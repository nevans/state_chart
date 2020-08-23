# frozen_string_literal: true

require_relative "../util"

module StateChart

  module Events

    # The value for an immediate transition's {#event}
    IMMEDIATE = ""

    # The value for an wildcard transition's {#event}
    WILDCARD = "*"

    WILDCARD_ARY = [WILDCARD].freeze
    private_constant :WILDCARD_ARY

    # All of the values that can be coerced to {IMMEDIATE}
    IMMEDIATES = [nil, IMMEDIATE, Util::EMPTY].freeze

    # From https://www.w3.org/TR/scxml/#EventDescriptors
    #
    # Like an event name, an event descriptor is a series of alphanumeric
    # characters segmented into tokens by the "." character. The 'event'
    # attribute of a transition consists of one or more such event descriptors
    # separated by spaces.
    #
    # A transition _matches_ an event if at least one of its event descriptors
    # matches the event's name.
    #
    # An event descriptor matches an event name if its string of tokens is an
    # exact match or a prefix of the set of tokens in the event's name. In all
    # cases, the token matching is case sensitive.
    #
    # For example, a transition with an 'event' attribute of "error foo" will
    # match event names "error", "error.send", "error.send.failed", etc. (or
    # "foo", "foo.bar" etc.) but would not match events named
    # "errors.my.custom", "errorhandler.mistake", "error.send" or "foobar".
    #
    # To make the prefix matching possibly more clear to a reader of the machine
    # definition, an event descriptor MAY also end with the wildcard '.*', which
    # matches zero or more tokens at the end of the processed event's name. Note
    # that a transition with 'event' of "error", one with "error.", and one with
    # "error.*" are functionally equivalent since they are token prefixes of
    # exactly the same set of event names.
    #
    # An event designator consisting solely of "*" can be used as a wildcard
    # matching any sequence of tokens, and thus any event. Note that this is
    # different from a transition lacking the 'event' attribute altogether. Such
    # an eventless transition does not match any event, but will be taken
    # whenever its 'cond' attribute evaluates to 'true'. The {Interpreter}
    # will check for such eventless transitions when it first enters a state,
    # before it looks for transitions driven by internal or external events.
    class Descriptors

      # The events matched by this transition
      #
      # @return [String] space-delimited list of event names
      attr_reader :to_s
      alias event to_s

      # (see #event)
      #
      # @return [Array<String>] an array of all matched event names. an immediate
      #                         returns an empty array
      attr_reader :to_a
      alias events to_a

      # How long to delay the transition, in seconds.
      #
      # @return [Numeric,Symbol,nil]
      attr_reader :delay

      def initialize(event_descriptor)
        @to_a = validate_transition_events event_descriptor
        @to_s = event_string_for(@to_a)
        @delay = event_descriptor.delay if event_descriptor.is_a?(Events::Delay)
        freeze
      end

      # @return [Boolean] is this a {Events::Delay}?
      def delay?; !!@delay end

      # @return [Boolean] is this a catch-all for *any* received event?
      def wildcard?;  @to_s == WILDCARD end

      # @return [Boolean] is this a pseudo-event, matched when entering a state?
      def immediate?; IMMEDIATES.include?(@to_s) end

      # @return [Boolean] was an event specified? (i.e. not immediate)
      def event?; !immediate? end

      def matches_name?(event_name)
        if IMMEDIATES.include?(event_name)
          immediate?
        else
          wildcard? ||
            events.include?(event_name) ||
            events.any? {|e| event_name.start_with?("#{e}.") }
        end
      end

      private

      def validate_transition_events(events)
        case events
        when *IMMEDIATES
          Util::EMPTY
        when WILDCARD
          WILDCARD_ARY
        when Array
          validate_transition_events_array(events)
        when Util::Regex::SCXML::EVENT_NAMES
          validate_transition_events_array(events.to_s.split(/\s+/))
        when Event
          [events.name].freeze
        else
          raise InvalidName, "invalid Transition events: %p" % events
        end
      end

      def validate_transition_events_array(events)
        events
          .map {|e| Util.validate_event_name(e) }
          .sort.uniq.freeze
      end

      def event_string_for(events)
        if events.empty?
          IMMEDIATE
        elsif events.include?(WILDCARD)
          WILDCARD
        else
          -events.join(" ")
        end
      end

    end

  end
end
