# frozen_string_literal: true

require_relative "builder/definition"
require_relative "builder/state_defs"
require_relative "builder/transition_def"
require_relative "builder/generic_state_def"

require_relative "chart"
require_relative "state"
require_relative "transition"

module StateChart

  module Builder

    BUILDERS = {
      Chart           => ChartDef,
      State::Atomic   => AtomicDef,
      State::Compound => CompoundDef,
      State::Parallel => ParallelDef,
      State::Final    => FinalDef,
      Transition      => TransitionDef,
    }.freeze

    def self.[](klass)
      klass = klass.class unless klass.is_a?(Class)
      BUILDERS.fetch(klass)
    end

    def self.node_class_for(builder_class)
      BUILDERS.invert.fetch(builder_class)
    end

  end
end
