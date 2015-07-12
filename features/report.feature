Feature: Report
  As a Business Analyst
  I want to get a report for language mistakes within my feature files
  so that I am able to fix them

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

  Scenario: Broken Sentence
    Given a file named "test.feature" with:
      """
      Feature: Test
        Scenario: Tag
          Given an test
          When execute
          Then pass
      """
    When I run `ruby report.rb`
    Then it should fail with exactly:
      """
      [misspelling] EN_A_VS_AN
        Use 'a' instead of 'an' if the following word doesn't start with a vowel sound, e.g. 'a sentence', 'a university'
        Context: Given an test when execute then pass
        Replacements: a
        References: test.feature

      """

  Scenario: Unknown Words
    Given a file named "test.feature" with:
      """
      Feature: Test
        Scenario: Tag
          Given a test
          When exicute
          Then pass
      """
    When I run `ruby report.rb`
    Then it should fail with exactly:
      """
      [misspelling] MORFOLOGIK_RULE_EN_US
        Possible spelling mistake found
        Context: Given a test when exicute then pass
        Replacements: execute
        References: test.feature
      1 unknown words: exicute

      """
