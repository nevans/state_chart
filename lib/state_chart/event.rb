# frozen_string_literal: true

module StateChart

  class Event

    def initialize(name, **payload)
      @name = Util.validate_event_name(name)
      @payload = payload
      freeze
    end

    attr_reader :name, :payload

    alias to_s name

    def initialize_copy(other)
      super
      @payload = @payload.transform_values {|val| val.clone }
    end

    def hash
      [@name, @payload].hash
    end

    def eql?(other)
      self.class == other.class &&
        name == other.name &&
        payload == other.payload
    end

    alias == eql?

  end

end

require_relative "events/delay"

require_relative "events/descriptors"
