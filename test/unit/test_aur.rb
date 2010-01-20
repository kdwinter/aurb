require File.expand_path(File.dirname(__FILE__) + '/../test_helper')

class AurTest < Test::Unit::TestCase
  context 'Aur ClassMethod' do
    setup do
      @session = Session()
    end

    context 'upgrade' do
      setup do
        @list = ['aurb 0.0.0.0',
                 'aurb 0.9.9.9']
      end

      should 'return an array' do
        assert @session.upgrade(@list).is_a?(Array)
      end

      should 'contain only upgradable packages' do
        assert_not_equal [:aurb, :aurb], @session.upgrade(@list)
        assert_equal [:aurb], @session.upgrade(@list)
      end
    end

    context 'download' do
      setup do
        @url = lambda {|p| "http://aur.archlinux.org/packages/#{p}/#{p}.tar.gz"}
        @package_working = 'awesome-git'
        @package_faulty  = 'awesome'
      end

      should 'accept arrays, symbols and strings' do
        assert_nothing_raised { @session.download(@package_working.to_s) }
        assert_nothing_raised { @session.download(@package_working.split) }
        assert_nothing_raised { @session.download(@package_working.to_sym) }
      end

      should 'return an array' do
        assert @session.download(@package_working).is_a?(Array)
        assert @session.download(@package_faulty).is_a?(Array)
      end

      should 'return download links' do
        assert_equal [@url.call(@package_working)], @session.download(@package_working)
      end

      should 'filter out non-existant packages' do
        assert_equal [], @session.download(@package_faulty)
      end
    end

    context 'search' do
      setup do
        @package = 'aurb'
      end

      should 'accept arrays, symbols and strings' do
        assert_nothing_raised { @session.search(@package.to_s)   }
        assert_nothing_raised { @session.search(@package.split)   }
        assert_nothing_raised { @session.search(@package.to_sym) }
      end

      should 'return an array of results' do
        assert @session.search(@package.to_s).is_a?(Array)
        assert @session.search(@package.split).is_a?(Array)
      end

      context 'result' do
        setup do
          @result = @session.search(@package).first
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
  end
end
