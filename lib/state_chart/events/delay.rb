# frozen_string_literal: true

module StateChart

  module Events

    class Delay < Event

      def initialize(delay, **payload)
        @delay = validate_delay(delay)
        super(-"__internal__.delay.after_#{@delay}", **payload)
      end

      attr_reader :delay

      def hash
        [super, @delay].hash
      end

      def eql?(other)
        super && delay == other.delay
      end

      private

      def validate_delay(delay)
        case delay
        when Numeric; delay
        when Util::Regex::VALID_NAME; delay.to_sym
        else raise ArgumentError, "invalid delay"
        end
      end

    end

  end

end
