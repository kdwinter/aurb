#!/usr/bin/env ruby
# encoding: utf-8
#
# Most of these extracted from Rails source (http://github.com/rails/rails)

class Object
  # An object is blank if it's false, empty or a whitespace string.
  def blank?
    respond_to?(:empty?) ? empty? : !self
  end
end

class Symbol
  # Turns the symbol into a proc, useful for enumerations.
  #
  #   items.select(&:cool?).map(&:name)
  #   # Does the same as
  #   items.select {|i| i.cool?}.map {|i| i.name}
  def to_proc
    Proc.new {|obj| obj.__send__(self)}
  end
end

class Hash
  # Returns a new hash with all keys converted to symbols.
  def symbolize_keys
    inject({}) do |options, (key, value)|
      options[(key.to_sym rescue key) || key] = value
      options
    end
  end

  # Destructively converts all keys to symbols.
  def symbolize_keys!
    self.replace(self.symbolize_keys)
  end

  # Delegation
  def method_missing(key)
    self.symbolize_keys[key.to_sym]
  end
end

class Array
  # Extracts options from a set of arguments.
  #
  #   def options(*args)
  #     args.extract_options!
  #   end
  #
  #   options(1, 2)           # => {}
  #   options(1, 2, :a => :b) # => {:a=>:b}
  def extract_options!
    last.is_a?(Hash) ? pop : {}
  end
end

class String
  # Colors a string with +color+.
  # Uses the ANSICode library provided by +facets+.
  #
  #   "Hello".colorize(:blue) # => "\e[34mHello\e[0m"
  #
  # For more information on available effects, see
  # http://facets.rubyforge.org/apidoc/api/more/classes/ANSICode.html
  def colorize(effect)
    ANSICode.send(effect.to_sym) << self << ANSICode.clear
  rescue
    self
  end
end
