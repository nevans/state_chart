# frozen_string_literal: true

module StateChart
  module Attrs

    module InitialState

      def initialize(*args, initial: nil, **opts, &block)
        self.initial = Transition.new(nil, target: initial) if initial
        super(*args, **opts, &block)
      end

      # @return [Transition,nil] an initial state transition
      attr_reader :initial

      # @todo ensure initial_state is a descendant
      def initial=(transition)
        raise "initial transition already set: %p" % [@initial] if @initial
        validate_initial_transition!(transition)
        @initial = transition
      end

      def initial_state
        @initial_state || states.values.first
      end

      # @todo ensure initial_state is a descendant
      # @todo ensure initial_state has only one target_state
      def initialize_done
        @initial&.resolve_references!(self)
        @initial_state = initial ? initial.target_states.first : states.values.first
        super
      end

      def freeze
        @initial.freeze
        super
      end

      def resolve_references!
        @initial&.resolve_references!(self)
        super
      end

      private

      # valid local target should be verified during initialize_done
      def validate_initial_transition!(transition, name: "initial")
        if !transition.kind_of?(Transition)
          raise "must set #{name} with a transition"
        elsif !transition.target
          raise "must set target on #{name} transition"
        elsif !transition.only_target?
          raise "must only set target on #{name} transition"
        end
      end

    end

  end
end
