# frozen_string_literal: true

require_relative "../transitions_list"
require_relative "../util"

module StateChart

  module Attrs
    module Transitions

      # to avoid name resolution annoyance and accidents
      Collection = ::StateChart::TransitionsList

      # n.b. transient nodes, on_done, on_error, after_timeout, etc are all
      # implemented as special event types, and implemented as transitions.
      #
      # @return [TransitionsList]
      def transitions
        if defined?(@transitions)
          @transitions
        elsif frozen?
          Collection::NULL_SET
        else
          @transitions = Collection.new
        end
      end

      # Represents delayed transitions. The transitions are all immediate (no
      # event), but they are keyed on a numeric (number of seconds after state
      # is entered) or a "delays" name (defined in the machine options)
      #
      # @return [TransitionsList]
      def after
        if defined?(@after)
          @after
        elsif frozen?
          Collection::NULL_SET
        else
          @after = Collection.new
        end
      end

      def freeze
        @transitions&.freeze
        @after&.freeze
        super
      end

      def resolve_references!
        @transitions&.each do |t| t.resolve_references!(self) end
        @after&.each do |t| t.resolve_references!(self) end
        super
      end

    end

  end
end
