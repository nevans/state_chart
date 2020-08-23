# frozen_string_literal: true

require_relative "nodes/identifiable"
require_relative "attrs"

module StateChart

  # @abstract This is the superclass of all "state-like" chart nodes.
  #
  # A state chart definition is composed of a tree of {State}s.  The root of
  # the tree is a {State::Chart}, which closely resembles a {State::Compound}
  # node.
  #
  # Here is the class heirarchy:
  #
  #                                          Node
  #                                           |
  #                                      Identifiable
  #                                     /            \
  #                                    /              \
  #                               State                Attrs,Services,Etc
  #                              /     \
  #                    LegalState       PseudoState
  #                     /      \             |
  #              NonfinalState  \            |
  #               /      \       \           |
  #        ParentState    \       \          |
  #         /       \      \       \         |
  #     Parallel  Compound  Atomic  Final  History
  #
  # Although, after implementing {Machine}, it might make more sense for
  # {Compound} and {Atomic} to both inherit from "Sequential" (dropping both
  # NonfinalState and ParentState).
  #
  class State < Nodes::Identifiable

    include Attrs::MetaData

    def final?; false end
    def atomic?; false end
    def compound?; false end
    def parallel?; false end

    # @todo match by ID or by path (siblings can target by relative path)
    def match?(state_value)
      state_value == name || state_value == id
    end

    def enabled_transitions_for_event_name(event_name)
      return to_enum(__method__, event_name) unless block_given?
      node = self
      while node
        node.transitions.matching_event_name(event_name) do |t|
          yield t
          return if t.unconditional?
        end
        node = node.parent
      end
      nil
    end

    class LegalState < State
      include Attrs::Actions
      include Attrs::DataModel
      # include Attrs::Activities
      # include Attrs::Services

      def pseudo?; false end
    end

    class PseudoState < State
      def pseudo?; true end
    end

    class NonfinalState < LegalState
      include Attrs::Transitions
      def final?;  false end
    end

    # @abstract ...
    class ParentState < NonfinalState
      include Nodes::ParentNode
      def atomic?; false end
    end

    # Has no child state nodes. aka "leaf" node
    class Atomic < NonfinalState
      def atomic?; true end
    end

    # An atomic node with no transitions. aka "terminal" node
    class Final < LegalState
      include Attrs::DoneData
      def atomic?; true end
      def final?;  true end
    end

    # Represents being in one of its child states at a time. aka "heirarchical"
    class Compound < ParentState
      include Attrs::InitialState
      def compound?; true end
    end

    # Represents being in all of child states at the same time. aka "orthoganal"
    class Parallel < ParentState
      def parallel?; true end
    end

    # A pseudo-state, which remembers and immediately transitions into one or
    # more of its parent's descendant states.
    class History < PseudoState
      include Attrs::InitialState
      include Attrs::History
    end

  end
end
