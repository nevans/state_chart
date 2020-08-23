# frozen_string_literal: true

require_relative "../errors"
require_relative "../util"

require_relative "path_referable"

module StateChart

  module Nodes

    class Identifiable < PathReferable

      # Identifier which must be unique within the entire {Chart}.
      #
      # Can be any valid XML "Name".
      #
      # @return [String,Symbol]
      def id; @id || @generated_id end

      def generated_id?; !!@generated_id end

      private

      def initialize_attrs(*args, id: nil, **attrs, &block)
        super
        @id = validate_id_format(id) if id
        @generated_id = -"#{chart.name}.#{path.join('.')}" unless id
      end

      def inspect_attrs
        generated_id? ? super : super + ["id=#{id}"]
      end

      # uniqueness should be handled elsewhere.
      def validate_id_format(id)
        if Util::Regex::XML::ID.match?(id)
          -id.to_s
        else
          raise InvalidName, "invalid ID: %p" % [id]
        end
      end

    end

  end

end
