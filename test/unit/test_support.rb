require File.expand_path(File.dirname(__FILE__) + '/../test_helper')

class SupportTest < Test::Unit::TestCase
  context 'Object' do
    should 'be able to check for blank' do
      assert ''.blank?
      assert nil.blank?
    end
  end

  context 'Hash' do
    setup do
      @hash_s = {'hello' => 'world'}
      @hash_sym = {:hello => 'world'}
    end

    should 'be able to symbolize keys' do
      assert_equal @hash_sym, @hash_s.symbolize_keys
      symbolized = @hash_s.symbolize_keys!
      assert_equal @hash_sym, symbolized
    end

    should 'provide methods for its keys through method_missing' do
      assert_equal 'world', @hash_s.hello
      assert_equal 'world', @hash_sym.hello
    end
  end
end
