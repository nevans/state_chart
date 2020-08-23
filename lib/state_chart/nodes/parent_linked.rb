# frozen_string_literal: true

require_relative "../errors"
require_relative "node"

module StateChart

  module Nodes

    class ParentLinked < Node

      # @return [Chart] the state chart this {State} belongs to
      attr_reader :chart

      # return [nil, ChartRoot, Compound, Parallel]
      attr_reader :parent

      def each_node_up_to_top
        return to_enum(__method__) unless block_given?
        node = self
        while node
          yield node
          node = node.respond_to?(:parent) && node.parent
        end
      end

      def is_ancestor_of?(other)
        other.is_descendant_of?(self)
      end

      def is_descendant_of?(other)
        raise Error, "States have different charts" unless other.chart == chart
        each_node_up_to_top.any? {|node| node == other }
      end

      private

      def initialize_attrs(*args, parent:, **attrs, &block)
        super
        @parent = parent or raise ArgumentError, "must provide parent"
        @chart = parent.chart
      end

      # Override to add into parent after all subclasses have initialized attrs
      # but before running the block (which may add child nodes).
      def initialize_block(...)
        parent << self
        super
      end

    end

  end
end
