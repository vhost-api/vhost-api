# frozen_string_literal: true
require 'lib/serializable_error'
require 'lib/repositories/base'
require 'lib/models/example'
require 'securerandom'

module VhostApi
  module Repositories
    # Example repository class for talking to the ORM
    class Example < VhostApi::Repositories::Base
      def all
        VhostApi::Models::Example.naked.to_hash(:id)
      end

      def find(id = 0)
        example = VhostApi::Models::Example[id]
        example ? example.to_hash : nil
      end

      def first
        example = VhostApi::Models::Example.first
        example ? example.to_hash : nil
      end

      def last
        example = VhostApi::Models::Example.last
        example ? example.to_hash : nil
      end

      def create(_data = nil)
        example = VhostApi::Models::Example.create(name: SecureRandom.hex(16))
        example ? example.to_hash : nil
      end

      def update(id = 0, data = nil) end

      def delete(id = 0)
        example = VhostApi::Models::Example[id]
        raise SerializableError, 'delete failed' unless example.destroy
        {}
      end

      def clear
        VhostApi::Models::Example.delete
      end
    end
  end
end
