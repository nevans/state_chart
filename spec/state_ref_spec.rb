# frozen_string_literal: true

require "spec_helper"

module StateChart

  RSpec.describe StateRef, :aggregate_failures do

    it "rejects invalid ID or path strings" do
      expect { StateRef.new("no spaces")      }.to raise_error(InvalidName)
      expect { StateRef.new("!not-allowed")   }.to raise_error(InvalidName)
      expect { StateRef.new("nor!here....")   }.to raise_error(InvalidName)
      expect { StateRef.new("(not)allowed")   }.to raise_error(InvalidName)
      expect { StateRef.new("/")              }.to raise_error(InvalidName)
      expect { StateRef.new("......./nope")   }.to raise_error(InvalidName)
      expect { StateRef.new(".././../nope")   }.to raise_error(InvalidName)
      expect { StateRef.new("../nope/./no")   }.to raise_error(InvalidName)
      expect { StateRef.new("./no/../nope")   }.to raise_error(InvalidName)
      expect { StateRef.new("/not/../middle") }.to raise_error(InvalidName)
      expect { StateRef.new("%isn't.allowed") }.to raise_error(InvalidName)
      # maybe allow these in the future?
      expect { StateRef.new("/not/at/end/")   }.to raise_error(InvalidName)
      expect { StateRef.new("NOPE/no/good")   }.to raise_error(InvalidName)
      expect { StateRef.new("not/in/middle")  }.to raise_error(InvalidName)
    end

    shared_examples "StateRef valid ref string" do |ref_str|
      subject(:reference) { StateRef.new(ref_str) }
      it "has #to_s matching the given reference string" do
        expect(reference.to_s).to eq(ref_str)
      end
      it "has #ref and #reference aliases for to_s" do
        expect(reference.ref).to eq(ref_str)
        expect(reference.reference).to eq(ref_str)
      end
    end

    shared_examples "defined with no prefix" do |ref_str|
      include_examples "StateRef valid ref string", ref_str if ref_str
      it "is defined as potentially any type (ID or path)" do
        expect(reference).not_to be_defined_as_id
        expect(reference).not_to be_defined_as_relative_path
        expect(reference).not_to be_defined_as_absolute_path
        expect(reference).to     be_defined_as_any
      end
    end

    shared_examples "defined as an ID" do |ref_str|
      include_examples "StateRef valid ref string", ref_str if ref_str
      it "is defined as an ID (with the '#' prefix)" do
        expect(reference).to     be_defined_as_id
        expect(reference).not_to be_defined_as_relative_path
        expect(reference).not_to be_defined_as_absolute_path
        expect(reference).not_to be_defined_as_any
      end

      it "has nil #path_segments" do
        expect(reference.path_segments).to be_nil
      end
    end

    shared_examples "defined as a relative path" do |ref_str|
      include_examples "StateRef valid ref string", ref_str if ref_str
      it "is defined as a relative path" do
        expect(reference).not_to be_defined_as_id
        expect(reference).to     be_defined_as_relative_path
        expect(reference).not_to be_defined_as_absolute_path
        expect(reference).not_to be_defined_as_any
      end

      it "has path_segments" do
        expect(reference.path_segments).to be_an_instance_of(Array)
      end
    end

    context "with valid ID strings (but no '#' prefix)" do
      valid_ids = %w[okay OK.GO THIS-IS-FINE THIS.IS.FINE]
      valid_ids.each do |valid_id|
        context "e.g. %p" % [valid_id] do
          include_examples "defined with no prefix", valid_id
        end
      end
    end

    context "with valid ID strings (and a '#' prefix)" do
      valid_ids = %w[#okay #OK.GO #THIS-IS-FINE #THIS.IS.FINE]
      valid_ids.each do |valid_id|
        context "e.g. %p" % [valid_id] do
          include_examples "defined as an ID", valid_id
        end
      end
    end

    shared_examples "a resolvable StateRef" do
      it "resolves to the referent" do
        expect(reference.resolve_from(referrer)).to eq(referent)
      end
    end

    # to test resolution
    let(:chart) {
      StateChart.chart("state_ref_examples") {
        state :simple1, id: "S1"
        state :simple2, id: "S2"
        state :auto_id1
        state :auto_id2

        state :compound1, id: "C1" do
          state :simple1, id: "S3"
          state :simple2, id: "S4"
          state :auto_id1
          state :auto_id2

          state :compound1, id: "C2" do
            state :simple1, id: "S5"
            state :simple2, id: "S6"
            state :auto_id1
            state :auto_id2
          end

          state :compound2, id: "C3" do
            state :simple1, id: "S7"
            state :simple2, id: "S8"
            state :auto_id1
            state :auto_id2
          end

          parallel :parallel, id: "P1" do
            state :pstate1, id: "PS1" do
              state :off
              state :on
            end
            state :pstate2, id: "PS2" do
              state :on
              state :off
            end
            state :pstate3, id: "PS3" do
              state :off
              state :on
            end
          end

        end

        parallel :parallel, id: "P2" do
          state :pstate1, id: "PS1-2" do
            state :off
            state :on do
              state :normal
              state :abnormal
            end
          end
          state :pstate2, id: "PS2-2" do
            state :on do
              state :initializing
              state :running
              state :shutting_down
            end
            state :off
          end
          state :pstate3, id: "PS3-2" do
            state :off
            state :on
          end
        end

      }
    }

    context "with an existing '#ID' prefix" do
      include_examples "defined as an ID", "#PS2"

      it "can be resolved from the chart root" do
        state = reference.resolve_from(chart)
        expect(state).to be_a(State)
        expect(state).to eq(chart[:PS2])
      end

      it "can be resolved from an inner node" do
        state = chart[:PS2]
        expect(reference.resolve_from(chart[:S7])).to eq(state)
        expect(reference.resolve_from(chart["PS2-2"])).to eq(state)
      end

    end

    context "with an existing ID (no prefix)" do
      include_examples "defined with no prefix", "S6"

      it "can be resolved from the chart root" do
        state = reference.resolve_from(chart)
        expect(state).to be_a(State)
        expect(state).to eq(chart[:S6])
      end

      it "can be resolved from an inner node" do
        state = chart[:S6]
        current = chart["PS2-2"].states[:on].states[:running]
        expect(reference.resolve_from(current)).to eq(state)
        current = chart["C1"]
        expect(reference.resolve_from(current)).to eq(state)
      end

    end

    context "with '.' for this/self node" do
      subject(:reference) { StateRef.new(".") }
      include_examples "defined as a relative path"
      it { is_expected.to be_this }
      it { is_expected.to be_self }
      it { is_expected.not_to be_ancestor }

      it "returns the resolution node" do
        %i[C1 C2 C3 S1 S3 S5 S7 PS1 PS2-2 PS3].each do |id|
          state = chart[id]
          expect(reference.resolve_from(state)).to eq(state)
        end
      end

      it "raises an error for chart root node" do
        expect { reference.resolve_from(chart) }.to raise_error(InvalidReference)
      end

    end

    context "with '..' for parent node" do
      subject(:reference) { StateRef.new("..") }
      include_examples "defined as a relative path"
      it { is_expected.to be_parent }
      it { is_expected.to be_ancestor }

      let(:grandparent) { chart[:P2] }
      let(:parent)      { chart["PS1-2"] }
      let(:child)       { parent.states[:off] }

      it "resolves parents" do
        expect(reference.resolve_from(child)).to eq(parent)
        expect(reference.resolve_from(parent)).to eq(grandparent)
      end

      it "raises InvalidReference for the chart root" do
        expect { reference.resolve_from(grandparent).to raise_error(InvalidReference) }
      end

    end

    context "with a '.child.path' relative path prefix" do

      include_examples "defined as a relative path", ".child.path"

      context "resolving from the example chart" do
        let(:ggrandparent) { chart[:P2] }
        let(:grandparent)  { chart["PS1-2"] }
        let(:parent)       { grandparent.states[:on] }
        let(:child) { parent.states[:normal] }

        include_examples "defined as a relative path", ".pstate1.on.normal"

        let(:referrer) { ggrandparent }
        let(:referent) { child }
        include_examples "a resolvable StateRef"

        it "has four path segments" do
          expect(reference.path_segments).to eq([".", "pstate1", "on", "normal"])
        end

      end
    end

    context "with a '..sibling.path' relative path prefix" do
      include_examples "defined as a relative path", "..sibling.path"

      context "resolving from the example chart" do
        include_examples "defined as a relative path", "..compound2.auto_id1"
        let(:referrer) { chart["C2"] }
        let(:referent) { chart["C3"].states[:auto_id1] }
        include_examples "a resolvable StateRef"
      end
    end

    context "with a '....path' great-grandparent relative path prefix" do
      subject(:reference) { StateRef.new("....path.foo.bar") }
      include_examples "defined as a relative path"
      it { is_expected.to_not be_ancestor } # not a *direct* ancestor
      context "resolving from the example chart" do
        include_examples "defined as a relative path", "....parallel.pstate2"
        it "has three '..' in its path_segments" do
          expect(reference.path_segments).to eq(%w[.. .. .. parallel pstate2])
        end
        let(:referrer) { chart["PS3"] }
        let(:referent) { chart["PS2-2"] }
        include_examples "a resolvable StateRef"
      end
    end

    it "accepts extra-dotted ancestors" do
      expect(StateRef.new("...")).to be_ancestor
      expect(StateRef.new("....")).to be_ancestor
      expect(StateRef.new(".....")).to be_ancestor
      expect(StateRef.new("......")).to be_ancestor
      # and so on...
    end

    it "accepts slash delimited ancestors" do
      expect(StateRef.new("../..")).to be_ancestor
      expect(StateRef.new("../../..")).to be_ancestor
      expect(StateRef.new("../../../..")).to be_ancestor
      expect(StateRef.new("../../../../..")).to be_ancestor
      # and so on...
    end

    it "accepts slash delimited absolute path" do
      expect(StateRef.new("/path/from/root").ref).to eq("/path/from/root")
    end

    it "accepts slash delimited children, siblings, cousins" do
      expect(StateRef.new("./child/path").ref).to eq("./child/path")
      expect(StateRef.new("../sibling/path").ref).to eq("../sibling/path")
      expect(StateRef.new("../../cousin/path").ref).to eq("../../cousin/path")
    end

    context "with unspecified relative path (no special prefix)" do

      it "can have dotted path segments" do
        expect(StateRef.new("foo.bar.baz").path_segments).to eq(%w[foo bar baz])
      end

      it "can't have slashed path segments" do
        # as currently defined, slash paths must have absolute or relative root
        expect{ StateRef.new("foo/bar/baz") }.to raise_error(InvalidName)
      end

      context "resolving from the example chart" do
        subject(:reference) { StateRef.new("parallel.pstate2.off") }

        context "unresolvable" do
          subject(:reference) { StateRef.new("foo.bar.baz") }
          let(:referrer) { chart[:C1] }
          it "raises an InvalidReference error" do
            expect{ reference.resolve_from(referrer) }
              .to raise_error(InvalidReference)
          end
        end

        context "all resolving to the same state" do
          let(:referent) { chart[:PS2].states[:off] }
          context "from the parent" do
            let(:referrer) { chart[:C1] }
            include_examples "a resolvable StateRef"
          end
          context "from a sibling" do
            let(:referrer) { chart[:C3] }
            include_examples "a resolvable StateRef"
          end
          context "from inside the path" do
            let(:referrer) { chart[:PS1] }
            include_examples "a resolvable StateRef"
          end
          context "inside a nearby cousin" do
            let(:referrer) { chart[:S7] }
            include_examples "a resolvable StateRef"
          end
        end

        context "referring to a different state" do
          let(:referent) { chart["PS2-2"].states[:off] }
          context "from a remote cousin with a similar matching path" do
            let(:referrer) { chart[:S1] }
            include_examples "a resolvable StateRef"
          end
          context "from the chart root" do
            let(:referrer) { chart }
            include_examples "a resolvable StateRef"
          end
        end

      end

    end

  end

end
