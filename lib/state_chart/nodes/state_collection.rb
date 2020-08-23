# frozen_string_literal: true

require "forwardable"

require_relative "../util/ordered_map"

module StateChart

  module Nodes

    class StateCollection < Util::OrderedMap

      NULL_SET = new.freeze

      alias names keys

      private

      def key_for(key)
        key.is_a?(Symbol) ? key.to_s : key.to_str
      end

      def name_for(state)
        unless state.is_a?(State)
          raise ArgumentError, "not a State: %p" % [state]
        end
        state.name.to_s
      end

    end

  end
end
