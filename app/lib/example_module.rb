# frozen_string_literal: true
require 'json'
require_relative '../models/example'
require 'securerandom'

module VhostApi
  module Modules
    # Example module for handling Example objects/models
    module ExampleModule
      def index
        VhostApi::Models::Example.to_hash(:id).to_json
      end

      def show(id: nil)
        example = VhostApi::Models::Example[id]
        example ? example.to_json : {}.to_json
      end

      def create(*)
        example = VhostApi::Models::Example.create(name: SecureRandom.hex(16))
        example ? example.to_json : {}.to_json
      end

      def update(id: nil, _params: nil) end

      def delete(id: nil)
        example = VhostApi::Models::Example[id]
        example.destroy ? example.to_json : {}.to_json
      end
    end
  end
end
