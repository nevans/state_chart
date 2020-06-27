# frozen_string_literal: true

require_relative "../util"

module StateChart

  class StateNode

    class StatesCollection < Hash

      def <<(state)
        unless StateNode === state
          raise ArgumentError, "invalid state: %p" % [state]
        end
        key = state.name
        raise InvalidName, "already used name: %p" % [key] if self[key]
        self[key] = state
        self
      end

      def [](name)
        if Symbol === name
          super name.to_s
        else
          super name.to_str
        end
      end

      def fetch(key, default = Util::UNDEFINED, &block)
        if Symbol === key
          key = key.to_s
        else
          key = key.to_str
        end
        if default != Util::UNDEFINED
          super(key, default, &block)
        else
          super(key, &block)
        end
      end

    end

  end
end
