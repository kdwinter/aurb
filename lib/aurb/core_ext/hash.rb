#!/usr/bin/env ruby
# encoding: utf-8

module Aurb
  module CoreExt
    module Hash
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
  end
end

Hash.send :include, Aurb::CoreExt::Hash
