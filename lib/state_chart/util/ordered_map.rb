# frozen_string_literal: true

require "forwardable"

require_relative "../util"

module StateChart

  module Util

    class OrderedMap
      include Enumerable
      extend Forwardable

      def initialize
        @h = {}
      end

      # {#dup} and {#clone} give deep copies
      def initialize_copy(other)
        super
        @h = @h.transform_values {|val| val.clone }
      end

      def eql?(other)
        self.class == other.class && @h == other.instance_variable_get(:"@h")
      end

      alias == eql?

      def freeze
        @h.freeze
        @h.values.each do |val| val.freeze end
        super
      end

      def [](key)
        fetch(key, nil)
      end

      def fetch(key, *default, &block)
        if key.is_a?(Integer)
          @h.values.fetch(key, *default, &block)
        else
          key = key_for(key)
          @h.fetch(key, *default, &block)
        end
      end

      def <<(member)
        name = name_for(member)
        raise InvalidName, "already used name: %p" % [name] if @h.key?(name)
        @h[name] = member
        self
      end

      def_delegators :@h, :hash
      def_delegators :@h, :each
      def_delegators :@h, :empty?, :length
      def_delegators :@h, :keys, :values, :key?, :transform_values

      private

      def key_for(key)
        key.to_str
      end

      # can also validate member here
      def name_for(member)
        member.name.to_str
      end

    end
  end
end
