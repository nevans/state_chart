# frozen_string_literal: true

require_relative "../util"
require_relative "../nodes/identifiable"

module StateChart

  module DataModel

    class Attribute # < Node::Identifiable

      def initialize(name, default: nil, type: nil, &block)
        raise ArgumentError if !default.nil? && block
        @name    = Util.validate_name_format(name)
        @default = default.nil? ? block : default
        @type    = type
      end

      attr_reader :name, :default, :type

      alias id name

    end

  end
end
