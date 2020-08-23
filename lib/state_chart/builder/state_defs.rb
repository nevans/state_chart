# frozen_string_literal: true

require_relative "state_attr_defs"

module StateChart

  module Builder

    ########################################################################
    # class heirarchy, follows a roughly parallel shape to {State}
    ########################################################################

    class StateDef < Definition
      include MetaDataAttr
    end

    # Chart isn't actually a state at all, but it behaves enough like one
    # It's like {CompoundDef}, except:
    # * missing ActionsAttrs from LegalStateDef
    # * missing TransitionAttrs from NonfinalStateDef
    # * missing HistoryStateAttr from ParentNodeAttrs
    # * initial must not take an actions block
    # * it should allow a single on_load action
    class ChartDef < StateDef
      include DataModelAttr
      include ParentNodeAttrs
      include InitialStateAttr
      include FinalStateAttr

      def initial(target)
        super(target) # no actions block allowed at top level
      end

    end

    class LegalStateDef < StateDef
      include DataModelAttr
      include ActionsAttrs
    end

    class NonfinalStateDef < LegalStateDef
      include TransitionAttrs
    end

    class ParentStateDef < NonfinalStateDef
      include ParentNodeAttrs
      include HistoryStateAttr
    end

    # like SCXML <state>, but atomic only
    class AtomicDef < NonfinalStateDef
      # nothing additional
    end

    class FinalDef < LegalStateDef
      include DoneDataAttr
    end

    class CompoundDef < ParentStateDef
      include InitialStateAttr
      include FinalStateAttr
    end

    class ParallelDef < ParentStateDef
      # nothing additional
    end

  end
end
