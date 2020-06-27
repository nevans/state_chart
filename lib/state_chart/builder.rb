# frozen_string_literal: true

require_relative "state_node"
require_relative "transition"

# TODO: do we want this dependency? maybe just use BasicObject and simplify?
require "docile"

module StateChart

  module Builder

    class BuildContext
      include Util

      # The builder methods are class level so they don't pollute the DSL.
      class << self

        def build!(*args, **opts, &block)
          build_ctx = new(*args, **opts)
          run(build_ctx, &block)
          finalize!(build_ctx)
        end

        # This refers to any built node in the object tree, not just StateNode.
        def node_class
          raise NotImplementedError
        end

        def new_node(...)
          node_class.new(...)
        end

        def run(build_ctx, &block)
          if block
            Docile.dsl_eval(build_ctx, &block)
          end
        end

        def finalize!(build_ctx)
          node = build_ctx.node
          node.finalize! if node.respond_to?(:finalize!)
          node.freeze unless node.frozen?
          node
        end

      end

      attr_reader :node

      def initialize(...)
        @node = self.class.new_node(...)
      end

    end

    # for Final
    class Final < BuildContext
      def self.node_class; StateNode::Final end

      def after(delay, transition, &block)
        unless Numeric === delay
          delay = validate_name_format!("after delay", delay)
        end
        @node.after.add Transition.multi!(nil, transition, &block), key: delay
      end

    end

    # for Atomic
    class State < Final
      def self.node_class; StateNode::Atomic end

      def on(event, transitions = nil, &block)
        @node.transitions << Transition.multi!(event, transitions, &block)
      end

    end

    # for Compound
    class States < State
      def self.node_class; StateNode::Compound end

      def initial(transition, &block)
        @node.initial = Transition.build!(nil, transition, &block)
      end

      def state(name, id: nil, &block)
        @node.states << State.build!(name, parent: @node, id: id, &block)
      end

      def states(name, id: nil, &block)
        @node.states << States.build!(name, parent: @node, id: id, &block)
      end

      def include_definition(other)
        @node.include_definition(other)
      end

    end

    class Transition < BuildContext
      def self.node_class; StateChart::Transition end

      def self.multi!(event, transitions, &block)
        if Hash === event
          guard_block_multiple_transitions!(&block) if event.length > 1
          raise_invalid_transitions!(event, transitions) if transitions
          event.flat_map {|e, t| multi!(e, t) }
        else
          case transitions
          when Array
            guard_block_multiple_transitions!(&block)
            transitions.flat_map {|t| build!(event, t, **{}) }
          else
            build!(event, transitions, **{}, &block)
          end
        end
      end

      def self.new_node(event, transitions)
        case transitions ||= {}
        when Symbol, String
          super(event, target: transitions)
        when Hash
          super(event, **transitions)
        else
          raise_invalid_transitions!(event, transitions) if transitions
        end
      end

      def self.guard_block_multiple_transitions!
        if block_given?
          raise ArgumentError, "cannot use block with multiple transitions"
        end
      end

      def self.raise_invalid_transitions!(*transitions)
        raise ArgumentError, "invalid transitions: %p" % [transitions]
      end

    end

  end
end
