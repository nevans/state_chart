# frozen_string_literal: true

require_relative "errors"

module StateChart

  module Util

    VALID_NAME = /[A-Za-z][A-Za-z0-9_:.-]*/

    UNDEFINED = Object.new
    private_constant :UNDEFINED

    class << UNDEFINED
      def to_s; "#{Util}::UNDEFINED" end
      alias inspect to_s
    end
    UNDEFINED.freeze

    module_function

    def validate_initial_transition!(transition, name: "initial")
      # valid local target is verified during finalize
      raise "must set target on #{name} transition" unless transition.target
      raise "must not set cond on #{name} transition"  if transition.cond?
      raise "must not set event on #{name} transition" if transition.event?
    end

    def validate_transition_event(event)
      return Transition::IMMEDIATE if event.nil?
      if event == Transition::IMMEDIATE || event == Transition::WILDCARD
        event
      else
        validate_name_format!("transition event", event)
      end
    end

    def validate_cond_format(cond)
      return true if cond.nil? || cond == true
      validate_name_format!("cond", cond)
    end

    def validate_name_format!(attr, val, nullable: false)
      if val.nil? && nullable
        return
      elsif Symbol === val
        val = val.to_s
      elsif val.respond_to?(:to_str)
        val = val.to_str
      else
        raise InvalidName, "invalid %s, no conversion to string: %p" % [attr, val]
      end
      if VALID_NAME.match?(val)
        val
      else
        raise InvalidName, "invalid %s: %p" % [attr, val]
      end
    end

    TRANSITION_TYPES = %i[internal external].freeze

    def validate_transition_type(type)
      return nil if type.nil?
      validate_transition_type!(type)
    end

    def validate_transition_type!(type)
      if String === type
        type = type.to_sym
      end
      unless type && TYPES.include?(type)
        raise ArgumentError, "invalid type %p" % [type]
      end
      type
    end

  end
end
