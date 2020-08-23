module StateChart

  module Builder

    module TransitionsTransform

      module_function

      def call(events, multi_opts, &block)
        if multi_opts.is_a?(Array)
          guard_multiple_transition_opts!(&block)
          multi_opts.map {|opts| new_transition_args(events, opts) }
        elsif events.is_a?(Hash) && !multi_opts
          multi_args_from_hash(**events, &block)
        else
          [new_transition_args(events, multi_opts, &block)]
        end
      end

      def multi_args_from_hash(**events, &block)
        cond = extract_cond!(events)
        if events.length <= 1
          event, target = events.first
          opts = {target: target, **cond}
          [new_transition_args(event, opts, &block)]
        else
          guard_multiple_transition_opts!(**cond, &block)
          events.flat_map {|event, opts| call(event, opts) }
        end
      end

      # keywords make annoying kwargs
      def extract_cond!(transitions)
        cond = transitions.slice(:if, :unless)
        transitions.delete(:if)
        transitions.delete(:unless)
        cond
      end

      def new_transition_args(event, opts, &block)
        attrs = new_transition_attrs(opts) or
          raise_invalid_transitions!(event, opts)
        [event, attrs, block]
      end

      def new_transition_attrs(opts)
        case opts
        when nil; {}
        when Symbol, String; {target: opts}
        when Hash; {**opts}
        end
      end

      def guard_multiple_transition_opts!(**cond)
        if block_given?
          raise ArgumentError, "block with multiple transitions"
        elsif cond.any?
          raise ArgumentError, "%s on multiple transitions" % [cond.keys]
        end
      end

      def raise_invalid_transitions!(*args)
        raise ArgumentError, "invalid transition args: %p" % [args]
      end

    end

  end
end
