# frozen_string_literal: true

require "spec_helper"

module StateChart

  RSpec.describe Transition do

    describe "#event, #events, and #immediate?" do

      describe "immediate events" do
        it "must have an explicit event value" do
          expect { Transition.new }.to raise_error ArgumentError
        end

        immediate_examples = {
          "the Events::IMMEDIATE constant" => Events::IMMEDIATE,
          "an explict nil"  => nil,
          "an empty string" => "",
          "an empty array"  => [],
        }

        immediate_examples.each do |name, val|
          it "can be created with #{name}" do
            t = Transition.new(val)
            expect(t).to be_immediate
            expect(t.event).to eq(Events::IMMEDIATE)
            expect(t.events).to eq([]) # special case!
          end
        end

      end

      string_event_example_groups = {
        "single 'token' event string" => %w[foo error EVENT tOgGlE],
        "multi 'token' event string" => %w[
          foo.bar foo.bar.baz error.send.failed error.communication.script
        ],
        "single token event symbol (converted to_s)" => %i[foo error EVENT bLaH]
      }

      string_event_example_groups.each do |type, names|
        describe "can be given a #{type}," do
          names.each do |name|
            specify "e.g. %p" % name do
              t = Transition.new(name)
              expect(t).to_not be_immediate
              expect(t.event).to eq(name.to_s)
              expect(t.events).to eq([name.to_s])
            end
          end
        end
      end

      describe "multiple events" do

        it "can be given a space delimited list of events" do
          str = "bar errors.communication.script foo" # n.b. alpha-sorted
          t = Transition.new(str)
          expect(t).to_not be_immediate
          expect(t.event).to eq(str)
          expect(t.events).to match_array(
            %w[foo bar errors.communication.script]
          )
        end

        it "can be given an array of events" do
          array = %w[foo bar errors.communication.script]
          t = Transition.new(array)
          expect(t).to_not be_immediate
          expect(t.event).to eq("bar errors.communication.script foo")
          expect(t.events).to match_array(array)
        end

      end

    end

    describe "#target" do
      specify "???"
    end

    describe "#cond" do
      specify "???"
    end

    describe "#internal?" do
      specify "???"
    end

    describe "#wildcard?" do
      specify "???"
    end

    describe "#external? and #internal?", aggregate_failures: true do
      it "is external by default" do
        transition = Transition.new("event")
        expect(transition).to     be_external
        expect(transition).to_not be_internal
        expect(transition.type).to eq(:external)
      end

      it "is external when type is set to :external" do
        transition = Transition.new("event", type: :external)
        expect(Transition.new("event", type: :external)).to     be_external
        expect(Transition.new("event", type: :external)).to_not be_internal
        expect(transition.type).to eq(:external)
      end

      it "is internal when type is set to :internal" do
        transition = Transition.new("event", type: :internal)
        expect(Transition.new("event", type: :internal)).to_not be_external
        expect(Transition.new("event", type: :internal)).to     be_internal
        expect(transition.type).to eq(:internal)
      end

    end
  end

end
