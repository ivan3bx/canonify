# frozen_string_literal: true

require "active_support"

RSpec.describe Canonify do
  it "has a version number" do
    expect(Canonify::VERSION).not_to be nil
  end

  context "with invalid input" do
    let(:invalid_url) { "hx_?foo=bar" }

    it "performs no action" do
      expect(Canonify.resolve(invalid_url)).to eq({url: invalid_url, included_params: [], excluded_params: []})
    end
  end

  context "with a simple URL" do
    let(:url) { "https://www.wsj.com/articles/test.html" }

    it "returns the same URL" do
      expect(Canonify.resolve(url)).to eq({
        url: url,
        included_params: [],
        excluded_params: []
      })
    end
  end

  context "with a URL that can be simplified" do
    let(:input) { "https://example.com/article?mod=opinion_lead_pos2" }
    let(:output) { "https://example.com/article/" }

    before {
      stub_request(:get, input).to_return(body: '<html><head><link rel="canonical" href="%s"/></head></html>' % output)
    }

    it "returns the canonical URL" do
      expect(Canonify.resolve(input)).to include({url: output})
    end

    it "returns excluded parameters" do
      expect(Canonify.resolve(input)).to include({excluded_params: ["mod"]})
    end

    it "returns no included parameters" do
      expect(Canonify.resolve(input)).to include({included_params: []})
    end
  end

  context "with a URL that can not be simplified" do
    let(:input) { "https://example.com/article?mod=opinion_lead_pos2" }
    let(:output) { input.dup }

    before {
      stub_request(:get, input).to_return(body: '<html><head><link rel="canonical" href="%s"/></head></html>' % output)
    }

    it "returns the canonical URL" do
      expect(Canonify.resolve(input)).to include({url: output})
    end

    it "returns no excluded params" do
      expect(Canonify.resolve(input)).to include({excluded_params: []})
    end

    it "returns all params as included" do
      expect(Canonify.resolve(input)).to include({included_params: ["mod"]})
    end
  end

  context "with a URL that can be partially simplified" do
    let(:input) { "https://example.com/article?mod=opinion_lead_pos2&utm_source=m" }
    let(:output) { "https://example.com/article?mod=opinion_lead_pos2" }

    before {
      stub_request(:get, input).to_return(body: '<html><head><link rel="canonical" href="%s"/></head></html>' % output)
    }

    it "returns the canonical URL" do
      expect(Canonify.resolve(input)).to include({url: output})
    end

    it "returns excluded param" do
      expect(Canonify.resolve(input)).to include({excluded_params: ["utm_source"]})
    end

    it "returns included param" do
      expect(Canonify.resolve(input)).to include({included_params: ["mod"]})
    end
  end

  context "with a cached result" do
    let(:request_a) { "https://example.com/article_1?mod=1" }
    let(:request_b) { "https://example.com/article_2?mod=2" }
    let(:request_c) { "https://www.example.com/article_3?mod=2" }

    let(:output_a) { "https://example.com/article_1" }
    let(:output_b) { "https://example.com/article_2" }
    let(:output_c) { "https://www.example.com/article_3" }
    let(:resolver) { Canonify.new(cache: ActiveSupport::Cache::MemoryStore.new) }

    before {
      stub_request(:get, request_a).to_return(body: '<html><head><link rel="canonical" href="%s"/></head></html>' % output_a)
      resolver.resolve(request_a) # cache rule for 'example.com'
    }

    it "caches exclusion rule for same domain" do
      expect(resolver.resolve(request_b)).to include({url: output_b})
      expect(WebMock).to_not have_requested(:get, request_b)
    end

    it "does not cache rule for other domain" do
      stub_request(:get, request_c).to_return(body: '<html><head><link rel="canonical" href="%s"/></head></html>' % output_c)
      expect(resolver.resolve(request_c)).to include({url: output_c})
      expect(WebMock).to have_requested(:get, request_c)
    end

    pending "does not cache rule for same domain and new params" do
      stub_request(:get, "https://example.com/article_1?mod=2&foo=bar").to_return(body: '<html><head><link rel="canonical" href="%s"/></head></html>' % "https://example.com/article_1")
      expect(resolver.resolve("https://example.com/article_1?mod=2&foo=bar")).to include({url: "https://example.com/article_1"})
      expect(WebMock).to have_requested(:get, "https://example.com/article_1?mod=2&foo=bar")
    end
  end
end
