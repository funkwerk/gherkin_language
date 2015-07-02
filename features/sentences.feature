Feature: Sentences
  As a Business Analyst
  I want to extract all sentences out of my feature files
  so that I could do further analysis on them

  Background:
    Given a file named "extract_sentences.rb" with:
      """
      $LOAD_PATH << '../../lib'
      require 'gherkin_language'

      language = GherkinLanguage.new false
      puts language.extract_sentences language.parse 'foo.feature'

      """

  Scenario: Extract Sentences
    Given a file named "foo.feature" with:
      """
      Feature: Foo
        Scenario: Bar
          Given a foo
          When I bar
          Then I baz
      """
    When I run `ruby extract_sentences.rb`
    Then it should pass with:
      """
      Foo
      Bar
      Given a foo when I bar then I baz
      """

  Scenario: Extract Sentences with background
    Given a file named "foo.feature" with:
      """
      Feature: Foo
        Background:
          Given something

        Scenario: Bar
          Given a foo
          When I bar
          Then I baz
      """
    When I run `ruby extract_sentences.rb`
    Then it should pass with:
      """
      Foo
      Bar
      Given something and a foo when I bar then I baz
      """

  Scenario: Extract Sentences from outlines
    Given a file named "foo.feature" with:
      """
      Feature: Foo
        Scenario Outline: Bar
          Given a <foo>
          When I <bar>
          Then I <baz>

          Examples: table
            | foo | bar | baz |
            | FOO | BAR | BAZ |
            | oof | rab | zab |
      """
    When I run `ruby extract_sentences.rb`
    Then it should pass with:
      """
      Foo
      Bar
      table
      Given a FOO when I BAR then I BAZ
      Given a oof when I rab then I zab
      """

  Scenario: Extract Sentences considers feature description
    Given a file named "foo.feature" with:
      """
      Feature: Foo
        As a user,
        I want something
        so that I have that

        Scenario: Bar
          Given a foo
          When I bar
          Then I baz
      """
    When I run `ruby extract_sentences.rb`
    Then it should pass with:
      """
      Foo
      As a user,
      I want something
      so that I have that
      Bar
      Given a foo when I bar then I baz
      """

  Scenario: Extract Sentences considers scenario description
    Given a file named "foo.feature" with:
      """
      Feature: Foo
        As a user,
        I want something
        so that I have that

        Scenario: Bar
        This is a sentence description
        
          Given a foo
          When I bar
          Then I baz
      """
    When I run `ruby extract_sentences.rb`
    Then it should pass with:
      """
      Foo
      As a user,
      I want something
      so that I have that
      Bar
      This is a sentence description
      Given a foo when I bar then I baz
      """
