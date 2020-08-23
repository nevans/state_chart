# frozen_string_literal: true

require "forwardable"

require_relative "util"
require_relative "event"
require_relative "expressions"
require_relative "actions"

module StateChart

  class Transition
    include Util

    # @todo SCXML MUST specify at least one of 'event', 'cond' or 'target'.
    #       (immediate events must supply at least 'cond' or 'target')
    # @todo collapse redundant events, e.g. "foo foo.bar baz" into "foo baz"
    # @todo issue a warning for redundant events (e.g. "foo foo.bar")
    # @todo add mandatory @param source [state]
    def initialize(
      event_descriptor,
      target: nil,
      type: nil,
      actions: nil,
      **opts, # because :if and :unless are ruby keywords!
      &block
    )
      @event   = Events::Descriptors.new event_descriptor
      @target  = Target.new(target, type: type)
      @cond    = Expressions::Condition.new(**opts)
      @actions = Actions::Block.new(*actions)
      if block_given?
        Builder[self].build!(self, &block)
      end
      freeze # not deep frozen until target refs are resolved
    end

    extend Forwardable

    def_delegators :@event, :event, :events, :delay
    def_delegators :@event, :delay?, :event?, :wildcard?, :immediate?
    def_delegator :@event, :matches_name?, :matches_event_name?

    def_delegators :@target, :target, :target?
    def_delegators :@target, :type, :type?, :external?, :internal?
    def_delegator :@target, :resolve_references!
    def_delegator :@target, :states, :target_states
    def_delegator :@target, :ids, :target_ids

    def_delegators :@cond, :cond, :cond?, :unconditional?, :conditional?

    def_delegators :@actions, :actions, :actions?

    def transient?; immediate? && unconditional? end

    def only_target?
      target? && !(actions? || type? || cond?)
    end

    class Target

      TYPES = %i[internal external].freeze

      def initialize(target, type:)
        @to_s = validate_transition_target target
        @type = validate_transition_type   type
      end

      # Usually a single target state, but an array of targets is allowed if a
      # parallel state allows that to be a legal state configuration.
      #
      # @return [String] the string serialization for the target states
      attr_reader :to_s

      def to_a
        @to_s ? @to_s.split(/\s+/) : Util::EMPTY
      end

      alias target  to_s
      alias targets to_a

      # @return [:external,:interna;] the type of transition
      def type; external? ? :external : :internal end

      # @return [Boolean] was a target specified?
      def target?; !@to_s.nil? end

      # @return [Boolean] was a type explicitly specified?
      def type?; !@type.nil? end

      # @return [Boolean] is this an external transition?
      def external?; !@type || @type == :external end

      # @return [Boolean] is this an internal transition?
      def internal?;  @type && @type == :internal end

      def resolve_references!(source_state)
        @states = to_a.map {|ref| source_state.resolve_state(ref) }
      end

      def resolved?
        !!@states
      end

      def states
        raise Error, "need to resolve_references" unless resolved?
        @states
        # TODO: order by document order
      end

      def ids
        states.map {|s| s.id }
      end

      private

      # TODO: use {StateSet} for transition target
      def validate_transition_target(target)
        case target
        when nil
          nil
        when Util::Regex::VALID_REFS
          -target.to_s
        when Array
          -target.flat_map {|t| validate_transition_target(t) }.join(" ")
        else
          raise InvalidName, "invalid transition target: %p" % [target]
        end
      end

      def validate_transition_type(type)
        return nil if type.nil?
        type = type.to_sym
        unless TYPES.include?(type)
          raise ArgumentError, "invalid type %p" % [type]
        end
        type
      end

    end

  end

end
