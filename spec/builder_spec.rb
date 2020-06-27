# frozen_string_literal: true

require "spec_helper"
require "state_chart/export/xstate"

module StateChart

  RSpec.describe Builder do

    # generics

    subject(:builder) { Builder::States }

    let(:definition_name) { :untitled }
    let(:definition_opts) { {} }
    let(:definition) {
      builder.build!(definition_name, **definition_opts, &definition_proc)
    }
    let(:exported_xstate_config) { definition.to_xstate_config }

    # specific machines...

    let(:toggle_proc) {
      proc do
        initial :inactive
        state :inactive do
          on TOGGLE: :active
        end
        state :active do
          on TOGGLE: :inactive
        end
      end
    }

    let(:toggle_xstate_config) do
      {
        id: "toggle",
        initial: "inactive",
        states: {
          "inactive" => {
            on: {
              "TOGGLE" => "active",
            },
          },
          "active" => {
            on: {
              "TOGGLE" => "inactive",
            },
          }
        }
      }
    end

    let(:toggle_scxml) do
      <<~XML
        <?xml version="1.0" encoding="utf-8"?>
        <scxml xmlns="http://www.w3.org/2005/07/scxml" xmlns:xi="http://www.w3.org/2001/XInclude" version="1.0" initial="inactive" datamodel="ruby">
          <state id="toggle__inactive">
            <transition event="TOGGLE" target="toggle__active"/>
          </state>
          <state id="toggle__active">
            <transition event="TOGGLE" target="toggle__inactive"/>
          </state>
        </scxml>
      XML
    end

    describe "building a simple compound state node from basic block syntax" do

      let(:definition_name) { :toggle }
      let(:definition_proc) { toggle_proc }
      let(:xstate_config) { toggle_xstate_config }

      it "generates config hash from builder block" do
        expect(exported_xstate_config).to eq(xstate_config)
      end

      it "creates a #{StateNode} with an ID" do
        expect(definition).to be_a_kind_of(StateNode)
        expect(definition.id).to eq("toggle")
      end

      it "creates no transitions for the root node" do
        expect(definition.transitions).to be_empty
      end

      it "creates two states on a #{StateNode::Compound} root node" do
        expect(definition).to be_a_kind_of(StateNode::Compound)
        expect(definition.states.length).to eq(2)
        inactive = definition.states.fetch(:inactive)
        active   = definition.states.fetch(:active)
        expect(inactive).to be_a_kind_of(StateNode::Atomic)
        expect(active).to be_a_kind_of(StateNode::Atomic)
        expect(definition.initial_state_node).to equal(inactive)
        expect(inactive).to be_initial
      end

    end

    let(:traffic_light_builder) { Builder::States.new("traffic_light") }

    let(:traffic_light_build_proc) {
      proc do
        initial "green"
        state :green do
          after 1000, "yellow"
        end
        state :yellow do
          after 1000, [{ target: 'red' }]
        end
        state :red do
          after 1000, [
            { target: 'yellow', cond: "warning" },
            { target: 'green',  cond: "crosswalk_ready" },
          ]
        end
      end
    }

    let(:traffic_light_xstate_config) {
      {
        id: 'traffic_light',
        initial: 'green',
        states: {
          "green" => {
            after: { 1000 => 'yellow' }
          },
          "yellow" => {
            after: { 1000 => 'red' }
          },
          "red" => {
            after: {
              1000 => [
                { target: 'yellow', cond: 'warning' },
                { target: 'green',  cond: 'crosswalk_ready' },
              ],
            }
          }
        }
      }
    }

    describe "building with 'after' delays" do

      let(:definition_name) { :traffic_light }
      let(:definition_proc) { traffic_light_build_proc }
      let(:xstate_config) { traffic_light_xstate_config }

      it "generates config hash from builder block" do
        expect(exported_xstate_config).to eq(xstate_config)
      end

    end

    # adapted from xstate's machine.test.ts

    let(:pedestrian_definition) {
      Builder::States.build!("pedestrian", initial: :walk) do
        state :walk do
          on PED_COUNTDOWN: 'wait'
        end
        state :wait do
          on PED_COUNTDOWN: 'stop'
        end
        state :stop
      end
    }

    let(:pedestrian_xstate_config) {
      {
        initial: 'walk',
        states: {
          "walk" => { on: { "PED_COUNTDOWN" => 'wait' } },
          "wait" => { on: { "PED_COUNTDOWN" => 'stop' } },
          "stop" => {}
        }
      };
    }

    let(:nested_light_opts) { { initial: :green } }
    let(:nested_light_proc) {
      proc do
        state :green do
          on(
            TIMER: 'yellow',
            POWER_OUTAGE: 'red',
            FORBIDDEN_EVENT: nil,
          )
        end
        state :yellow do
          on TIMER: 'red'
          on POWER_OUTAGE: 'red'
        end
        states :red do
          include_definition pedestrian_definition
          on TIMER: 'green'
          on POWER_OUTAGE: 'red'
        end
      end
    }

    let(:nested_light_xstate_config) {
      {
        id: 'nested_light',
        initial: 'green',
        states: {
          "green" => {
            on: {
              "TIMER" => 'yellow',
              "POWER_OUTAGE" => 'red',
              "FORBIDDEN_EVENT" => { actions: [] },
            }
          },
          "yellow" => {
            on: {
              "TIMER" => 'red',
              "POWER_OUTAGE" => 'red'
            }
          },
          "red" => pedestrian_xstate_config.merge({
            on: {
              "TIMER" => 'green',
              "POWER_OUTAGE" => 'red'
            },
          })
        }
      }
    }

    describe "building with nested and merged/included states" do

      let(:definition_name) { :nested_light }
      let(:definition_opts) { nested_light_opts }
      let(:definition_proc) { nested_light_proc }
      let(:xstate_config)   { nested_light_xstate_config }

      it "generates config hash from builder block" do
        expect(exported_xstate_config).to eq(xstate_config)
      end

    end

  end

end
