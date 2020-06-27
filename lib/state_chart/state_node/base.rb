# frozen_string_literal: true

require_relative "../util"

module StateChart

  class StateNode

    # needed for inheritance to work on modules include in {StateNode}
    module Base

      def finalize!
        freeze
      end

      def include_definition(other)
        unless self.class <= other.class
          raise ArgumentError, "bad type %p to merge into %p" % [other, self]
        end
        # copying of actual data is handled by descendent mixins
      end

      protected

      def deep_dup_reparent(new_parent)
        # puts "<##{self.id}>.deep_dup_reparent(<##{new_parent.id}>)"
        dupped = self.class.new(name, parent: new_parent, id: nil)
        dupped.include_definition(self)
        dupped
      end

      private

      def __copying_ivar__(other, attr, &b)
        # puts "<##{self.id}>.__copying_ivar__(<##{other.id}>, #{attr}) {...}"
        val = other.instance_variable_get(:"@#{attr}")
        b.call val if val
      end

    end

  end
end
