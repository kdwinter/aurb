require File.expand_path('../../test_helper', __FILE__)

class AurTest < Test::Unit::TestCase
  context 'Aurb::Aur ::' do
    context 'Version' do
      should 'be able to compare versions and return the newest' do
        versions = [
          {:old => '1',       :new => '2'      },
          {:old => '1-3',     :new => '2-1'    },
          {:old => '1.0.0-2', :new => '2.0.0-3'},
          {:old => '1.0.pre', :new => '1.0.1'  }
        ]
        versions.each do |version|
          assert_operator Aurb::Aur::Version.new(version[:old]), :<, Aurb::Aur::Version.new(version[:new])
        end
      end
    end
  end

  context 'Aurb::Aur #' do
    context 'info' do
      setup do
        @package_working = 'aurb'
        @package_faulty  = 'foobarbaz'
      end

      should 'return a hash of results' do
        assert_operator Hash, :===, Aurb.aur.info(@package_working)
      end

      should 'return nothing when a package does not exist' do
        assert Aurb.aur.info(@package_faulty).blank?
        assert_nil Aurb.aur.info(@package_faulty)
      end
    end

    context 'upgrade' do
      setup do
        @list = "aurb 0.0.0-0\naurb 9.9.9-9".split(/\n/)
      end

      should 'return an array' do
        assert_operator Array, :===, Aurb.aur.upgrade(*@list)
      end

      should 'contain only upgradable packages' do
        assert_not_equal [:aurb, :aurb], Aurb.aur.upgrade(*@list)
        assert_equal [:aurb], Aurb.aur.upgrade(*@list)
      end
    end

    context 'download' do
      setup do
        @package_working = 'aurb'
        @package_faulty  = 'foobarbaz'
      end

      should 'return an array' do
        assert_operator Array, :===, Aurb.aur.download(*@package_working)
        assert_operator Array, :===, Aurb.aur.download(*@package_faulty)
      end

      should 'return download links' do
        assert_equal [Aurb.aur_download_path(*@package_working)], Aurb.aur.download(*@package_working)
      end

      should 'filter out non-existant packages' do
        assert Aurb.aur.download(*@package_faulty).blank?
        assert_equal [], Aurb.aur.download(*@package_faulty)
      end
    end

    context 'search' do
      setup do
        @package_working = 'aurb'
        @package_faulty  = 'foobarbaz'
      end

      should 'return an array of results' do
        assert_operator Array, :===, Aurb.aur.search(*@package_working)
        assert_operator Array, :===, Aurb.aur.search(*@package_faulty)
      end

      should 'filter out non-existant packages' do
        assert Aurb.aur.search(*@package_faulty).blank?
        assert_equal [], Aurb.aur.search(*@package_faulty)
      end

      context 'result' do
        should 'return an array containing hashes' do
          assert_operator Hash, :===, Aurb.aur.search(*@package_working).first
        end
      end
    end
  end
end
