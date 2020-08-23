# frozen_string_literal: true

# based on https://xstate.js.org/docs/examples/calculator.html
StateChart.chart "calcMachine" do

  attribute :display, default: "0."
  attribute :operand1
  attribute :operand2
  attribute :operator

  # Top-level transitions will be checked *last*, after all state transitions.
  # This would not be valid in SCXML, but is a useful feature in xstate.
  on CLEAR_EVERYTHING: :start, action: :reset

  initial :start

  state :start do
    on NUMBER: "operand1.zero", if: :zero? do
      action :defaultReadout
    end
    on NUMBER: "operand1.before_decimal_point", unless: :zero? do
      action :setReadoutNum
    end
    on OPERATOR: "negative_number", if: :minus? do
      action :startNegativeNumber
    end
    on DECIMAL_POINT: "operand1.after_decimal_point" do
      action :defaultReadout
    end
  end

  state :operand1 do
    on OPERATOR: "operator_entered" do
      action :recordOperator
    end
    on PERCENTAGE: "result" do
      actions :storeResultAsOperand2, :computePercentage
    end
    on CLEAR_ENTRY: "operand1" do
      action :defaultReadout
    end
    initial :zero
    state :zero do
      on NUMBER: {
        target: "before_decimal_point",
        actions: ["setReadoutNum"]
      }
      on DECIMAL_POINT: "after_decimal_point"
    end
    state :before_decimal_point do
      on NUMBER: {
        target: "before_decimal_point",
        actions: ["appendNumBeforeDecimal"]
      }
      on DECIMAL_POINT: "after_decimal_point"
    end
    state :after_decimal_point do
      on NUMBER: {
        target: "after_decimal_point",
        actions: ["appendNumAfterDecimal"]
      }
    end
  end

  state :negative_number do
    on NUMBER: [
      {
        cond: :zero?,
        target: "operand1.zero",
        actions: ["defaultNegativeReadout"]
      },
      {
        cond: {not: :zero?},
        target: "operand1.before_decimal_point",
        actions: ["setNegativeReadoutNum"]
      }
    ]
    on DECIMAL_POINT: {
      target: "operand1.after_decimal_point",
      actions: ["defaultNegativeReadout"]
    }
    on CLEAR_ENTRY: {
      target: "start",
      actions: ["defaultReadout"]
    }
  end

  state :operator_entered do
    on OPERATOR: [
      { unless: :minus?, target: :operator_entered,  action: :setOperator },
      { if:     :minus?, target: :negative_number_2, action: :startNegativeNumber }
    ]
    on NUMBER: [
      { if: :zero?, target: "operand2.zero", action: :defaultReadout },
      {
        unless: :zero?,
        target: "operand2.before_decimal_point",
        action: :setReadoutNum,
      }
    ]
    on DECIMAL_POINT: "operand2.after_decimal_point", action: :defaultReadout
  end

  state :operand2, initial: :hist do
    on OPERATOR: "operator_entered" do
      action :storeResultAsOperand2
      action :compute
      action :storeResultAsOperand1
      action :setOperator
    end
    on EQUALS: [
      {
        unless: :divide_by_zero?,
        target: "result",
        actions: ["storeResultAsOperand2", "compute"]
      },
      { target: "alert", action: :divideByZeroAlert }
    ]
    on CLEAR_ENTRY: "operand2", action: :defaultReadout
    history :hist, default: :zero
    state :zero do
      on NUMBER: "before_decimal_point", action: :setReadoutNum
      on DECIMAL_POINT: "after_decimal_point"
    end
    state :before_decimal_point do
      on NUMBER: "before_decimal_point", action: :ppendNumBeforeDecimal
      on DECIMAL_POINT: "after_decimal_point"
    end
    state :after_decimal_point do
      on NUMBER: "after_decimal_point", action: :appendNumAfterDecimal
    end
  end

  state :negative_number_2 do
    on NUMBER: [
      {
        if: :zero?,
        target: "operand2.zero",
        actions: ["defaultNegativeReadout"]
      },
      {
        unless: :zero?,
        target: "operand2.before_decimal_point",
        actions: ["setNegativeReadoutNum"]
      }
    ]
    on DECIMAL_POINT: "operand2.after_decimal_point",
      action: :defaultNegativeReadout
    on CLEAR_ENTRY: "operator_entered", action: :defaultReadout
  end

  state :result do
    on :NUMBER do
      choose :operand1, if: :zero? do
        action :defaultReadout
      end
      choose "operand1.before_decimal_point", unless: :zero? do
        actions ["setReadoutNum"]
      end
    end
    on PERCENTAGE: "result",
      actions: ["storeResultAsOperand2", "computePercentage"]
    on OPERATOR: "operator_entered",
      actions: ["storeResultAsOperand1", "recordOperator"]
    on CLEAR_ENTRY: "start", actions: ["defaultReadout"]
  end

  state :alert do
    on OK: "operand2.hist"
  end

  conditions do
    cond :minus?, event(:operator).eq("-")
    cond :zero?,  event(:key).zero?
    cond :divide_by_zero?, attr(:operand2).eq("0.") & attr(:operator).eq("/")
  end

  actions do
    action :defaultReadout,         assign(display:  "0.")
    action :defaultNegativeReadout, assign(display: "-0.")

    action :appendNumBeforeDecimal, assign(
      display: -> { display[0...-1] + _event.key + "." }
    )

    action :appendNumAfterDecimal, assign(
      display: -> { display + _event.key }
    )

    action :setReadoutNum, assign(
      display: -> { _event.key + "." }
    )

    action setNegativeReadoutNum: assign(
      display: -> { "-#{_event.key}." }
    )

    action startNegativeNumber: assign(display: "-")

    action recordOperator: assign(
      operand1: :display,
      operator: event(:operator),
    )

    # isn't this a no-op?
    action setOperator: assign(operator: :operator)

    action computePercentage: assign(
      display: -> { display / 10 }
    )

    action :compute, assign(
      display: -> {
        case (operator)
        when "+"; operand1.to_f + operand2.to_f
        when "-"; operand1.to_f - operand2.to_f
        when "/"; operand1.to_f / operand2.to_f
        when "x"; operand1.to_f * operand2.to_f
        else Float::INFINITY
        end.tap do |result|
          logger.info {
            "doing calculation #{operand1} #{operator} #{operand2} = #{result}"
          }
        end
      },
    )

    action storeResultAsOperand1: assign(
      operand1: :display,
    )

    action storeResultAsOperand2: assign(
      operand2: :display,
    )

    # divideByZeroAlert() {
    #   // have to put the alert in setTimeout because action is executed on event, before the transition to next state happens
    #   // this alert is supposed to happend on transition
    #   // setTimeout allows time for other state transition (to 'alert' state) to happen before showing the alert
    #   // probably a better way to do it. like entry or exit actions
    #   setTimeout(() => {
    #     alert("Cannot divide by zero!");
    #     this.transition("OK");
    #   }, 0);
    # },

    action reset: assign(
      display: "0.",
      operand1: nil,
      operand2: nil,
      operator: nil,
    )

  end

end
