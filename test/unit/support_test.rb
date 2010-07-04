require File.expand_path('../../test_helper', __FILE__)

class SupportTest < Test::Unit::TestCase
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
    should 'be able to colorize itself' do
      str = 'foo'
      String::COLORS.each_with_index do |color, i|
        assert str.colorize(color)
        assert_equal "\e[0;#{30+i}m#{str}\e[0m", str.colorize(color)
      end
    end
  end
end
