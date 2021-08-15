require "faraday"
require "faraday_middleware"
require "nokogiri"
require "pry"

module Canonify
  class Resolver
    def initialize(options = {})
      @cache = options[:cache]
    end

    def resolve(original_url)
      uri = Addressable::URI.parse(original_url)

      return {url: original_url, included_params: [], excluded_params: []} unless uri.host && uri.query
      return cached_response(uri) if @cache&.exist?(uri.hostname)

      old_params = Addressable::URI.parse(original_url).query_values || {}

      {url: fetch(original_url), excluded_params: [], included_params: []}.tap do |response|
        new_url = Addressable::URI.parse(response[:url])
        new_params = Addressable::URI.parse(new_url).query_values

        # present in old but not in new? => excluded!
        response[:excluded_params] = new_params ? old_params.reject { |k, v| new_params[k] }.keys : old_params.keys
        # present in new but not in old? => included!
        response[:included_params] = new_params ? new_params.select { |k, v| old_params[k] }.keys : []

        if @cache
          hostname = Addressable::URI.parse(new_url).hostname
          @cache.write(hostname, {excluded_params: response[:excluded_params]})
        end
      end
    end

    private

    def cached_response(uri)
      excluded_params = @cache.read(uri.hostname).fetch(:excluded_params)
      uri.query_values = uri.query_values.reject { |k, v| excluded_params.include?(k) }
      uri.query_values = nil if uri.query_values.empty?
      {url: uri.to_s, excluded_params: excluded_params, included_params: []}
    end

    def fetch(url)
      connection = create_connection(url)
      response = connection.get
      return url unless response.success?

      doc = Nokogiri::HTML(response.body)
      doc.at_css('head link[rel="canonical"]')&.attr("href") || url
    end

    def create_connection(url)
      Faraday.new(url: url) do |connection|
        connection.use FaradayMiddleware::FollowRedirects
        connection.adapter Faraday.default_adapter
      end
    end
  end
end
