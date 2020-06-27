# frozen_string_literal: true

module StateChart

  # @abstract
  class StateNode

    module HasStateId

      # Identifier which must be unique within the entire StateChart
      #
      # @return [String,Symbol]
      attr_reader :id

      # Identifier which must be unique among all siblings.
      #
      # @return [String,Symbol]
      attr_reader :name

      # return [nil, Compound, Parallel]
      attr_reader :parent

      def initialize(name, parent: nil, id: nil)
        super() # in case there are e.g. mutexes
        @id   = id # ensure this ivar sorts first in inspect...
        @name = validate_name_format!("name", name)
        @parent = parent
        @id   = validate_name_format!("id", id || generated_id)
        # TODO: verify globally unique ID
      end

      def generated_id?
        !parent || id != generated_id
      end

      # use double underscore for generated IDs.
      # "period" is used for searching via key path
      def generated_id
        parent ? "#{parent.id}__#{name}" : name
      end

    end
  end
end
