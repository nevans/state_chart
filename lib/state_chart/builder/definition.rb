# frozen_string_literal: true

module StateChart

  module Builder

    class Definition

      def self.build!(node, &block)
        build_ctx = new(node)
        build_ctx.instance_exec(&block) if block
      end

      # delegate const_missing to Object, to avoid annoying surprises
      def self.const_missing(name) ::Object.const_get(name) end

      def initialize(node)
        @node = node
      end

    end

  end
end
