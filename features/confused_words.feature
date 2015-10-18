Feature: Confused Words
  As a Business Analyst
  I want to be informed for confused words
  so that I know when I'm using wrong words

  Background:
    Given a file named "confused_words.rb" with:
      """
      $LOAD_PATH << '../../lib'
      require 'gherkin_language'

      no_cache = true
      ngrams = true
      language = GherkinLanguage.new(no_cache, ngrams)
      language.analyze 'test.feature'
      exit language.report

      """

  Scenario: Warns for confused word
    Given a file named "test.feature" with:
      """
      Feature: Test
        Scenario: Tag
          Given I do not now where it is
          When execute
          Then pass
      """
    When I run `ruby confused_words.rb`
    Then it should fail with exactly:
      """
      [non-conformance] CONFUSION_RULE
        Statistic suggests that 'know' (to be aware of) might be the correct word here, not 'now' (in this moment). Please check.
        Context: Given I do not now where it is when execute then pass
        Replacements: know
        References: test.feature

      """

  Scenario: Accept non confused words
    Given a file named "test.feature" with:
      """
      Feature: Test
        Scenario: Tag
          Given I do not know where it is
          When execute
          Then pass
      """
    When I run `ruby confused_words.rb`
    Then it should pass with exactly:
      """

      """
