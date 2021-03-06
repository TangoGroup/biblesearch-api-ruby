require 'biblesearch-api/client_version'

require 'biblesearch-api/endpoints/books'
require 'biblesearch-api/endpoints/chapters'
require 'biblesearch-api/endpoints/passages'
require 'biblesearch-api/endpoints/search'
require 'biblesearch-api/endpoints/verses'
require 'biblesearch-api/endpoints/versions'

require 'hashie'
require 'httparty'

directory = File.expand_path(File.dirname(__FILE__))

Hash.send :include, Hashie::HashExtensions

class BibleSearchError < StandardError
  attr_reader :data

  def initialize(data)
    @data = data
    super
  end
end

class BibleSearch
  include HTTParty

  include Books
  include Chapters
  include Passages
  include Search
  include Verses
  include Versions

  no_follow = true
  format :json

  attr_accessor :api_key
  def initialize(api_key, base_uri = 'bibles.org/v2')
    self.class.base_uri base_uri
    self.class.basic_auth(@api_key = api_key, 'X')
  end

  private
    def mashup(response)
      response = Hashie::Mash.new(response)
      # => raise BibleSearchError.new("Code #{response.code} -- #{response.desc}") unless response.stat == "ok"
      response
    end

    def required_keys_present?(hash, required)
      hash.keys.sort_by {|key| key.to_s} == required.sort_by {|key| key.to_s}
    end

    def get_mash(*args)
      api_response = self.class.get(*args)
      result = {}
      result['meta'] = {}
      begin
        result['meta'] = api_response['response'].delete('meta')
        result['response'] = api_response['response']
      rescue MultiJson::LoadError
        result['meta']['message'] = api_response.body
      ensure
        result['meta']['http_code'] = api_response.code
        return mashup(result)
      end
    end

    def pluralize_result(result)
      result.kind_of?(Array) ? result : [result]
    end

    def fumsify(api_result, value)
      fumsified = Hashie::Mash.new
      fumsified.fums = api_result.meta.fums

      if value.kind_of?(Array)
        fumsified.collection = value
      else
        fumsified.value = value
      end

      fumsified
    end
end
