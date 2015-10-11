Feature: Readability
  As a Business Analyst
  I want to be informed about non readable features
  so that I know when I need to restructure

  Background:
    Given a file named "readability.rb" with:
      """
      $LOAD_PATH << '../../lib'
      require 'gherkin_language'

      no_cache = true
      ngrams = false
      language = GherkinLanguage.new(no_cache, ngrams)
      language.determine_readability_by_file %w(default.feature unreadable.feature)
      exit language.report

      """
    And a file named "default.feature" with:
      """
      Feature: Default
        Scenario: Tag
          Given a test
          When execute
          Then pass
      """

  Scenario: Sort by readability
    Given a file named "unreadable.feature" with:
      """
      Feature: Unreadable busting complexity check
        Scenario: nonsense and unreadable
          Given a fancy-hyper non-readable and quite complex test specification
          When consider to execute that
          Then verification is successful
      """
    When I run `ruby readability.rb`
    Then it should pass with exactly:
      """
      Readability. Sorted from best to worst readable feature

      119: default.feature
      30: unreadable.feature

      2 files analyzed. Average readability is 74

      """
