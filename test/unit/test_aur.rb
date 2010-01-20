require File.expand_path(File.dirname(__FILE__) + '/../test_helper')

class AurTest < Test::Unit::TestCase
  context 'Aur ClassMethod' do
    setup do
      @session = Session()
    end

    context 'download' do
      setup do
        @url = ->(p) {"http://aur.archlinux.org/packages/#{p}/#{p}.tar.gz"}
        @packages_working = ['aurb', 'awesome-git']
        @packages_faulty  = ['aurb', 'awesome']
      end

      should 'return an array' do
        assert @session.download(@packages_working).is_a?(Array)
        assert @session.download(@packages_faulty).is_a?(Array)
      end

      should 'return download links' do
        assert_equal @packages_working.map {|p| @url.call(p)},
          @session.download(@packages_working)
      end

      should 'filter out non-existant packages' do
        assert_equal [@url.call('aurb')], @session.download(@packages_faulty)
      end
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
