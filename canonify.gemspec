# frozen_string_literal: true

require_relative "lib/canonify/version"

Gem::Specification.new do |spec|
  spec.name = "canonify"
  spec.version = Canonify::VERSION
  spec.authors = ["Ivan Moscoso"]
  spec.email = ["moscoso@gmail.com"]

  spec.summary = "A library for intelligently resolving URLs to their closest, most canonical form."
  spec.homepage = "https://github.com/ivan3bx/canonify"
  spec.license = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.3.0")

  #spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/ivan3bx/canonify"
  spec.metadata["changelog_uri"] = "https://github.com/ivan3bx/canonify/CHANGELOG.md"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{\A(?:test|spec|features)/}) }
  end

  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  spec.add_dependency "addressable", "~> 2.8"
  spec.add_dependency "faraday", "~> 1.0"
  spec.add_dependency "faraday_middleware", "~> 1.0"
  spec.add_dependency "nokogiri", "~> 1.12"
end
