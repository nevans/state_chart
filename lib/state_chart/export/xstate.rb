# frozen_string_literal: true

require_relative "../state_node"

module StateChart

  module Export

    # In order to take advantage of tooling in the robust xstate ecosystem,
    # we'll attempt to support import and export of XState machine configs and
    # state.
    module XState

      module Visitable
        def to_xstate_config(**opts)
          XState.visit(self, **opts)
        end
      end

      StateNode.class_eval do
        include Visitable
      end

      module_function

      def visit(node, **opts)
        case node
        when Hash;        visit_hash(node,        **opts)
        when Array;       visit_array(node,       **opts)
        when StateNode;   visit_state_node(node,  **opts)
        when Transitions; visit_transitions(node, **opts)
        when Transition;  visit_transition(node,  **opts)
        else              node
        end
      end

      def visit_hash(node, **opts)
        node.transform_values {|val| visit(val, **opts) }
      end

      def visit_array(array, **opts)
        visited = array.map {|val| visit(val, **opts) }
        visited.length > 1 ? visited : visited.first
      end

      def visit_state_node(node, **opts)
        h = case node
        when StateNode::Final;    {type: :final}
        when StateNode::Parallel; {type: :parallel}
        when StateNode::History;  {type: :history, history: node.history_type}
        else                      {}
        end
        visit_node_attr(node, h, :meta, :meta_data)
        if node.is_a?(StateNode::HasStateId) && node.generated_id?
          visit_node_attr(node, h, :id)
        end
        if node.is_a? StateNode::HasInitialState
          visit_node_attr(node, h, :initial)
        end
        if node.is_a? StateNode::HasActions
          visit_node_attr(node, h, :onEntry, :on_entry)
          visit_node_attr(node, h, :onExit,  :on_entry)
        end
        if node.is_a? StateNode::HasChildren
          visit_node_attr(node, h, :states)
        end
        if node.is_a? StateNode::HasDoneData
          visit_node_attr(node, h, :data,    :done_data)
        end
        if node.is_a? StateNode::HasTransitions
          visit_node_attr(node, h, :on,      :transitions)
          visit_node_attr(node, h, :after)
        end
        h
      end

      def visit_node_attr(node, hash, hash_key, node_key = hash_key)
        val = node.send(node_key)
        val = visit(val)
        val &&= nil if val.respond_to?(:empty?) && val.empty?
        val &&= nil if val.respond_to?(:blank?) && val.blank?
        hash[hash_key] = val unless val.nil?
        hash
      end

      def visit_transitions(transitions, **)
        h = transitions.each.with_object({}) do |(key, t), h|
          h[key] ||= []
          h[key] << visit(t)
        end
        h.transform_values {|v| v.length == 1 ? v.first : v }
      end

      def visit_transition(t, include_event: false, **)
        return t.target if t.only_target?
        h = {}
        visit_node_attr(t, h, :event)  if include_event
        visit_node_attr(t, h, :target)
        visit_node_attr(t, h, :cond)   if t.cond?
        visit_node_attr(t, h, :type)   if t.type?
        visit_node_attr(t, h, :actions)
        h[:actions] = [] if h.empty? # "forbidden" transition
        h
      end

    end

  end

end
