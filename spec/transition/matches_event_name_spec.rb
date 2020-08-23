# frozen_string_literal: true

require "spec_helper"

module StateChart

  RSpec.describe Transition do

    describe "#matches_event_name?(name)" do

      RSpec::Matchers.alias_matcher :match_event_name, :be_matches_event_name

      shared_examples "a non-immediate transition" do
        it "does not match the immediate pseudo event" do
          expect(transition).not_to match_event_name("")
          expect(transition).not_to match_event_name(nil)
        end
      end

      describe "with an immediate (nil or empty event) Transition" do
        subject(:transition) { Transition.new(Events::IMMEDIATE) }

        it "does not match any named event" do
          expect(transition).not_to match_event_name("foo")
          expect(transition).not_to match_event_name("foo.bar")
          expect(transition).not_to match_event_name("foo.bar.baz")
          expect(transition).not_to match_event_name("bar.baz")
          expect(transition).not_to match_event_name("foobar")
          expect(transition).not_to match_event_name("barfoo")
        end

        it "matches the immediate pseudo event name (empty or nil)" do
          expect(transition).to match_event_name("")
          expect(transition).to match_event_name(nil)
        end
      end

      describe "with a wildcard Transition" do
        subject(:transition) { Transition.new(Events::WILDCARD) }

        include_examples "a non-immediate transition"

        it "matches any and every named event" do
          expect(transition).to match_event_name("foo")
          expect(transition).to match_event_name("foo.bar")
          expect(transition).to match_event_name("foo.bar.baz")
          expect(transition).to match_event_name("bar.baz")
          expect(transition).to match_event_name("foobar")
          expect(transition).to match_event_name("barfoo")
        end
      end

      shared_examples "a transition that matches a single event name" do

        it "matches the exact same event name" do
          expect(transition).to match_event_name(event_name)
        end

        it "does not match completely different events" do
          rot13 = event_name.tr("a-zA-Z", "N-ZA-Mn-za-m")
          expect(transition).not_to match_event_name(rot13)
          expect(transition).not_to match_event_name("abc#{rand 9_999_999_999}")
          expect(transition).not_to match_event_name("abc#{rand 9_999_999_999}")
        end

        it "does not match by token prefix" do
          expect(transition).not_to match_event_name("#{event_name}abc")
          expect(transition).not_to match_event_name("#{event_name}s.blah")
        end

        it "does not match by token suffix" do
          expect(transition).not_to match_event_name("abc#{event_name}")
        end

        it "is case sensitive" do
          flipcase = event_name.tr("a-zA-Z", "A-Za-z")
          expect(transition).not_to match_event_name(flipcase)
        end

        it "does match by *exact* token prefix" do
          expect(transition).to match_event_name(event_name + ".subtoken")
          expect(transition).to match_event_name(event_name + ".my.king")
          expect(transition).to match_event_name(event_name + ".is.matched.ok")
        end

      end

      describe "matching a single simple event name (no '.')" do
        subject(:transition) { Transition.new(event_name) }

        simple_examples = %w[foo bar error EVENT Event]

        simple_examples.each do |event_name|
          describe "e.g. #{event_name.inspect}" do
            subject(:event_name) { event_name }
            include_examples "a non-immediate transition"
            include_examples "a transition that matches a single event name"
          end
        end

      end

      describe "matching on compound event names (containing '.')" do
        subject(:transition) { Transition.new(event_name) }

        simple_examples = %w[foo.bar error.hazmat Oh.hi.there.many.layers]

        simple_examples.each do |event_name|
          describe "e.g. #{event_name.inspect}" do
            subject(:event_name) { event_name }
            include_examples "a non-immediate transition"
            include_examples "a transition that matches a single event name"

            tokens = event_name.split(".")
            (1...tokens.length).each do |i|
              prefix = tokens[0, i].join(".")
              it "does not match a shorter token path: %p" % prefix do
                expect(transition).not_to match_event_name(prefix)
              end
            end

          end
        end

      end

      describe "with a transition that handles multiple events" do
        let(:matched_events) { "foo bar.baz error.platform" }
        subject(:transition) { Transition.new(matched_events) }

        it "matches against any of those events" do
          expect(transition).to match_event_name("foo")
          expect(transition).to match_event_name("foo.bar")
          expect(transition).to match_event_name("foo.bar.baz")
          expect(transition).to match_event_name("bar.baz")
          expect(transition).to match_event_name("bar.baz.quux")
          expect(transition).to match_event_name("bar.baz.quux")
          expect(transition).to match_event_name("error.platform")
          expect(transition).to match_event_name("error.platform.busted-fuzzle")
        end

        it "doesn't match against any other events" do
          expect(transition).to_not match_event_name("foobar")
          expect(transition).to_not match_event_name("errors.my.custom")
          expect(transition).to_not match_event_name("errorhandler.mistake")
        end

      end

    end

  end

end
