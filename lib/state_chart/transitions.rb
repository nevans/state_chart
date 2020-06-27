# frozen_string_literal: true

require_relative "util"
require_relative "transition"

module StateChart

  # chooses the first matching transition from a Hash.
  #
  # @todo support SCXML-style matching: token prefix and source ordering
  # use hash storage for caching/performance
  #
  # Each {Transition#event} must match hash key.
  class Transitions
    IMMEDIATE = Transition::IMMEDIATE
    WILDCARD  = Transition::WILDCARD

    def initialize
      @hash = {}
    end

    def [](event)
      name = Event.name(event)
      array = @hash[IMMEDIATE] if name.nil?
      array ||= @hash[name]
      array ||= @hash[WILDCARD]
      if array
        array.find {|transition| transition.matches?(event) }
      end
    end

    # @internal used to override event name matching hash lookup
    # useful e.g. for delayed "after" transitions
    def add(transition, key: nil)
      if Array === transition
        transition.map {|t| add(t, key: key) }
      else
        key ||= transition.event || IMMEDIATE
        @hash[key] ||= []
        @hash[key] << transition
        transition
      end
    end

    def <<(transition)
      add transition
      self
    end

    # deep freeze the data structure
    def freeze
      @hash.each {|_, array| array.freeze }
      @hash.freeze
      super
    end

    def empty?
      @hash.all? {|_, v| v.empty? }
    end

    def each
      return to_enum unless block_given?
      immediate.each do |t| yield IMMEDIATE, t end
      @hash.each do |key,ts|
        next if key == IMMEDIATE || key == WILDCARD
        ts.each do |t| yield key, t end
      end
      wildcard.each do |t| block.call WILDCARD, t end
      nil
    end

    EMPTY = [].freeze

    def immediate; @hash[IMMEDIATE] || EMPTY end
    def wildcard;  @hash[WILDCARD]  || EMPTY end

  end

end
