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

class String
  # Colors a string with +color+.
  # Uses the ANSICode library provided by +facets+.
  #
  #   "Hello".colorize(:blue) # => "\e[34mHello\e[0m"
  #
  # For more information on available effects, see
  # http://facets.rubyforge.org/apidoc/api/more/classes/ANSICode.html
  def colorize(effect)
    ANSI::Code.send(effect.to_sym) << self << ANSI::Code.clear
  rescue
    self
  end
end
