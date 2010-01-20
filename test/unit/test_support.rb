require File.expand_path(File.dirname(__FILE__) + '/../test_helper')

class SupportTest < Test::Unit::TestCase
  context 'The core extensions' do
    should 'be able to check for blank' do
      assert ''.blank?
      assert nil.blank?
    end

    context 'for symbol' do
      setup do
        @stub = ['HELLO']
      end

      should 'allow for to_proc on enumerations' do
        assert_equal @stub.map {|s| s.downcase}, @stub.map(&:downcase)
        assert_equal ['hello'], @stub.map(&:downcase)
      end
    end

    context 'for hash' do
      setup do
        @hash_s = {'hello' => 'world'}
        @hash_sym = {:hello => 'world'}
      end

      should 'be able to symbolize keys' do
        assert_equal @hash_sym, @hash_s.symbolize_keys
        symbolized = @hash_s.symbolize_keys!
        assert_equal @hash_sym, symbolized
      end

      should 'provide methods for its keys and automatically symbolize them' do
        assert_equal 'world', @hash_s.hello
        assert_equal 'world', @hash_sym.hello
      end
    end

    context 'for array' do
      setup do
        @array_no_opts   = [1, 2]
        @array_with_opts = [1, 2, :a => :b]
      end

      should 'be able to extract options' do
        assert_equal({}, @array_no_opts.extract_options!)
        assert_equal({:a => :b}, @array_with_opts.extract_options!)
      end
    end
  end
end
