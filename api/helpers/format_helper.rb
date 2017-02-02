# frozen_string_literal: true
require 'json'

module VhostApi
  module Helpers
    # Format module including various output/formatting helpers
    module Format
      def return_json_pretty(json)
        content_type :json, charset: 'utf-8'
        result = JSON.pretty_generate(JSON.parse(json)) + "\n"
        result_digest = Digest::SHA256.hexdigest(result)
        etag result_digest
        halt 304 if request.env['HTTP_IF_NONE_MATCH'] == result_digest
        result
      end
    end
  end
end
