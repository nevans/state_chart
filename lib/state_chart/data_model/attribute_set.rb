# frozen_string_literal: true

require "forwardable"

require_relative "../util/ordered_map"
require_relative "attribute"

module StateChart

  module DataModel

    class AttributeSet < Util::OrderedMap

      NULL_SET = new.freeze

      alias names keys

      private

      def name_for(attr)
        unless attr.is_a?(Attribute)
          raise ArgumentError, "not an Attribute: %p" % [attr]
        end
        attr.name
      end

    end

  end
end
