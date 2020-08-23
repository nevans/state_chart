# frozen_string_literal: true

require_relative "util"
require_relative "transition"

module StateChart

  # chooses the first matching transition from a Hash.
  #
  # Each {Transition#event} must match hash key.
  class TransitionsList

    def initialize(*transitions)
      @immediate = []
      @list = []
      transitions.each do |t| add(t) end
    end

    include Enumerable

    def each
      return to_enum unless block_given?
      @immediate.each do |t| yield t end
      @list.each do |t| yield t end
      nil
    end

    # enumerates over the transitions that match this event name (ignoring cond)
    #
    # In {https://www.w3.org/TR/scxml/#AlgorithmforSCXMLInterpretation SCXML},
    # this would be a piece of +selectTransitions(event)+ function.  This part
    # ignores the condition predicate, however it can be trivially cached.
    #
    # @todo cache for each recognized_event, perhaps at the {State} node
    def matching_event_name(event_name)
      return to_enum(__method__, event_name) unless block_given?
      if Events::IMMEDIATES.include?(event_name)
        @immediate
      else
        @list.select{|t| t.matches_event_name?(event_name)}
      end
        .each do |t| yield t end
      nil
    end

    # @param event   [Event]
    # @param context [ExecutionContext]
    #
    # @return [Transition,nil] the matching transition, if it exists
    def matching(event, context)
      matching_event_name(event.name).find {|t|
        context.matches?(t.cond)
      }
    end

    def recognized_delays
      inject(Hash.new) do |events, t|
        events[t.delay] ||= t.event if t.delay?
        events
      end
    end

    def recognized_events
      inject(Set.new) do |events, t|
        events += t.events
      end
    end

    def empty?
      @immediate.empty? && @list.empty?
    end

    # @todo handle during object construction
    def <<(transition)
      case transition
      when Enumerable
        transition.each do |t| self << t end
      when Transition
        add(transition)
      else
        raise ArgumentError, "cannot add transition %p" % [transition]
      end
      self
    end

    # deep freeze the data structure
    #
    # @todo create cache of type: {recognized_event_name => Array<Transition>}
    def freeze
      @immediate.each(&:freeze)
      @list.each(&:freeze)
      @immediate.freeze
      @list.freeze
      super
    end

    def resolve_references!(source_state)
      @immediate&.each do |t| t.resolve_references!(self) end
      @list&.each do |t| t.resolve_references!(self) end
    end

    private

    def add(t)
      raise ArgumentError, "not a #{Transition}" unless t.is_a?(Transition)
      (t.immediate? ? @immediate : @list) << t
    end

    NULL_SET = new.freeze

  end

end
