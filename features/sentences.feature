Feature: Sentences
  As a Developer
  I want to extract all sentences out of my feature files
  so that I could do further analysis on them

  Background:
    Given a file named "extract_sentences.rb" with:
      """
      $LOAD_PATH << '../../lib'
      require 'gherkin_language'

      language = GherkinLanguage.new false
      puts language.extract_sentences language.parse 'test.feature'

      """

  Scenario: Extract Sentences
    Given a file named "test.feature" with:
      """
      Feature: Test
        Scenario: Test
          Given test
          When I execute
          Then verify
      """
    When I run `ruby extract_sentences.rb`
    Then it should pass with:
      """
      Test
      Test
      Given test when I execute then verify
      """

  Scenario: Extract Sentences with background
    Given a file named "test.feature" with:
      """
      Feature: Test
        Background:
          Given background

        Scenario: Test
          Given test
          When I execute
          Then verify
      """
    When I run `ruby extract_sentences.rb`
    Then it should pass with:
      """
      Test
      Test
      Given background and test when I execute then verify
      """

  Scenario: Extract Sentences from outlines
    Given a file named "test.feature" with:
      """
      Feature: Test
        Scenario Outline: Test
          Given <A>
          When <B>
          Then <C>

          Examples: Table
            | A | B | C |
            | 1 | 3 | 5 |
            | 2 | 4 | 6 |
      """
    When I run `ruby extract_sentences.rb`
    Then it should pass with:
      """
      Test
      Test
      Table
      Given 1 when 3 then 5
      Given 2 when 4 then 6
      """

  Scenario: Extract Sentences from outlines with multiple examples
    Given a file named "test.feature" with:
      """
      Feature: Test
        Scenario Outline: Test
          When <A> <B>
          Then <C>

          Examples: Table
            | A |
            | 1 |
            | 2 |

          Examples: Second Table
            | B | C |
            | 3 | 5 |
            | 4 | 6 |
      """
    When I run `ruby extract_sentences.rb`
    Then it should pass with:
      """
      Test
      Test
      Table
      Second Table
      When 1 3 then 5
      When 1 4 then 6
      When 2 3 then 5
      When 2 4 then 6
      """

  Scenario: Extract Sentences considers feature description
    Given a file named "test.feature" with:
      """
      Feature: Test
        As a user,
        I want something
        so that I have that

        Scenario: Test
          Given test
          When I execute
          Then verify
      """
    When I run `ruby extract_sentences.rb`
    Then it should pass with:
      """
      Test
      As a user,
      I want something
      so that I have that
      Test
      Given test when I execute then verify
      """

  Scenario: Extract Sentences considers scenario description
    Given a file named "test.feature" with:
      """
      Feature: Test
        As a user,
        I want something
        so that I have that

        Scenario: Test
        This is a sentence description

          Given test
          When I execute
          Then verify
      """
    When I run `ruby extract_sentences.rb`
    Then it should pass with:
      """
      Test
      As a user,
      I want something
      so that I have that
      Test
      This is a sentence description
      Given test when I execute then verify
      """
