Feature: Exception
  As a Business Analyst
  I want to define exceptions for checks
  so that I am able to bypass false positives

  Background:
    Given a file named "exception.rb" with:
      """
      $LOAD_PATH << '../../lib'
      require 'gherkin_language'

      no_cache = true
      language = GherkinLanguage.new no_cache
      language.ignore 'EN_A_VS_AN'
      language.analyze 'test.feature'
      exit language.report

      """

  Scenario: Accept ignored rules
    Given a file named "test.feature" with:
      """
      Feature: Test
        Scenario: Tag
          Given an test
          When execute
          Then pass
      """
    When I run `ruby exception.rb`
    Then it should pass with exactly:
      """

      """

  Scenario: Fails for non ignored rules
    Given a file named "test.feature" with:
      """
      Feature: Test
        Scenario: Tag
          Given a test
          When exicute
          Then pass
      """
    When I run `ruby exception.rb`
    Then it should fail with exactly:
      """
      [misspelling] MORFOLOGIK_RULE_EN_US
        Possible spelling mistake found
        Context: Given a test when exicute then pass
        Replacements: execute
        References: test.feature

      """
