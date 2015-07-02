require 'minitest/autorun'
require 'gherkin_language'

# gherkin language test
class GherkinLanguageTest < Minitest::Unit::TestCase
  def setup
    @gherkin = GherkinLanguage.new
  end

  def test_to_json
    # setup
    feature = %(Feature: Foo
Scenario: Bar
)
    expected = MultiJson.load %(
      [
       {
        "keyword": "Feature",
        "name": "Foo",
        "line": 1,
        "description": "",
        "id": "foo",
        "uri": "generated.feature",
        "elements":
         [
          {
           "keyword": "Scenario", "name": "Bar",
           "line": 2, "description": "",
           "id": "foo;bar", "type": "scenario"
          }
         ]
        }
       ]
      )

    # exercise
    actual = @gherkin.to_json feature

    # verify
    assert_equal expected, actual
  end

  def test_sentences
    # setup
    feature = %(Feature: Foo
Scenario: Bar
  Given a Foo
  And another Foo
  But no Bar
  When a Bar
  Then a Baz
)
    expected = ['Given a Foo and another Foo but no Bar when a Bar then a Baz']

    # exercise
    actual = @gherkin.sentences @gherkin.to_json feature

    # verify
    assert_equal expected, actual
  end
end
