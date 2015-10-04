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
