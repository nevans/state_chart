# frozen_string_literal: true

require_relative "errors"
require_relative "util"
require_relative "util/id_map"
require_relative "nodes"
require_relative "attrs"

require_relative "actions"
require_relative "data_model"

module StateChart

  # A {Chart} definition is a tree of {State} nodes, each of which may contain:
  #
  # * child {State} nodes (doubly-linked back to their parent)
  # * {Action}s that execute on entry into or exit from the {State}
  # * {Transition}s to other {State}s on {Event}s, with their own {Action}s.
  # * a {DataModel} definition for "extended state" attributes.
  # * {Service} definitions, which describe triggers and actor-style
  #   communications with external services, including other {Machine}s.
  #
  # The {Chart} itself is the root node of the {State} tree, and contains
  # meta-data pertinent to the whole tree, such as an id lookup hash.
  #
  # A {Chart} may contain an incomplete {ExecutionContext}, if it doesn't have
  # definitions for all of the conditions, attr_readers, attr_writers, scripts,
  # actividies, and services that have been referenced.  In that case, it should
  # be merged with more {ExecutionContext} objects until all referenced proc
  # names have definitions. This allows a base {Chart} definition to be combined
  # with different {ExecutionContext} implementations.
  #
  # Because {State} nodes are doubly-linked back to their parents, {State#dup}
  # (and thus {Chart#dup}) must deep copy all nodes in the tree.
  class Chart < Nodes::Node

    include Nodes::ParentNode
    include Attrs::InitialState
    include Attrs::DataModel

    def initialize_attrs(name: nil, **attrs, &block)
      super
      @id_map  = Util::IDMap.new(self)
      @name    = validate_name_format(name, nullable: true) || "unnamed_chart"
    end

    # @return [String] an (optional) chart identifier
    attr_reader :name

    # @return [Hash{Symbol=>Nodes::Identifiable}]
    attr_reader :id_map

    def path
      Util::EMPTY
    end

    # @return [self] this chart
    def chart
      self
    end

    def parent
      nil
    end

    def freeze
      @id_map.freeze
      super
    end

    # Look up chart nodes by ID
    #
    # @param id [String,Symbol] the object's id, unique within this {Chart}
    # @return [State,Send,Invoke] the chart value matching the ID
    def [](id) @id_map[id] end

    # @return [State,Send,Invoke] the chart value matching the ID
    def fetch(...) @id_map.fetch(...) end

    def state_ids; @id_map.state_ids end

    def all_states; id_map.states end
    def all_attributes; id_map.attributes end

    private

    def initialize_done
      super
      resolve_references!
      freeze
    end

    def inspect_attrs
      super + [
        name,
        "(%d top-level states)" % [states.count]
      ]
    end

  end

end
