# frozen_string_literal: true

require_relative "../transitions"
require_relative "../util"

module StateChart

  class StateNode
    module HasTransitions

      # n.b. transient nodes, on_done, on_error, after_timeout, etc are all
      # implemented as special event types, and implemented as transitions.
      #
      # @return [Transitions]
      def transitions
        @transitions ||= Transitions.new
      end

      # Represents delayed transitions. The transitions are all immediate (no
      # event), but they are keyed on a numeric (number of seconds after state
      # is entered) or a "delays" name (defined in the machine options)
      #
      # @return [Transitions]
      def after
        @after ||= Transitions.new
      end

      def finalize!
        # create empty collections before freezing
        transitions
        after
        super
      end

      def include_definition(other)
        super
        __copying_ivar__(other, :after) do |other_afters|
          other_afters.each do |delay, transitions|
            after.add(transition, key: delay)
          end
        end
        __copying_ivar__(other, :transitions) do |other_transitions|
          other_transitions.each do |key, t|
            transitions.add(t, key: key)
          end
        end
      end

    end

  end
end
