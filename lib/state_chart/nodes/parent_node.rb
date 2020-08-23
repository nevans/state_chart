# frozen_string_literal: true

require_relative "../errors"
require_relative "state_collection"

module StateChart

  module Nodes

    module ParentNode

      # @return [States::Collection]
      def states
        if defined?(@states)
          @states
        elsif frozen?
          StateCollection::NULL_SET
        else
          @states = StateCollection.new
        end
      end

      def <<(identifiable)
        chart.id_map << identifiable
        if identifiable.kind_of?(State)
          states << identifiable
        end
        self
      end

      def initialize_done
        if states.empty?
          raise Error, "Must have at least one child state: %p" % [self]
        end
        super
      end

      def resolve_references!
        super
        @states&.each do |_, state|
          state.resolve_references!
        end
      end

      def freeze
        states.freeze
        super
      end

    end

  end
end
