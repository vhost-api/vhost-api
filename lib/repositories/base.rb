# frozen_string_literal: true
module VhostApi
  module Repositories
    # Base repository class for communication with the ORM/database
    class Base
      def all
        []
      end

      def find(_id = nil)
        {}
      end

      def first
        {}
      end

      def last
        {}
      end

      def create(_data = nil)
        {}
      end

      def update(_id = nil, _data = nil)
        {}
      end

      def delete(_id = nil)
        nil
      end

      def clear
        nil
      end
    end
  end
end
