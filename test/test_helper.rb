require File.expand_path(File.dirname(__FILE__) + '/../lib/aurb')

require 'shoulda'

class Test::Unit::TestCase
  include Aurb

  def Session
    klass = Class.new do
      include Aurb::Aur
    end

    klass
  end
end
