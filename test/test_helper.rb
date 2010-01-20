require File.expand_path(File.dirname(__FILE__) + '/../lib/aurb')

require 'shoulda'

class Test::Unit::TestCase
  def Session(&block)
    klass = Class.new do
      include Aurb::Aur

      class_eval(&block) if block_given?
    end

    klass
  end
end
