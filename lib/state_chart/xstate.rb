# frozen_string_literal: true

require "state_chart"
require_relative "visitor"

module StateChart

  # In order to take advantage of tooling in the robust xstate ecosystem,
  # we'll attempt to support import and export of XState machine configs and
  # state.
  module XState

    class Exporter < Visitor

      TRANS_KEYS = %i[event delay]

      def visit_StateChart_Chart(node, h: {}, **opts)
        visit_node_attr(node, h, :id, :name)
        visit_node_attr(node, h, :initial)
        visit_node_attr(node, h, :context, :all_attributes)
        visit_node_attr(node, h, :states)
      end

      def visit_StateChart_State_Parallel(node, h: {}, **opts)
        h = h.merge type: :parallel
        visit_StateChart_State(node, h: h, **opts)
      end

      def visit_StateChart_State_Final(node, h: {}, **opts)
        h = h.merge type: :final
        visit_StateChart_State(node, h: h, **opts)
      end

      def visit_StateChart_State_History(node, h: {}, **opts)
        h = h.merge type: :history, history: node.history_type
        visit_StateChart_State(node, h: h, **opts)
      end

      def visit_StateChart_State(node, h: {}, **opts)
        visit_node_attr(node, h, :id) unless node.generated_id?
        visit_node_attr(node, h, :meta, :meta_data)
        if node.respond_to? :initial
          visit_node_attr(node, h, :initial)
        end
        if node.respond_to?(:on_entry)
          visit_node_attr(node, h, :onEntry, :on_entry)
          visit_node_attr(node, h, :onExit,  :on_exit)
          visit_node_attr(node, h, :invoke,  :services)
        end
        if node.respond_to?(:states)
          visit_node_attr(node, h, :states)
        end
        if node.respond_to?(:done_data)
          visit_node_attr(node, h, :data, :done_data)
        end
        if node.respond_to?(:transitions)
          visit_node_attr(node, h, :on,    :transitions)
          visit_node_attr(node, h, :after, :after, with_key: :delay)
        end
        h
      end

      # create an array of hashes of arrays, but simplified when single-valued.
      #
      # we're not going to rely on preserved ordering of keys within the hash,
      # so each hash will have only a single key.  That may result in a slightly
      # more verbose version that is necessary for xstate. But it should be
      # semantically equivalent, and it simplified this code.
      def visit_StateChart_TransitionsList(transitions, with_key: :event, **)
        raise ArgumentError unless TRANS_KEYS.include?(with_key)
        result = transitions.each.inject(nil) do |acc, t|
          key = with_key == :event ? t.event : t.delay * 1000
          val = visit(t, with_key: with_key)
          case acc
          when nil
            {key => val}
          when Hash
            if acc.key?(key)
              visit_transitions_append_hash(acc, key, val)
            else
              [acc, {key => val}]
            end
          when Array
            last = acc.last
            if last.key?(key)
              visit_transitions_append_hash(last, key, val)
              acc
            else
              acc << {key => val}
            end
          end
        end
        result
      end

      def visit_StateChart_Transition(t, with_key: :event, **)
        raise ArgumentError unless TRANS_KEYS.include?(with_key)
        return t.target if t.only_target?
        h = {}
        if with_key == :event
          visit_node_attr(t, h, :delay) {|d| d * 1000 } if t.delay?
        else
          visit_node_attr(t, h, :event) unless t.delay?
        end
        visit_node_attr(t, h, :target)
        visit_node_attr(t, h, :cond)   if t.cond?
        visit_node_attr(t, h, :type)   if t.type?
        visit_node_attr(t, h, :actions)
        h[:actions] = [] if h.empty? # "forbidden" transition
        h
      end

      def visit_StateChart_DataModel_Attribute(attr)
        attr.default
      end

      def visit_node_attr(node, hash, hash_key, node_key = hash_key, **opts)
        val = node.send(node_key)
        val = visit(val, **opts)
        val &&= nil if val.respond_to?(:empty?) && val.empty?
        val &&= nil if val.respond_to?(:blank?) && val.blank?
        val &&= yield val if block_given?
        hash[hash_key] = val unless val.nil?
        hash
      end

      def visit_transitions_append_hash(acc, key, val)
        acc[key] = [acc[key]] unless acc[key].is_a?(Array)
        acc[key] << val
        acc
      end

      def visit_itself(node, **kw)
        node
      end

      alias visit_String   visit_itself
      alias visit_NilClass visit_itself

      def visit_Array(array, **opts)
        visited = array.map {|val| visit(val, **opts) }
        visited.length > 1 ? visited : visited.first
      end

      def visit_Hash(node, **opts)
        node.transform_values {|val| visit(val, **opts) }
      end

      alias visit_StateChart_Nodes_StateCollection visit_Hash
      alias visit_StateChart_Util_OrderedMap visit_Hash

      module Visitable
        def to_xstate_config(**opts)
          Exporter.new.visit(self, **opts)
        end
      end

    end

    Chart.class_eval do
      include Exporter::Visitable
    end

  end
end
