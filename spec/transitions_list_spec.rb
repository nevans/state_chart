# frozen_string_literal: true

require "spec_helper"

module StateChart

  RSpec.describe TransitionsList do

    describe "creating a list of transitions" do

      describe "(e.g. the HighwayReport state, from SCXML G.1)" do

        # TODO: load this from SpecCharts.scxml_traffic_report
        subject(:transitions) {
          TransitionsList.new(
            Transition.new("highway",    target: "PlayHighway"),
            Transition.new("go_back",    target: "StartOver"),
            Transition.new("doOver",     target: "HighwayReport"),
            Transition.new("fullreport", target: "FullReport"),
            Transition.new("restart",    target: "Intro"),
          )
        }

        it "contains its transitions" do
          expect(transitions.count).to eq(5)
          expect(transitions.map {|t| [t.event, t.target]}.to_h).to eq(
            {
              "highway"    => "PlayHighway",
              "go_back"    => "StartOver",
              "doOver"     => "HighwayReport",
              "fullreport" => "FullReport",
              "restart"    => "Intro",
            }
          )
        end

        it "returns correct transitions per event name" do
          events = %w[highway go_back doOver fullreport restart]
          results = events.map {|e| transitions.matching_event_name(e) }
          results.each_with_index do |transition, i|
            expect(transition.to_a).to eq([transitions.to_a[i]])
          end
        end

        let(:context) { ExecutionContext.new }

        describe "#recognized_events" do
          it "returns all of the known events" do
            expect(transitions.recognized_events).to eq(
              Set.new(%w[highway go_back doOver fullreport restart])
            )
          end
        end

      end

    end

  end

end
