# frozen_string_literal: true

require_relative "state_node/base"
require_relative "state_node/has_actions"
require_relative "state_node/has_children"
require_relative "state_node/has_done_data"
require_relative "state_node/has_history"
require_relative "state_node/has_initial_state"
require_relative "state_node/has_meta_data"
require_relative "state_node/has_state_id"
require_relative "state_node/has_transitions"

module StateChart
  class StateNode

    include Util
    include Base
    include HasStateId
    include HasMetaData
    include HasActions
    # include HasActivities
    # include HasServices

    def initial?
      parent && self.match?(parent.initial_state_value)
    end

    def match?(state_value)
      state_value == name || state_value == id
    end

    class Chart < StateNode
      include HasInitialState
      include HasChildren
      include HasTransitions
    end

    # An {Atomic} node with no transitions. aka "terminal" node
    class Final < StateNode
      include HasDoneData
    end

    # Has no child state nodes. aka "leaf" node
    class Atomic < StateNode
      include HasTransitions
    end

    # Represents being in one of its child states at a time. aka "heirarchical"
    class Compound < StateNode
      include HasInitialState
      include HasChildren
      include HasTransitions
    end

    # Represents being in all of child states at the same time.
    #
    # @todo...
    class Parallel < StateNode
      include HasChildren
      include HasTransitions
    end

    class History < StateNode
      include HasInitialState
      include HasTransitions
      include HasHistory
    end

  end
end
