Feature: Tag
  As a Business Analyst
  I want to tag all words from my features files
  so that I can build up a glossary or check against forbidden words

  Scenario: Tag words
    Given a file named "tag.rb" with:
      """
      $LOAD_PATH << '../../lib'
      require 'gherkin_language'

      no_cache = true
      language = GherkinLanguage.new no_cache
      puts language.tag ['tag.feature']

      """
    And a file named "tag.feature" with:
      """
      Feature: Test
        Scenario: Tag
          Given a test
          When execute
          Then pass
      """
    When I run `ruby tag.rb`
    Then it should pass with exactly:
      """
      <S>
      [[[/null]
      "["/``]
      Test[Test/NNP]
      "["/'']
      ,[,/,,O]
      "["/``,O]
      Tag[tag/NN:UN,tag/VB,tag/VBP]
      "["/'']
      ,[,/,,O]
      "["/``,O]
      Given[Given/NNP,B-VP]
      a[a/DT,B-NP-singular]
      test[test/JJ,test/NN,test/VB,test/VBP,E-NP-singular]
      when[when/WRB,B-ADVP]
      execute[execute/VB,execute/VBP,B-VP]
      then[then/JJ,then/NN,then/RB,I-VP]
      pass[pass/JJ,pass/NN,pass/VB,pass/VBP,I-VP]
      "["/'',B-ADVP]
      ]
      [</S>,O]


      """
