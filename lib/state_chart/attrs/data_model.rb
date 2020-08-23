# frozen_string_literal: true

require_relative "../data_model/attribute_set"

module StateChart

  module Attrs
    module DataModel

      Collection = ::StateChart::DataModel::AttributeSet

      def attributes
        if defined?(@attributes)
          @attributes
        elsif frozen?
          Collection::NULL_SET
        else
          @attributes = Collection.new
        end
      end

      def freeze
        @attributes&.freeze
        super
      end

    end

  end
end
