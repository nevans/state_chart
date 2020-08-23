# frozen_string_literal: true

require_relative "../errors"
require_relative "parent_linked"

module StateChart

  module Nodes

    class PathReferable < ParentLinked

      # @return [Array<String>] path from the root node to here, by name
      attr_reader :path

      # Identifier which must be unique among sibling states.
      #
      # Must be a valid ruby identifier (e.g. variable, method, constant) and
      # not a ruby keyword.  Although ruby does allow using most keywords as
      # method names, it is usually less annoying to simply avoid them anyway.
      #
      # @return [String,Symbol]
      def name
        @path.last
      end

      private

      def initialize_attrs(name, **attrs, &block)
        super
        name    = validate_name_format(name)
        @path   = [*parent.path, name].freeze
      end

      def inspect_attrs
        super + [
          path&.join("."),
        ].compact
      end

    end

  end
end
