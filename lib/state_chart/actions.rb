# frozen_string_literal: true

module StateChart

  # SCXML refers to these as "executable content"
  module Actions

    # TODO: everything in here...
    class Block

      def initialize(*actions)
        @actions = actions
      end

      # @return [Array<Action>]
      attr_reader :actions
      alias to_a actions

      def actions?; !@actions.empty? end

      def freeze
        @actions.freeze
        super
      end

    end

  end
end
