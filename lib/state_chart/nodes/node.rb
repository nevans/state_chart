# frozen_string_literal: true

require_relative "../util"
require_relative "../state_ref"

module StateChart

  module Nodes

    class Node
      include Util

      def initialize(*args, **attrs, &block)
        initialize_attrs(*args, **attrs)
        initialize_block(&block)
        initialize_done
      end

      def inspect
        "#<%s:0x%x %s>" % [
          self.class, object_id, inspect_attrs.join(" ")
        ]
      rescue => ex
        "#{super} (raised [#{ex.class}] #{ex})"
      end

      alias to_s inspect

      # @return [State]
      def resolve_state(reference)
        StateRef.resolved(reference, referrer: self)
      end

      def dig(*path_segments)
        node = self
        until node.nil? || path_segments.empty?
          first, *path_segments = path_segments
          node =
            case first
            when StateRef::SELF; node
            when StateRef::PARENT; node.parent
            else node.respond_to?(:states) ? node.states[first] : nil
            end
        end
        node
      end

      # called when the chart has been completely built
      def resolve_references!
        # noop: implement in subclasses
      end

      private

      # @abstract for subclasses to override
      def initialize_attrs(*args, **attrs)
        # TODO: iterate over attributes ...
      end

      def initialize_block(&block)
        if block_given?
          Builder[self].build!(self, &block)
        end
      end

      # Called at the end of this object's initialize
      #
      # All attributes and children are built and done, except external refs.
      #
      # Should be used for validation of children.
      def initialize_done
        # noop: implement in subclasses
      end

      def inspect_attrs
        Util::EMPTY
      end

    end

  end
end
