# frozen_string_literal: true

require_relative "canonify/version"
require "canonify/resolver"

module Canonify
  class Error < StandardError; end

  class << self
    def new(options = {})
      Resolver.new(options)
    end

    def resolve(url)
      Resolver.new.resolve(url)
    end
  end
end
