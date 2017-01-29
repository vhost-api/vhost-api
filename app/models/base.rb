# frozen_string_literal: true
require 'sequel'
require_relative '../../vhost_api_app'

class VhostApi
  class Models
    Base = Class.new(Sequel::Model)
    # Base model
    class Base
      # enable json serializing
      plugin :json_serializer

      def before_create
        self.created_at ||= Time.now.to_i
        self.updated_at ||= Time.now.to_i
        super
      end

      def before_update
        self.updated_at = Time.now.to_i
        super
      end
    end
  end
end
