# frozen_string_literal: true

module StateChart
  class StateNode

    # @todo...
    module HasHistory

      # @return [:deep, :shallow] deep or shallow history (default: shallow)
      def history_type
        @history_type.nil? ? :shallow : :deep
      end

      def shallow?; !@history_type || (@history_type == :shallow) end
      def deep?;   !!@history_type && (@history_type == :deep)    end

    end

  end
end
