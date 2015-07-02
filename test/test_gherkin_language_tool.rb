require 'minitest/autorun'
require 'gherkin_language'

# checks language
class LanguageTest < Minitest::Unit::TestCase
  def setup
    @language = GherkinLanguage::LanguageToolProcess.new
    @language.start!
  end

  def test_check_valid_paragraph
    # setup
    feature = 'This is good English'

    # exercise
    @language.check_paragraph feature
    @language.stop!
    actual = @language.errors
    unknown_words = @language.unknown_words

    # verify
    assert_empty actual
    assert_empty unknown_words
  end

  def test_check_invalid_paragraph
    # setup
    feature = 'This are no English good'

    # exercise
    @language.check_paragraph feature
    @language.stop!
    actual = @language.errors
    unknown_words = @language.unknown_words

    # verify
    refute_empty actual
    assert_empty unknown_words
  end
end
