# frozen_string_literal: true

require_relative "../util"
require_relative "actions"

module StateChart

  class StateNode

    # manages on_entry, on_exit
    module HasActions

      # @return [Array<Action>] node entry actions
      def on_entry
        @on_entry ||= []
      end

      # @return [Array<String,Symbol>] node exit actions
      def on_exit
        @on_exit ||= []
      end

      def include_definition(other)
        super
        __copying_ivar__(other, :on_entry) do |other_entry|
          @on_entry = other_entry
        end
        __copying_ivar__(other, :on_exit) do |other_exit|
          @on_exit = other_exit
        end
      end

      def finalize!
        on_entry # trigger memoization before freeze
        on_exit  # trigger memoization before freeze
        super
      end

    end

  end
end
