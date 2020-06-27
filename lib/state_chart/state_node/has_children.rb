# frozen_string_literal: true

require_relative "../util"
require_relative "states_collection"

module StateChart

  class StateNode

    module HasChildren

      # @return [Hash{String,Symbol => StateNode}]
      def states
        @states ||= StatesCollection.new
      end

      def include_definition(other)
        super
        __copying_ivar__(other, :states) do |other_states|
          other_states.each do |_, state|
            self.states << state.deep_dup_reparent(self)
          end
        end
      end

      def finalize!
        raise Error, "Cannot have empty states" if states.empty?
        super
      end

    end

  end
end
