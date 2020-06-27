# frozen_string_literal: true

require_relative "../util"
require_relative "states_collection"

module StateChart
  class StateNode

    module HasInitialState

      def initialize(*args, initial: nil, **opts)
        super(*args, **opts)
        self.initial = Transition.new(nil, target: initial) if initial
      end

      # @return [DefaultTransition] an initial state transition
      attr_reader :initial

      def initial=(transition)
        raise "initial transition already set: %p" % [@initial] if @initial
        validate_initial_transition!(transition)
        @initial = transition
      end

      def initial_state_value
        @initial.target or raise "no initial state"
      end

      def initial_state_node
        @states.fetch(initial_state_value)
      end

      def include_definition(other)
        super
        __copying_ivar__(other, :initial) do |i|
          @initial = i
        end
      end

      def finalize!
        self.initial ||= Transition.new(target: states.first.name)
        # TODO: verify initial or default target exists locally
        super
      end

    end

  end
end
