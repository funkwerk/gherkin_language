Feature: Correct
  As a Business Analyst
  I want no errors for correct files
  so that I know that my files are all correct

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

  Scenario: Empty Feature
    Given a file named "test.feature" with:
      """
      Feature: Test
      """
    When I run `ruby report.rb`
    Then it should pass with exactly:
      """

      """

  Scenario: Empty Scenario
    Given a file named "test.feature" with:
      """
      Feature: Test
        Scenario: Test
      """
    When I run `ruby report.rb`
    Then it should pass with exactly:
      """

      """
