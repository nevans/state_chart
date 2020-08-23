# frozen_string_literal: true

require_relative "../errors"
require_relative "../util"
require_relative "ordered_map"

module StateChart

  module Util

    class IDMap < OrderedMap

      def initialize(chart)
        super()
        @chart = chart
      end

      # @return [Chart] the chart this id map belongs to
      #
      # Used to ensure that any added nodes also belong to the same chart.
      attr_reader :chart

      def states;     grep_values(State) end
      def attributes; grep_values(DataModel::Attribute) end

      def state_ids;     states.map(&:id) end
      def attribute_ids; attributes.map(&:id) end

      private

      def grep_values(matcher)
        values.grep(matcher).inject(IDMap.new(chart), &:<<)
      end

      def key_for(key)
        key.to_sym
      end

      def name_for(value)
        if value.is_a?(Nodes::Identifiable)
          id = value.id.to_sym
          if !Regex::VALID_ID.match?(id)
            raise InvalidName, "Invalid ID (%p) for %p" % [id, value]
          elsif value.chart != chart
            raise Error, "Value is not a member of chart."
          end
          id
        elsif value.is_a?(DataModel::Attribute)
          id = value.id.to_sym
          if !Regex::VALID_ID.match?(id)
            raise InvalidName, "Invalid ID (%p) for %p" % [id, value]
          end
          id
        else
          raise TypeError, "Invalid value for ID map (%p => %p)" % [id, value]
        end
      end

    end
  end
end
