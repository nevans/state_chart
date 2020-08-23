# frozen_string_literal: true

require_relative "../util"

module StateChart

  module Attrs

    # manages done_data for {Final}
    module DoneData

      # @todo implement ...
      # @see https://www.w3.org/TR/scxml/#donedata
      # @see https://xstate.js.org/docs/guides/communication.html#done-data
      def done_data
        if defined?(@done_data)
          @done_data
        elsif frozen?
          Util::EMPTY_HASH
        else
          @done_data = {}
        end
      end

      def freeze
        @done_data&.freeze
        super
      end

    end

  end
end
