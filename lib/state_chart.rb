# frozen_string_literal: true

require_relative "state_chart/version"
require_relative "state_chart/errors"
require_relative "state_chart/util"

require_relative "state_chart/nodes"

require_relative "state_chart/actions"
require_relative "state_chart/chart"
require_relative "state_chart/data_model"
require_relative "state_chart/expressions"
require_relative "state_chart/event"
require_relative "state_chart/state"
require_relative "state_chart/transition"

require_relative "state_chart/builder"

# The {StateChart} library can be used to
# * create and interrogate {Chart} definitions,
# * use {Interpreter#call} to transform a {Machine::State} and an {Event} into a
#   new {Machine::State}
# * use {Machine} to execute {Event} queues, keeping track of {Machine::State}.
# * use a {Machine::Compiler} to convert a {Machine} into forms with different
#   APIs or execution profiles.
#
# _n.b:_ Our "interpreter" vs "machine" terminology is the _opposite_ of
# `xstate`.
#
# Note that the term "state" is overloaded. It can refer to:
#
# * A {State} node within a {Chart} definition.
#   * This is what SCXML usually means when it refers to "state", and so it is
#   what this library will mean when we refer to {State} without qualifiers.
#   * `xchart` refers to nodes in the chart definition as "StateNode".
# * A {Machine::State} which combines:
#   * A {StateSet} that holds all of {State}s a {Machine} is currently in.
#     * SCXML refers to this as the machine's "configuration".
#   * A mapping of history nodes to their remembered {StateSet}s.
#   * A {DataModel} instance, which may also be called the "extended state".
#
# _n.b._ What `xstate` refers to as "State" we call {Event::Result}.
# {Event::Result} combines a {Machine::State} with {Services} that should be
# invoked and curried {Actions} that should be executed.  I think it's probably
# best to think of this as more than just "state": it's both the next state and
# the curried actions that should be executed en route into that state.
#
module StateChart

  def self.chart(name = nil, initial: nil, &definition)
    Chart.new(name: name, initial: initial, &definition)
  end

end
