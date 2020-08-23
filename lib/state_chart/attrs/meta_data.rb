# frozen_string_literal: true

module StateChart
  module Attrs

    # @todo
    module MetaData

      # @return [Hash{Symbol => Object}] node metadata, in a key-value lookup
      def meta_data
        if defined?(@meta_data)
          @meta_data
        elsif frozen?
          Util::EMPTY_HASH
        else
          @meta_data = {}
        end
      end

      def freeze
        @meta_data&.freeze
        super
      end
    end

  end
end
