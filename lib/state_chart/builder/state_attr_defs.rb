# frozen_string_literal: true

module StateChart

  module Builder

    ########################################################################
    # attribute builders, follows a roughly parallel shape to {Attr}
    ########################################################################

    module MetaDataAttr
      # TODO... raise exception on conflicts
      def meta(**attrs)
        @node.meta_data.merge!(**attrs)
      end
    end

    module DataModelAttr
      # Defines an attribute for a {DataModel}.
      #
      # @param name [String,Symbol] the attribute name.
      #   must match XML_Name. if it matches VALID_NAME, a method will be
      #   created with that name.
      # @param visibility [:public, :private]
      #   If the attribute reader is visible from outside the machine's context.
      #   Writers are always private.
      # @param default [nil,Numeric,String,Symbol,Array,Hash#call] the default.
      #   Strings must be frozen (Numeric and Symbol are always frozen).
      #   Arrays and Hashes must be deeply frozen and composed only frozen
      #   Strings, Symbols, Numeric, or nil (including Hash keys).
      #   callable will return the default value and must accept up to three
      #   args:
      #     first arg is the data to coerce.
      #     second arg is the {Machine} object.
      #     third arg is the attribute's {State} or {Chart}
      #   callable _may_ access an external service for non-deterministic data.
      # @param type [Symbol,Regexp,Module,Class,#call,#===] a matcher or coercer
      #   A Symbol, Regexp, or Module/Class is matched using +===+.
      #   A callable must return the coerced value and must accept up to three
      #   arguments:
      #     first arg is the data to coerce.
      #     second arg is the {Machine} object.
      #     third arg is the attribute's {State} or {Chart}
      def attribute(name, **opts)
        attr = DataModel::Attribute.new(name, **opts)
        @node.attributes << attr
        @node.chart.id_map << attr
      end
    end

    module ActionsAttrs

      # TODO...
      def on_entry(action = nil, &block)
        @node.on_entry << action || block
      end

      # TODO...
      def on_exit(action = nil, &block)
        @node.on_exit << action || block
      end

      # TODO...
      def service(name, **opts, &block)
        @node.services << [name, opts, block]
      end

    end

    # for state, states, and parallel
    #
    # initial and history are handled differently than SCXML
    #
    # Several different ways to call:
    #
    # creating a single transition (all allow an optional block):
    #
    #     on EVENT, TARGET
    #     on EVENT, **attrs
    #     on EVENT => TARGET, <if,unless>: predicate
    #
    # creating multiple transitions (block is prohibited):
    #
    # for a single event:
    #
    #     on EVENT, [TARGET1, TARGET2, {**attrs3}, {**attrs4}]
    #
    # for multiple events:
    #
    #     on(EVENT1 => TARGET1,
    #        EVENT2 => {**attrs2},
    #        EVENT3 => [TARGET3, {**attrs4}])
    #
    module TransitionAttrs

      def on(event, transitions = nil, &block)
        @node.transitions << TransitionDef.on_event(event, transitions, &block)
      end

      def after(delay, transitions = nil, &block)
        event = Events::Delay.new(delay)
        @node.after << TransitionDef.on_event(event, transitions, &block)
      end

    end

    # for chart, states (compound), and parallel
    #
    # n.b. parallel states can't have 'final' immediate children
    module ParentNodeAttrs

      # @todo merge {#state} and {#states}
      def state(name, id: nil, &block)
        GenericStateDef.build!(name, parent: @node, id: id, &block)
      end

      def parallel(name, id: nil, &block)
        State::Parallel.new(name, parent: @node, id: id, &block)
      end

    end

    # for chart and states (not parallel)
    module HistoryStateAttr
      def history(name, type: nil, id: nil, &block)
        type ||= "deep" if name.include?("deep")
        type ||= "shallow"
        History.build!(
          name, type: type, parent: @node, id: id, &block
        )
      end
    end

    module DoneDataAttr
      def done_data
        # TODO ...
      end
    end

    module InitialStateAttr
      def initial(target, &block)
        @node.initial = Transition.new(nil, target: target, &block)
      end
    end

    module FinalStateAttr
      def final(name, id: nil, &block)
        State::Final.new(name, parent: @node, id: id, &block)
      end
    end

  end
end
