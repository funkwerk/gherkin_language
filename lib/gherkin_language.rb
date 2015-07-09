# encoding: utf-8
require 'gherkin/formatter/json_formatter'
require 'gherkin/parser/parser'
require 'rexml/document'
require 'stringio'
require 'multi_json'
require 'term/ansicolor'
include Term::ANSIColor
require 'tmpdir'
require 'fileutils'
require 'yaml'
require 'set'
require 'digest'

# gherkin utilities
class GherkinLanguage
  # This service class provides access to language tool process.
  class LanguageToolProcess
    attr_accessor :errors, :unknown_words

    VERSION = 'LanguageTool-3.0'
    URL = "https://www.languagetool.org/download/#{VERSION}.zip"

    # This value entity class represents a language error
    class Error
      attr_accessor :category, :context, :issuetype, :message, :replacements, :rule, :from_y, :to_y

      def initialize(category, context, issuetype, message, replacements, rule, from_y, to_y)
        @category = category
        @context = context
        @issuetype = issuetype
        @message = message
        @replacements = replacements
        @rule = rule
        @from_y = from_y
        @to_y = to_y
      end

      def str(references)
        (red("[#{@issuetype}] #{@rule}\n") +
         "  #{@message}\n  Context: #{@context}\n  Replacements: #{@replacements}\n  References: #{references * ', '}\n")
      end
    end

    def initialize
      path = Dir.tmpdir
      download path unless File.exist? "#{path}/#{VERSION}/languagetool-commandline.jar"
      @path = path
      @p = nil
      @reference_line = 0
      @errors = []
      @unknown_words = []
      use_user_glossary "#{path}/#{VERSION}" if File.exist? '.glossary'
    end

    def use_user_glossary(path)
      resource_path = "#{path}/org/languagetool/resource/en"
      system "cp #{resource_path}/added.txt #{resource_path}/added.copy && cp .glossary #{resource_path}/added.txt"
      at_exit do
        system "cp #{resource_path}/added.copy #{resource_path}/added.txt"
      end
    end

    def download(path)
      system "wget --quiet #{URL} -O /var/tmp/languagetool.zip"
      FileUtils.mkdir_p path
      system "unzip -qq -u /var/tmp/languagetool.zip -d #{path}"
    end

    def start!
      @errors = []
      @unknown_words = []
      @reference_line = 0
      Dir.chdir("#{@path}/#{VERSION}/") do
        @p = IO.popen('java -jar languagetool-commandline.jar --list-unknown --api --language en-US -', 'r+')
      end
    end

    def tag(sentences)
      output = ''
      Dir.chdir("#{@path}/#{VERSION}/") do
        p = IO.popen('java -jar languagetool-commandline.jar --taggeronly --api --language en-US -', 'r+')
        sentences.each { |sentence| p.write sentence }
        p.close_write
        line = p.readline
        loop do
          break if line == "<!--\n"
          output << line
          line = p.readline
        end
        p.close
      end
      output.gsub!(' ', "\n")
      output.gsub!(']', "]\n")
      output.gsub!("\n\n", "\n")
      output
    end

    def check_paragraph(paragraph)
      start_line = @reference_line
      send paragraph
      end_line = @reference_line
      send "\n\n"
      Range.new(start_line, end_line)
    end

    def send(sentence)
      @reference_line += sentence.count "\n"
      @p.write sentence
    end

    def parse_errors(result)
      doc = REXML::Document.new result
      errors = []
      doc.elements.each '//error' do |error|
        errors.push Error.new(
          error.attributes['category'],
          error.attributes['context'],
          error.attributes['locqualityissuetype'],
          error.attributes['msg'],
          error.attributes['replacements'],
          error.attributes['ruleId'],
          error.attributes['fromy'].to_i,
          error.attributes['toy'].to_i)
      end
      errors
    end

    def parse_unknown_words(result)
      doc = REXML::Document.new result
      errors = []
      doc.elements.each '//unknown_words/word' do |error|
        errors.push error.text
      end
      errors
    end

    def stop!
      @p.close_write
      errors = ''
      line = @p.readline
      loop do
        break if line == "<!--\n"
        errors << line
        line = @p.readline
      end
      @errors = parse_errors errors
      @unknown_words = parse_unknown_words errors
      @p.close
    end
  end

  def initialize(no_cache = false)
    path = "~/.gherkin_language/#{LanguageToolProcess::VERSION}/accepted_paragraphs.yml"
    @settings_path = File.expand_path path
    @accepted_paragraphs = {}
    begin
      @accepted_paragraphs = YAML.load_file @settings_path unless no_cache
    rescue
      puts 'could not read settings'
    end
    @references = {}
    @line_to_reference = {}
  end

  def analyze(file)
    sentences = extract_sentences parse file
    sentences.select! { |sentence| !accepted? sentence }
    return if sentences.empty?
    sentences.each do |sentence|
      stripped = sentence.strip
      @references[stripped] = [] unless @references.include? stripped
      @references[stripped].push file
    end
  end

  def accepted?(sentence)
    return false if @accepted_paragraphs.nil?
    key = :without_glossary
    key = hash(File.read '.glossary') if File.exist? '.glossary'

    return false unless @accepted_paragraphs.key? key
    @accepted_paragraphs[key].include? hash sentence
  end

  def hash(value)
    Digest::MD5.digest value.strip
  end

  def parse(file)
    content = File.read file
    to_json(content, file)
  end

  def extract_sentences(parsed)
    feature_names = lambda do |input|
      input.map { |feature| feature['name'] unless feature['name'] == '' }
    end

    descriptions = lambda do |input|
      input.map { |feature| feature['description'] unless feature['description'] == '' }
    end

    sentences = feature_names.call(parsed) + descriptions.call(parsed) + scenario_names(parsed) + sentences(parsed)
    sentences.select! { |sentence| sentence }
    sentences.map { |sentence| sentence.gsub(/ «.+»/, '') }
  end

  def tag(files)
    sentences = files.map { |file| extract_sentences parse file }
    language = LanguageToolProcess.new
    language.tag sentences
  end

  def report
    return if @references.keys.empty?
    language = LanguageToolProcess.new
    language.start!

    @references.keys.each do |sentence|
      location = language.check_paragraph sentence
      location.map { |line| @line_to_reference[line] = sentence }
    end
    language.stop!
    errors = language.errors
    unknown_words = language.unknown_words

    used_refs = Set.new []
    errors.each do |error|
      used_refs.add @line_to_reference[error.from_y]
      local_refs = @references[@line_to_reference[error.from_y]]
      puts error.str local_refs
    end
    # TODO: list references for unknown words
    puts red "#{unknown_words.count} unknown words: #{unknown_words * ', '}" unless unknown_words.empty?
    return -1 unless unknown_words.empty?

    @references.each do |sentence, _refs|
      next if used_refs.include? sentence
      key = :without_glossary
      key = hash(File.read '.glossary') if File.exist? '.glossary'

      @accepted_paragraphs[key] = Set.new [] unless @accepted_paragraphs.key? key
      @accepted_paragraphs[key].add hash sentence
    end

    FileUtils.mkdir_p File.dirname @settings_path
    File.open(@settings_path, 'w') do |settings_file|
      settings_file.write @accepted_paragraphs.to_yaml
    end
    return -1 unless errors.empty?
    0
  end

  def to_json(input, file = 'generated.feature')
    io = StringIO.new
    formatter = Gherkin::Formatter::JSONFormatter.new(io)
    parser = Gherkin::Parser::Parser.new(formatter, true)
    parser.parse(input, file, 0)
    formatter.done
    MultiJson.load io.string
  end

  def scenario_names(input)
    # TODO: scenario outlines with example values inside?
    scenarios = []
    input.each do |features|
      next unless features.key? 'elements'
      elements = features['elements']
      elements.each do |scenario|
        scenarios.push scenario['name'] if scenario['type'] == 'scenario'
        scenarios.push scenario['name'] if scenario['type'] == 'scenario_outline'
        scenarios.push scenario['description'] unless scenario['description'].empty?
      end
    end
    scenarios
  end

  def sentences(input)
    sentences = []
    background = []
    input.each do |features|
      next unless features.key? 'elements'
      elements = features['elements']
      elements.each do |scenario|
        next unless scenario.key? 'steps'
        terms = background.dup
        if scenario['type'] == 'background'
          scenario['steps'].each do |step|
            new_terms = [step['keyword'], step['name']].join
            new_terms = uncapitalize(new_terms) unless terms.empty?
            background.push new_terms
          end
          next
        end

        scenario['steps'].each do |step|
          keyword = step['keyword']
          keyword = 'and ' unless background.empty? || keyword != 'Given '
          new_terms = [keyword, step['name']].join
          new_terms = uncapitalize(new_terms) unless terms.empty?
          terms.push new_terms
        end
        sentence = terms.join ' '
        if scenario.key? 'examples'
          # TODO: support for multiple examples?
          scenario['examples'].each do |example|
            sentences.push example['name'] unless example['name'].empty?
            sentences.push example['description'] unless example['description'].empty?
            expand_outlines(sentence.strip, example).map { |expanded| sentences.push expanded }
          end
        else
          sentences.push sentence.strip
        end
      end
    end
    sentences
  end

  def uncapitalize(term)
    term[0, 1].downcase + term[1..-1]
  end

  def expand_outlines(sentence, example)
    result = []
    headers = example['rows'][0]['cells']
    example['rows'].slice(1, example['rows'].length).each do |row|
      modified_sentence = sentence.dup
      headers.zip(row['cells']).map { |key, value| modified_sentence.gsub!("<#{key}>", value) }
      result.push modified_sentence
    end
    result
  end
end
