require File.expand_path(File.dirname(__FILE__) + '/../test_helper')

class AurTest < Test::Unit::TestCase
  context 'Aur ClassMethod' do
    setup do
      @session = Session()
    end

    context 'search' do
      setup do
        @package_s   = 'aurb'
        @package_a   = ['aurb']
        @package_sym = :aurb
      end

      should 'accept arrays, symbols and strings' do
        assert_nothing_raised { @session.search(@package_s)   }
        assert_nothing_raised { @session.search(@package_a)   }
        assert_nothing_raised { @session.search(@package_sym) }
      end

      should 'return an array of results' do
        assert @session.search(@package_s).is_a?(Array)
        assert @session.search(@package_a).is_a?(Array)
      end

      context 'result' do
        setup do
          @result = @session.search(@package_s).first
        end

        should 'return an array containing hashes' do
          assert @result.is_a?(Hash)
        end

        context 'keys' do
          setup do
            @key = @result.keys.first
          end

          should 'be symbolized' do
            assert @key.is_a?(Symbol)
          end
        end
      end
    end

    should 'return true' do
      assert true
    end
  end
end
