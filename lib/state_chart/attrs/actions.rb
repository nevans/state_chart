# frozen_string_literal: true

require_relative "../util"

module StateChart

  module Attrs

    # manages on_entry, on_exit
    module Actions

      # @return [Array<Action>] node entry actions
      def on_entry
        if defined?(@on_entry)
          @on_entry
        elsif frozen?
          Util::EMPTY
        else
          @on_entry = []
        end
      end

      # @return [Array<String,Symbol>] node exit actions
      def on_exit
        if defined?(@on_exit)
          @on_exit
        elsif frozen?
          Util::EMPTY
        else
          @on_exit = []
        end
      end

      def services
        if defined?(@services)
          @services
        elsif frozen?
          Util::EMPTY
        else
          @services = []
        end
      end

      def freeze
        @on_entry&.freeze
        @on_exit&.freeze
        @services&.freeze
        super
      end

    end

  end
end
