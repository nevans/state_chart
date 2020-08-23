# frozen_string_literal: true

require_relative "definition"
require_relative "../transition"
require_relative "transitions_transform"

module StateChart

  module Builder

    class TransitionDef < Definition

      extend TransitionsTransform

      def self.on_event(events, opts = nil, &block)
        TransitionsTransform.call(events, opts, &block).map {|args, attrs, b|
          Transition.new(args, **attrs, &b)
        }
      end

    end

  end
end
