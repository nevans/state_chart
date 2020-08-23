# frozen_string_literal: true

require_relative "state_defs"

module StateChart

  module Builder

    class GenericStateDef < Definition

      def self.build!(name, parent:, id: nil, &block)
        if new(&block).atomic?
          State::Atomic.new(name, parent: parent, id: id, &block)
        else
          State::Compound.new(name, parent: parent, id: id, &block)
        end
      end

      def initialize(&block)
        return unless block_given?
        @compound = false
        tap do
          @break = -> { break } # short-circuit at first compound method call
          instance_exec(&block)
        end
      ensure
        @break = nil
        freeze
      end

      ATOMIC   = AtomicDef.instance_methods   - Definition.instance_methods
      COMPOUND = CompoundDef.instance_methods - AtomicDef.instance_methods

      ATOMIC.each do |method|
        define_method method do |*a, **kw, &b|
          # noop
        end
      end

      COMPOUND.each do |method|
        define_method method do |*a, **kw, &b|
          @compound = true
          @break.call
        end
      end

      def compound?; @compound end
      def atomic?;  !@compound end

    end

  end
end
