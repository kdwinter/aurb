require File.expand_path('../../test_helper', __FILE__)

class SupportTest < Test::Unit::TestCase
  context 'Object' do
    should 'be able to check for blank' do
      assert ''.blank?
      assert nil.blank?
      assert [].blank?
    end
  end

  context 'Hash' do
    setup do
      @hash_str = {'hello' => 'world'}
      @hash_sym = {:hello  => 'world'}
    end

    should 'be able to symbolize keys' do
      assert_equal @hash_sym, @hash_str.symbolize_keys
      @hash_str.symbolize_keys!
      assert_equal @hash_sym, @hash_str
    end

    should 'provide methods for its keys through method_missing' do
      assert_equal 'world', @hash_str.hello
      assert_equal 'world', @hash_sym.hello
    end
  end

  context 'String' do
    should 'be able to colorize itself through the ansi library' do
      str = 'foo'
      assert str.colorize(:blue)
      assert_equal "\e[34mfoo\e[0m", str.colorize(:blue)
    end
  end
end
