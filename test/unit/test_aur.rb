require File.expand_path(File.dirname(__FILE__) + '/../test_helper')

class AurTest < Test::Unit::TestCase
  context 'Aurb::Aur #' do
    setup do
      @aur = Aurb.aur
    end

    context 'upgrade' do
      setup do
        @list = ['aurb 0.0.0.0',
                 'aurb 9.9.9.9']
      end

      should 'return an array' do
        assert @aur.upgrade(@list).is_a?(Array)
      end

      should 'contain only upgradable packages' do
        assert_not_equal [:aurb, :aurb], @aur.upgrade(@list)
        assert_equal [:aurb], @aur.upgrade(@list)
      end

      context 'version' do
        should 'be able to compare versions and return the newest' do
          versions = [
            {:old => '1',       :new => '2'      },
            {:old => '1-3',     :new => '2-1'    },
            {:old => '1.0.0-2', :new => '2.0.0-3'},
          ]

          versions.each do |version|
            assert Aurb::Aur::Version.new(version[:old]) < Aurb::Aur::Version.new(version[:new])
          end
        end
      end
    end

    context 'download' do
      setup do
        @package_working = ['awesome-git']
        @package_faulty  = ['awesome']
      end

      should 'return an array' do
        assert @aur.download(@package_working).is_a?(Array)
        assert @aur.download(@package_faulty).is_a?(Array)
      end

      should 'return download links' do
        assert_equal [Aurb.aur_download_path(@package_working.join)], @aur.download(@package_working)
      end

      should 'filter out non-existant packages' do
        assert_equal [], @aur.download(@package_faulty)
      end
    end

    context 'search' do
      setup do
        @package_working = ['aurb']
        @package_faulty  = ['foobarbaz']
      end

      should 'return an array of results' do
        assert @aur.search(@package_working).is_a?(Array)
      end

      should 'filter out non-existant packages' do
        assert_equal [], @aur.search(@package_faulty)
      end

      context 'result' do
        setup do
          @result = @aur.search(@package_working).first
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
