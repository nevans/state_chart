# frozen_string_literal: true

require "spec_helper"
require "state_chart/xstate"
require "state_chart/scxml"

module StateChart

  RSpec.describe Builder do

    # generics

    let(:exported_xstate_config) { chart.to_xstate_config }
    let(:exported_scxml) { chart.to_scxml }

    # specific machines...

    let(:toggle_chart) {
      StateChart.chart :toggle do
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
        <?xml version="1.0" encoding="UTF-8"?>
        <scxml xmlns="http://www.w3.org/2005/07/scxml" version="1.0" datamodel="ruby_state_chart" name="toggle" initial="toggle.inactive">
          <state id="toggle.inactive">
            <transition event="TOGGLE" target="toggle.active"/>
          </state>
          <state id="toggle.active">
            <transition event="TOGGLE" target="toggle.inactive"/>
          </state>
        </scxml>
      XML
    end

    describe "building a simple compound state node from basic block syntax" do

      let(:chart) { toggle_chart }
      let(:xstate_config) { toggle_xstate_config }
      let(:scxml_document) { toggle_scxml }

      it "generates xstate config hash from builder block" do
        expect(exported_xstate_config).to eq(xstate_config)
      end

      it "generates SCXML from builder block" do
        expect(exported_scxml).to eq(scxml_document)
      end

      it "creates a #{Chart} with a name" do
        expect(chart).to be_a_kind_of(Chart)
        expect(chart.name).to eq("toggle")
      end

      it "creates two child states" do
        expect(chart.states.length).to eq(2)
        inactive = chart.states.fetch(:inactive)
        active   = chart.states.fetch(:active)
        expect(inactive).to be_a_kind_of(State::Atomic)
        expect(active).to be_a_kind_of(State::Atomic)
        expect(chart.initial_state).to equal(inactive)
      end

    end

    let(:traffic_light_chart) {
      StateChart.chart :traffic_light do
        initial "green"
        state :green do
          after 30, "yellow"
        end
        state :yellow do
          after 5, [{ target: 'red' }]
        end
        state :red do
          after 25, [
            { target: 'yellow', if: "warning" },
            { target: 'green',  if: "crosswalk_ready" },
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
            after: { 30_000 => 'yellow' }
          },
          "yellow" => {
            after: { 5_000 => 'red' }
          },
          "red" => {
            after: {
              25_000 => [
                { target: 'yellow', cond: 'warning' },
                { target: 'green',  cond: 'crosswalk_ready' },
              ],
            }
          }
        }
      }
    }

    let(:traffic_light_scxml) do
      <<~XML
        <?xml version="1.0" encoding="UTF-8"?>
        <scxml xmlns="http://www.w3.org/2005/07/scxml" version="1.0" datamodel="ruby_state_chart" name="traffic_light" initial="traffic_light.green">
          <state id="traffic_light.green">
            <onentry>
              <send id="__internal__.delay.after_30" event="__internal__.delay.after_30" delay="30s"/>
            </onentry>
            <onexit>
              <cancel sendid="__internal__.delay.after_30"/>
            </onexit>
            <transition event="__internal__.delay.after_30" target="traffic_light.yellow"/>
          </state>
          <state id="traffic_light.yellow">
            <onentry>
              <send id="__internal__.delay.after_5" event="__internal__.delay.after_5" delay="5s"/>
            </onentry>
            <onexit>
              <cancel sendid="__internal__.delay.after_5"/>
            </onexit>
            <transition event="__internal__.delay.after_5" target="traffic_light.red"/>
          </state>
          <state id="traffic_light.red">
            <onentry>
              <send id="__internal__.delay.after_25" event="__internal__.delay.after_25" delay="25s"/>
            </onentry>
            <onexit>
              <cancel sendid="__internal__.delay.after_25"/>
            </onexit>
            <transition event="__internal__.delay.after_25" target="traffic_light.yellow" cond="warning"/>
            <transition event="__internal__.delay.after_25" target="traffic_light.green" cond="crosswalk_ready"/>
          </state>
        </scxml>
      XML
    end

    describe "building with 'after' delays" do

      let(:chart) { traffic_light_chart }
      let(:xstate_config) { traffic_light_xstate_config }
      let(:scxml_document) { traffic_light_scxml }

      it "generates config hash from builder block" do
        expect(exported_xstate_config).to eq(xstate_config)
      end

      it "generates SCXML from builder block" do
        expect(exported_scxml).to eq(scxml_document)
      end

    end

    # adapted from xstate's machine.test.ts

    let(:pedestrian_definition) {
      proc do
        initial :walk
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

    let(:nested_light_chart) {
      spec = self # because the block below will be instance_exec'd
      StateChart.chart :nested_light, initial: :green do
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
        state :red do
          instance_exec(&spec.pedestrian_definition)
          on TIMER: 'green'
          on POWER_OUTAGE: 'red'
        end
      end
    }

    # n.b. see the note on Export::XState#visit_transitions
    let(:nested_light_xstate_config) {
      {
        id: 'nested_light',
        initial: 'green',
        states: {
          "green" => {
            on: [
              { "TIMER" => 'yellow' },
              { "POWER_OUTAGE" => 'red' },
              { "FORBIDDEN_EVENT" => { actions: [] } },
            ],
          },
          "yellow" => {
            on: [
              { "TIMER" => 'red' },
              { "POWER_OUTAGE" => 'red' },
            ],
          },
          "red" => pedestrian_xstate_config.merge({
            on: [
              { "TIMER" => 'green' },
              { "POWER_OUTAGE" => 'red' },
            ],
          })
        }
      }
    }

    describe "building with nested and merged/included states" do

      let(:chart) { nested_light_chart }
      let(:xstate_config) { nested_light_xstate_config }

      it "generates config hash from builder block" do
        expect(exported_xstate_config).to eq(xstate_config)
      end

    end

    # adapted from xstate's machine.test.ts

    let(:config_chart) {
      StateChart.chart :config do
        initial :alpha

        # Having an identical attribute name and state name can cause issues
        # with SCXML export.  However, the state ID isn't explicit, so we are
        # free to generate a different one. e.g. namespaced like +"S:#{path}"+.
        attribute :foo, default: "bar"

        state :alpha do
          attribute :baz, default: "quux"
          on_entry "entryAction"
          on EVENT: "omega", if: "someCondition"
        end

        final :omega

      end
    }

    let(:config_xstate_schema) {
      {
        id: "config",
        initial: "alpha",
        context: {
          foo: "bar",
          baz: "quux", # xstate export hoists all attributes to the top
        },
        states: {
          "alpha" => {
            onEntry: "entryAction",
            on: {
              "EVENT" => {
                target: "omega",
                cond: "someCondition"
              }
            }
          },
          "omega" => {type: :final}
        }
      }
    }

    describe "building with data_model" do

      let(:chart) { config_chart }
      let(:xstate_config) { config_xstate_schema }

      it "generates config hash from builder block" do
        expect(exported_xstate_config).to eq(xstate_config)
      end

      it "lists all attributes on the chart" do

      end

    end

    describe "building with deeply nested and parallel nodes" do

      let(:parallel_traffic_lights_proc) do
        proc do
          initial :green
          state :green do
            on TIMER: "yellow"
          end
          state :yellow do
            on TIMER: 'red'
          end
          parallel :red do
            state :walkSign do
              initial :solid
              state :solid do
                on COUNTDOWN: 'flashing'
              end
              state :flashing do
                on STOP_COUNTDOWN: 'solid'
              end
            end
            state :pedestrian do
              initial :walk
              state :walk do
                on COUNTDOWN: 'wait'
              end
              wait do
                on STOP_COUNTDOWN: 'stop'
              end
              final :stop
            end
          end
        end
      end

      let(:parallel_traffic_lights_xstate_schema) do
        {
          id: 'light',
          initial: 'green',
          states: {
            green: {
              on: { TIMER: 'yellow' }
            },
            yellow: {
              on: { TIMER: 'red' }
            },
            red: {
              type: 'parallel',
              states: {
                walkSign: {
                  initial: 'solid',
                  states: {
                    solid: {
                      on: { COUNTDOWN: 'flashing' }
                    },
                    flashing: {
                      on: { STOP_COUNTDOWN: 'solid' }
                    }
                  }
                },
                pedestrian: {
                  initial: 'walk',
                  states: {
                    walk: {
                      on: { COUNTDOWN: 'wait' }
                    },
                    wait: {
                      on: { STOP_COUNTDOWN: 'stop' }
                    },
                    stop: {
                      type: 'final'
                    }
                  }
                }
              }
            }
          }
        }
      end

    end

  end

end
