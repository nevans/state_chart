# frozen_string_literal: true

require "state_chart"
require_relative "visitor"

begin
  require "ox"
rescue LoadError
  $stderr.puts "StateChart's SCXML support requires the 'ox' gem."
  raise
end

module StateChart

  # This gem is roughly based on SCXML, and so we will try to maintain loosely
  # compatible, in order to take advantage of tooling in the SCXML ecosystem.
  module SCXML

    class Exporter < Visitor

      XMLNS = "http://www.w3.org/2005/07/scxml"
      VERSION = "1.0"
      DATAMODEL = "ruby_state_chart"

      SCXML_ATTRS = {
        xmlns: XMLNS,
        version: VERSION,
        datamodel: DATAMODEL,
      }.freeze

      attr_reader :doc

      def initialize(doc = Ox::Document.new)
        super()
        @doc = doc
        @ctx = doc
        @doc << Ox::Instruct.new(:xml).tap do |xml|
          xml[:version] = "1.0"
          xml[:encoding] = "UTF-8"
        end
      end

      def visit_StateChart_Chart(node, **opts)
        with_element("scxml", **SCXML_ATTRS) do |scxml|
          scxml[:name]    = node.name                         if node.name
          scxml[:initial] = node.initial.target_ids.join(" ") if node.initial
          node.states.each do |_, state| visit(state) end
        end
      end

      def visit_StateChart_State(node, type: "state", **opts)
        with_element(type, id: node.id) do |elem|
          if node.respond_to?(:states)
            node.states.each do |_, child| visit(child) end
          end
          if node.respond_to?(:transitions)
            visit_after_transitions(node.after)
            node.transitions.each do |child| visit(child) end
          end
        end
      end

      def visit_StateChart_Transition(node, **opts)
        with_element("transition") do |elem|
          # attributes
          elem[:event] = node.event
          elem[:target] = node.target_ids.join(" ") if node.target?
          elem[:cond] = node.cond if node.cond?
          # children
          # TODO
        end
      end

      # TODO: perform this transform *inside* the chart
      def visit_after_transitions(after)
        return if after.empty?
        with_element("onentry") do
          after.recognized_delays.each do |d, event|
            with_element("send") do
              @ctx[:id]    = event
              @ctx[:event] = event
              @ctx[:delay] = "#{d}s"
            end
          end
        end
        with_element("onexit") do
          after.recognized_delays.each do |_, event|
            with_element("cancel") do
              @ctx[:sendid] = event
            end
          end
        end
        after.each do |child| visit(child) end
      end

      def visit_itself(node, **kw)
        node
      end

      alias visit_String   visit_itself
      alias visit_NilClass visit_itself

      def with_element(type, **attrs)
        @ctx << Ox::Element.new(type).tap do |elem|
          orig_ctx, @ctx = @ctx, elem
          attrs.each do |k,v|
            elem[k] = v
          end
          yield elem
        ensure
          @ctx = orig_ctx
        end
      end

      def dump
        Ox.dump(doc)
      end

      module Visitable
        def to_scxml(**opts)
          exporter = Exporter.new
          exporter.visit(self, **opts)
          exporter.dump
        end
      end

    end

    Chart.class_eval do
      include Exporter::Visitable
    end

  end
end
