#!/usr/bin/env ruby
# encoding: utf-8
#
# Most of these extracted from Rails source (http://github.com/rails/rails)

class Symbol
  # Turns the symbol into a proc, useful for enumerations.
  #
  #   items.select(&:cool?).map(&:name)
  #   # Does the same as
  #   items.select {|i| i.cool?}.map {|i| i.name}
  def to_proc
    Proc.new {|*args| args.shift.__send__(self, *args)}
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
