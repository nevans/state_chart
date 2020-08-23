# frozen_string_literal: true

require_relative "errors"
require_relative "util/regex"

module StateChart

  module Util

    # !@visibility private
    #
    # a special null object used to distinguish between args/kwargs that are
    # default vs user-specified nil. It should only be used internally, and
    # should probably only be used as an argument default and shouldn't be
    # allowed to escape the method it's declared in.
    UNDEFINED = Object.new.tap do |undefined|
      class << undefined
        def nil?;  true end

        def !; true end
        def &(obj) false end
        def ^(obj) obj ? true : false end
        def |(obj) obj ? true : false end

        def to_a; nil.to_a end
        def to_c; nil.to_c end
        def to_f; nil.to_f end
        def to_h; nil.to_h end
        def to_i; nil.to_i end
        def to_r; nil.to_r end
        def to_s; nil.to_s end

        def empty?;   true end
        def blank?;   true end
        def present?; false end

        def inspect; "#{Util}::UNDEFINED" end
      end
    end.freeze

    # !@visibility private
    # these could be very common, so avoid reallocating every time
    EMPTY = [].freeze

    # !@visibility private
    # these could be very common, so avoid reallocating every time
    EMPTY_HASH = {}.freeze

    module_function

    def validate_name_format(val, nullable: false)
      case val
      when Regex::VALID_NAME
        -val.to_s
      when nil
        raise InvalidName, "nil is not allowed" unless nullable
        nil
      else
        raise InvalidName, "invalid name: %p" % [val]
      end
    end

    def validate_event_name(event)
      case event
      when Util::Regex::SCXML::WILDCARD
        WILDCARD
      when Util::Regex::SCXML::EVENT_NAME
        -event.to_s
      when Util::Regex::SCXML::EVENT_NAME_WITH_WILD_SUFFIX
        -Regexp.last_match[:base]
      else
        raise InvalidName, "Invalid event name: %p" % event
      end
    end

  end
end
