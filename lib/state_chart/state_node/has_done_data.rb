# frozen_string_literal: true

require_relative "../util"
require_relative "states_collection"

module StateChart

  class StateNode

    # manages done_data for {Final}
    module HasDoneData

      # @todo implement ...
      # @see https://www.w3.org/TR/scxml/#donedata
      # @see https://xstate.js.org/docs/guides/communication.html#done-data
      def done_data
      end

      def include_definition(other)
        super
        __copying_ivar__(other, :done_data) do |other_done_data|
          @done_data = other_done_data
        end
      end

      def finalize!
        done_data # trigger memoization before freeze
        super
      end

    end

  end
end
