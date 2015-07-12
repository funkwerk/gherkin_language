Feature: Glossary
  As a Business Analyst
  I want to use business terms
  so that I use the same language as in the business

  Background:
    Given a file named "report.rb" with:
      """
      $LOAD_PATH << '../../lib'
      require 'gherkin_language'

      no_cache = true
      language = GherkinLanguage.new no_cache
      language.analyze 'test.feature'
      exit language.report

      """
    And a file named "test.feature" with:
      """
      Feature: Test
        Scenario: Duplex-Hyper-Reflux-Machine
      """

  Scenario: Warns about undefined Term
    When I run `ruby report.rb`
    Then it should fail with exactly:
      """
      1 unknown words: Duplex-Hyper-Reflux-Machine

      """

  Scenario: Business Term
    Given a file named ".glossary" with:
      """
      Duplex-Hyper-Reflux-Machine	Duplex-Hyper-Reflux-Machine	NNP

      """
    When I run `ruby report.rb`
    Then it should pass with exactly:
      """

      """
