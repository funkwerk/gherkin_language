# encoding: utf-8
gem 'gherkin', '2.12.2'

require 'gherkin/formatter/json_formatter'
require 'gherkin/parser/parser'
require 'gherkin_language/error'
require 'gherkin_language/language_tool_process'
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
  def initialize(no_cache = false, ngram = false)
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
    @exceptions = []
    @ngram = ngram
  end

  def ignore(exception)
    @exceptions.push exception
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

  def determine_readability_by_file(files)
    puts "Readability. Sorted from best to worst readable feature\n\n" if files.length > 1
    readability_by_file = {}
    files.each do |file|
      sentences = extract_sentences parse(file)
      readability_by_file[file] = readability sentences
    end
    average_readability = 0
    readability_by_file.sort { |lhs, rhs| lhs[1] <=> rhs[1] }.reverse_each do |file, rating|
      puts "#{rating.round}: #{file}"
      average_readability += rating / files.length
    end
    puts "\n#{files.length} files analyzed. Average readability is #{average_readability.round}" if files.length > 1
  end

  def readability(sentences)
    require 'syllables'

    total_words = 0
    total_syllabels = 0
    Syllables.new(sentences.join('\n')).to_h.each do |_word, syllabels|
      total_words += 1
      total_syllabels += syllabels
    end
    206.835 - 1.015 * (total_words / sentences.length) - 84.6 * (total_syllabels / total_words)
  end

  def accepted?(sentence)
    return false if @accepted_paragraphs.nil?
    key = :without_glossary
    key = hash(File.read('.glossary')) if File.exist? '.glossary'

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
    return 0 if @references.keys.empty?
    language = LanguageToolProcess.new @ngram
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
    end
    errors.select! { |error| !@exceptions.include? error.rule }
    errors.each do |error|
      local_refs = @references[@line_to_reference[error.from_y]]
      puts error.str local_refs
    end
    # TODO: list references for unknown words
    puts red "#{unknown_words.count} unknown words: #{unknown_words * ', '}" unless unknown_words.empty?
    return -1 unless unknown_words.empty?

    write_accepted_paragraphs used_refs

    return -1 unless errors.empty?
    0
  end

  def write_accepted_paragraphs(used_refs)
    @references.each do |sentence, _refs|
      next if used_refs.include? sentence
      key = :without_glossary
      key = hash(File.read('.glossary')) if File.exist? '.glossary'

      @accepted_paragraphs[key] = Set.new [] unless @accepted_paragraphs.key? key
      @accepted_paragraphs[key].add hash sentence
    end

    FileUtils.mkdir_p File.dirname @settings_path
    File.open(@settings_path, 'w') do |settings_file|
      settings_file.write @accepted_paragraphs.to_yaml
    end
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
      features['elements'].each do |scenario|
        next unless scenario.key? 'steps'
        terms = background.dup
        if scenario['type'] == 'background'
          background.push extract_terms_from_scenario(scenario['steps'], terms)
          next
        end

        terms.push extract_terms_from_scenario(scenario['steps'], background)
        sentence = terms.join(' ').strip
        if scenario.key? 'examples'
          sentences += extract_examples(scenario['examples'], sentence)
        else
          sentences.push sentence
        end
      end
    end
    sentences
  end

  def extract_terms_from_scenario(steps, background)
    steps.map do |step|
      keyword = step['keyword']
      keyword = 'and ' unless background.empty? || keyword != 'Given '
      terms = [keyword, step['name']].join
      terms = uncapitalize(terms) unless background.empty?
      background = terms
      terms
    end.flatten
  end

  def extract_examples(examples, prototype)
    examples.map do |example|
      sentences = []
      sentences.push example['name'] unless example['name'].empty?
      sentences.push example['description'] unless example['description'].empty?
      sentences += expand_outlines(prototype, example)
      sentences
    end.flatten
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
