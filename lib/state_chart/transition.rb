# frozen_string_literal: true

require_relative "util"

module StateChart

  class Transition
    IMMEDIATE = ""
    WILDCARD = "*"

    include Util

    def initialize(event, cond: true, target: nil, type: nil, actions: nil)
      @event  = validate_transition_event(event)
      @cond   = validate_cond_format(cond)
      @target = validate_name_format!("target", target, nullable: true)
      @type   = validate_transition_type(type)
      actions&.each do |a|
        action a
      end
    end

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
    #
    # @return [String,Symbol,nil]
    attr_reader :event

    # An array of targets is only allowed with {StateNode::Parallel}.
    #
    # @return [String,Symbol,StateNode,Array<String,Symbol,StateNode>]
    attr_reader :target

    # @return [Array<Action>]
    def actions
      defined?(@actions) ? @actions : (frozen? ? [] : @actions = [])
    end

    # @return [Boolean] if transition into self triggers actions
    attr_reader :external

    # @return [true,String] guard condition for this transition
    attr_reader :cond

    def external?; !@type || @type == :external end
    def internal?;  @type && @type == :internal end

    def type; external? ? :external : :internal end

    def immediate?; event == IMMEDIATE || event.nil?  end
    def transient?; immediate? && !cond? end

    def event?; !immediate? end
    def actions?; !(@actions.nil? || @actions.empty?) end
    def target?; !@target.nil? end
    def type?; !@type.nil? end
    def cond?; !(@cond.nil? || @cond == true) end

    def only_target?
      target? && !(actions? || type? || cond?)
    end

  end

end
