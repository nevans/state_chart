Copied from https://www.w3.org/TR/scxml/#AlgorithmforSCXMLInterpretation

# D Algorithm for SCXML Interpretation

[This section is informative.]

This section contains an illustrative algorithm for the interpretation of an
SCXML document. It is intended as a guide for implementers only. Implementations
are free to implement SCXML interpreters in any way they choose.

## Informal Semantics

The following definitions and highlevel principles and constraint are intended
to provide a background to the algorithm, and to serve as a guide for the proper
understanding of it.

### Preliminary definitions

state
    An element of type `<state>`, `<parallel>`, or `<final>`.
pseudo state
    An element of type `<initial>` or `<history>`.
transition target
    A state, or an element of type `<history>`.
atomic state
    A state of type `<state>` with no child states, or a state of type
    `<final>`.
compound state
    A state of type `<state>` with at least one child state.
configuration
    The maximal consistent set of states (including parallel and final states)
    that the machine is currently in. We note that if a state s is in the
    configuration c, it is always the case that the parent of s (if any) is also
    in c. Note, however, that `<scxml>` is not a(n explicit) member of the
    configuration.
source state
    The source state of a transition is the state which contains the transition.
target state
    A target state of a transition is a state that the transition is entering.
    Note that a transition can have zero or more target states.
targetless transition
    A transition having zero target states.
eventless transition
    A transition lacking the 'event' attribute.
external event
    An SCXML event appearing in the external event queue. Such events are either
    sent by external sources or generated with the `<send>` element.
internal event
    An event appearing in the internal event queue. Such events are either
    raised automatically by the platform or generated with the `<raise>` or
    `<send>` elements.
microstep
    A microstep involves the processing of a single transition (or, in the case
    of parallel states, a single set of transitions.) A microstep may change the
    current configuration, update the data model and/or generate new (internal
    and/or external) events. This, by causality, may in turn enable additional
    transitions which will be handled in the next microstep in the sequence, and
    so on.
macrostep
    A macrostep consists of a sequence (a chain) of microsteps, at the end of
    which the state machine is in a stable state and ready to process an
    external event. Each external event causes an SCXML state machine to take
    exactly one macrostep. However, if the external event does not enable any
    transitions, no microstep will be taken, and the corresponding macrostep
    will be empty.

### Principles and Constraints

We state here some principles and constraints, on the level of semantics, that
SCXML adheres to:

Encapsulation
    An SCXML processor is a pure event processor. The only way to get data into
    an SCXML state machine is to send external events to it. The only way to get
    data out is to receive events from it.
Causality
    There shall be a causal justification of why events are (or are not)
    returned back to the environment, which can be traced back to the events
    provided by the system environment.
Determinism
    An SCXML state machine which does not invoke any external event processor
    must always react with the same behavior (i.e. the same sequence of output
    events) to a given sequence of input events (unless, of course, the state
    machine is explicitly programmed to exhibit an non-deterministic behavior).
    In particular, the availability of the `<parallel>` element must not
    introduce any non-determinism of the kind often associated with concurrency.
    Note that observable determinism does not necessarily hold for state
    machines that invoke other event processors.
Completeness
    An SCXML interpreter must always treat an SCXML document as completely
    specifying the behavior of a state machine. In particular, SCXML is designed
    to use priorities (based on document order) to resolve situations which
    other state machine frameworks would allow to remain under-specified (and
    thus non-deterministic, although in a different sense from the above).
Run to completion
    SCXML adheres to a run to completion semantics in the sense that an external
    event can only be processed when the processing of the previous external
    event has completed, i.e. when all microsteps (involving all triggered
    transitions) have been completely taken.
Termination
    A microstep always terminates. A macrostep may not. A macrostep that does
    not terminate may be said to consist of an infinitely long sequence of
    microsteps. This is currently allowed.

## Algorithm

Note that the algorithm assumes a Lisp-like semantics in which the empty Set
null is equivalent to boolean 'false' and all other entities are equivalent to
'true'.

### Datatypes

These are the abstract datatypes that are used in the algorithm.

    datatype List
       function head()    // Returns the head of the list
       function tail()    // Returns the tail of the list (i.e., the rest of the list once the head is removed)
       function append(l) // Returns the list appended with l
       function filter(f) // Returns the list of elements that satisfy the predicate f
       function some(f)   // Returns true if some element in the list satisfies the predicate f.  Returns false for an empty list.
       function every(f)  // Returns true if every element in the list satisfies the predicate f.  Returns true for an empty list.
    The notation [...] is used as a list constructor, so that '[t]' denotes a list whose only member is the object t.

    datatype OrderedSet
       procedure add(e)              // Adds e to the set if it is not already a member
       procedure delete(e)           // Deletes e from the set
       procedure union(s)            // Adds all members of s that are not already members of the set (s must also be an OrderedSet)
       function  isMember(e)         // Is e a member of set?
       function  some(f)             // Returns true if some element in the set satisfies the predicate f.  Returns false for an empty set.
       function  every(f)            // Returns true if every element in the set satisfies the predicate f. Returns true for an empty set.
       function  hasIntersection(s)  // Returns true if this set and  set s have at least one member in common
       function  isEmpty()           // Is the set empty?
       procedure clear()             // Remove all elements from the set (make it empty)
       function  toList()            // Converts the set to a list that reflects the order in which elements were originally added
          // In the case of sets created by intersection, the order of the first set (the one on which the method was called) is used
          // In the case of sets created by union, the members of the first set (the one on which union was called) retain their original ordering
          // while any members belonging to the second set only are placed after, retaining their ordering in their original set.

    datatype Queue
       procedure enqueue(e) // Puts e last in the queue
       function dequeue()   // Removes and returns first element in queue
       function isEmpty()   // Is the queue empty?

    datatype BlockingQueue
       procedure enqueue(e) // Puts e last in the queue
       function dequeue()   // Removes and returns first element in queue, blocks if queue is empty

    datatype HashTable // table[foo] returns the value associated with foo.  table[foo] = bar sets the value associated with foo to be bar.

### Global variables

The following variables are global from the point of view of the algorithm.
Their values will be set in the procedure interpret().

    global configuration
    global statesToInvoke
    global datamodel
    global internalQueue
    global externalQueue
    global historyValue
    global running
    global binding

### Predicates

The following binary predicates are used for determining the order in which
states are entered and exited.

    entryOrder // Ancestors precede descendants, with document order being used to break ties
        (Note:since ancestors precede descendants, this is equivalent to document order.)
    exitOrder  // Descendants precede ancestors, with reverse document order being used to break ties
        (Note: since descendants follow ancestors, this is equivalent to reverse document order.)

The following binary predicate is used to determine the order in which we
examine transitions within a state.

    documentOrder // The order in which the elements occurred in the original document.

### Procedures and Functions

This section defines the procedures and functions that make up the core of the
SCXML interpreter. N.B. in the code below, the keyword 'continue' has its
traditional meaning in languages like C: break off the current iteration of the
loop and proceed to the next iteration.

#### procedure interpret(scxml,id)

The purpose of this procedure is to initialize the interpreter and to start
processing.

In order to interpret an SCXML document, first (optionally) perform [xinclude]
processing and (optionally) validate the document, throwing an exception if
validation fails. Then convert initial attributes to `<initial>` container
children with transitions to the state specified by the attribute. (This step is
done purely to simplify the statement of the algorithm and has no effect on the
system's behavior. Such transitions will not contain any executable content).
Initialize the global data structures, including the data model. If binding is
set to 'early', initialize the data model. Then execute the global `<script>`
element, if any. Finally call enterStates on the initial configuration, set the
global running variable to true and start the interpreter's event loop.

    procedure interpret(doc):
        if not valid(doc): failWithError()
        expandScxmlSource(doc)
        configuration = new OrderedSet()
        statesToInvoke = new OrderedSet()
        internalQueue = new Queue()
        externalQueue = new BlockingQueue()
        historyValue = new HashTable()
        datamodel = new Datamodel(doc)
        if doc.binding == "early":
            initializeDatamodel(datamodel, doc)
        running = true
        executeGlobalScriptElement(doc)
        enterStates([doc.initial.transition])
        mainEventLoop()

#### procedure mainEventLoop()

This loop runs until we enter a top-level final state or an external entity
cancels processing. In either case 'running' will be set to false (see
EnterStates, below, for termination by entering a top-level final state.)

At the top of the loop, we have either just entered the state machine, or we
have just processed an external event. Each iteration through the loop consists
of four main steps: 1)Complete the macrostep by repeatedly taking any internally
enabled transitions, namely those that don't require an event or that are
triggered by an internal event. After each such transition/microstep, check to
see if we have reached a final state. 2) When there are no more internally
enabled transitions available, the macrostep is done. Execute any `<invoke>`
tags for states that we entered on the last iteration through the loop 3) If any
internal events have been generated by the invokes, repeat step 1 to handle any
errors raised by the `<invoke>` elements. 4) When the internal event queue is
empty, wait for an external event and then execute any transitions that it
triggers. However special preliminary processing is applied to the event if the
state has executed any `<invoke>` elements. First, if this event was generated
by an invoked process, apply `<finalize>` processing to it. Secondly, if any
`<invoke>` elements have autoforwarding set, forward the event to them. These
steps apply before the transitions are taken.

This event loop thus enforces run-to-completion semantics, in which the system
process an external event and then takes all the 'follow-up' transitions that
the processing has enabled before looking for another external event. For
example, suppose that the external event queue contains events ext1 and ext2 and
the machine is in state s1. If processing ext1 takes the machine to s2 and
generates internal event int1, and s2 contains a transition t triggered by int1,
the system is guaranteed to take t, no matter what transitions s2 or other
states have that would be triggered by ext2. Note that this is true even though
ext2 was already in the external event queue when int1 was generated. In effect,
the algorithm treats the processing of int1 as finishing up the processing of
ext1.

```
procedure mainEventLoop():
    while running:
        enabledTransitions = null
        macrostepDone = false

        # Here we handle eventless transitions and transitions
        # triggered by internal events until macrostep is complete
        while running and not macrostepDone:
            enabledTransitions = selectEventlessTransitions()
            if enabledTransitions.isEmpty():
                if internalQueue.isEmpty():
                    macrostepDone = true
                else:
                    internalEvent = internalQueue.dequeue()
                    datamodel["_event"] = internalEvent
                    enabledTransitions = selectTransitions(internalEvent)
            if not enabledTransitions.isEmpty():
                microstep(enabledTransitions.toList())

        # either we're in a final state, and we break out of the loop
        if not running:
            break

        # or we've completed a macrostep, so we start a new macrostep by
        # waiting for an external event.
        # Here we invoke whatever needs to be invoked. The implementation of
        # 'invoke' is platform-specific
        for state in statesToInvoke.sort(entryOrder):
            for inv in state.invoke.sort(documentOrder):
                invoke(inv)

        statesToInvoke.clear()
        # Invoking may have raised internal error events and we iterate to
        # handle them
        if not internalQueue.isEmpty():
            continue

        # A blocking wait for an external event.  Alternatively, if we have been
        # invoked our parent session also might cancel us.  The mechanism for
        # this is platform specific, but here we assume it’s a special event we
        # receive
        externalEvent = externalQueue.dequeue()
        if isCancelEvent(externalEvent):
            running = false
            continue

        datamodel["_event"] = externalEvent
        for state in configuration:
            for inv in state.invoke:
                if inv.invokeid == externalEvent.invokeid:
                    applyFinalize(inv, externalEvent)
                if inv.autoforward:
                    send(inv.id, externalEvent)

        enabledTransitions = selectTransitions(externalEvent)
        if not enabledTransitions.isEmpty():
            microstep(enabledTransitions.toList())

    # End of outer while running loop.  If we get here, we have reached a
    # top-level final state or have been cancelled
    exitInterpreter()
```

#### procedure exitInterpreter()

The purpose of this procedure is to exit the current SCXML process by exiting
all active states. If the machine is in a top-level final state, a Done event is
generated. (Note that in this case, the final state will be the only active
state.) The implementation of returnDoneEvent is platform-dependent, but if this
session is the result of an `<invoke>` in another SCXML session, returnDoneEvent
will cause the event done.invoke.`<id>` to be placed in the external event queue
of that session, where `<id>` is the id generated in that session when the
`<invoke>` was executed.

    procedure exitInterpreter():
        statesToExit = configuration.toList().sort(exitOrder)
        for s in statesToExit:
            for content in s.onexit.sort(documentOrder):
                executeContent(content)
            for inv in s.invoke:
                cancelInvoke(inv)
            configuration.delete(s)
            if isFinalState(s) and isScxmlElement(s.parent):
                returnDoneEvent(s.donedata)

#### function selectEventlessTransitions()

This function selects all transitions that are enabled in the current
configuration that do not require an event trigger. First find a transition with
no 'event' attribute whose condition evaluates to true. If multiple matching
transitions are present, take the first in document order. If none are present,
search in the state's ancestors in ancestry order until one is found. As soon as
such a transition is found, add it to enabledTransitions, and proceed to the
next atomic state in the configuration. If no such transition is found in the
state or its ancestors, proceed to the next state in the configuration. When all
atomic states have been visited and transitions selected, filter the set of
enabled transitions, removing any that are preempted by other transitions, then
return the resulting set.

    function selectEventlessTransitions():
        enabledTransitions = new OrderedSet()
        atomicStates = configuration.toList().filter(isAtomicState).sort(documentOrder)
        for state in atomicStates:
            loop: for s in [state].append(getProperAncestors(state, null)):
                for t in s.transition.sort(documentOrder):
                    if not t.event and conditionMatch(t):
                        enabledTransitions.add(t)
                        break loop
        enabledTransitions = removeConflictingTransitions(enabledTransitions)
        return enabledTransitions

#### function selectTransitions(event)

The purpose of the selectTransitions()procedure is to collect the transitions
that are enabled by this event in the current configuration.

Create an empty set of enabledTransitions. For each atomic state , find a
transition whose 'event' attribute matches event and whose condition evaluates
to true. If multiple matching transitions are present, take the first in
document order. If none are present, search in the state's ancestors in ancestry
order until one is found. As soon as such a transition is found, add it to
enabledTransitions, and proceed to the next atomic state in the configuration.
If no such transition is found in the state or its ancestors, proceed to the
next state in the configuration. When all atomic states have been visited and
transitions selected, filter out any preempted transitions and return the
resulting set.

    function selectTransitions(event):
        enabledTransitions = new OrderedSet()
        atomicStates = configuration.toList().filter(isAtomicState).sort(documentOrder)
        for state in atomicStates:
            loop: for s in [state].append(getProperAncestors(state, null)):
                for t in s.transition.sort(documentOrder):
                    if t.event and nameMatch(t.event, event.name) and conditionMatch(t):
                        enabledTransitions.add(t)
                        break loop
        enabledTransitions = removeConflictingTransitions(enabledTransitions)
        return enabledTransitions

#### function removeConflictingTransitions(enabledTransitions)

enabledTransitions will contain multiple transitions only if a parallel state is
active. In that case, we may have one transition selected for each of its
children. These transitions may conflict with each other in the sense that they
have incompatible target states. Loosely speaking, transitions are compatible
when each one is contained within a single `<state>` child of the `<parallel>`
element. Transitions that aren't contained within a single child force the state
machine to leave the `<parallel>` ancestor (even if they reenter it later). Such
transitions conflict with each other, and with transitions that remain within a
single `<state>` child, in that they may have targets that cannot be
simultaneously active. The test that transitions have non-intersecting exit sets
captures this requirement. (If the intersection is null, the source and targets
of the two transitions are contained in separate `<state>` descendants of
`<parallel>`. If intersection is non-null, then at least one of the transitions
is exiting the `<parallel>`). When such a conflict occurs, then if the source
state of one of the transitions is a descendant of the source state of the
other, we select the transition in the descendant. Otherwise we prefer the
transition that was selected by the earlier state in document order and discard
the other transition. Note that targetless transitions have empty exit sets and
thus do not conflict with any other transitions.

We start with a list of enabledTransitions and produce a conflict-free list of
filteredTransitions. For each t1 in enabledTransitions, we test it against all
t2 that are already selected in filteredTransitions. If there is a conflict,
then if t1's source state is a descendant of t2's source state, we prefer t1 and
say that it preempts t2 (so we we make a note to remove t2 from
filteredTransitions). Otherwise, we prefer t2 since it was selected in an
earlier state in document order, so we say that it preempts t1. (There's no need
to do anything in this case since t2 is already in filteredTransitions.
Furthermore, once one transition preempts t1, there is no need to test t1
against any other transitions.) Finally, if t1 isn't preempted by any transition
in filteredTransitions, remove any transitions that it preempts and add it to
that list.

    function removeConflictingTransitions(enabledTransitions):
        filteredTransitions = new OrderedSet()
        //toList sorts the transitions in the order of the states that selected them
        for t1 in enabledTransitions.toList():
            t1Preempted = false
            transitionsToRemove = new OrderedSet()
            for t2 in filteredTransitions.toList():
                if computeExitSet([t1]).hasIntersection(computeExitSet([t2])):
                    if isDescendant(t1.source, t2.source):
                        transitionsToRemove.add(t2)
                    else:
                        t1Preempted = true
                        break
            if not t1Preempted:
                for t3 in transitionsToRemove.toList():
                    filteredTransitions.delete(t3)
                filteredTransitions.add(t1)
        return filteredTransitions

#### procedure microstep(enabledTransitions)

The purpose of the microstep procedure is to process a single set of
transitions. These may have been enabled by an external event, an internal
event, or by the presence or absence of certain values in the data model at the
current point in time. The processing of the enabled transitions must be done in
parallel ('lock step') in the sense that their source states must first be
exited, then their actions must be executed, and finally their target states
entered.

If a single atomic state is active, then enabledTransitions will contain only a
single transition. If multiple states are active (i.e., we are in a parallel
region), then there may be multiple transitions, one per active atomic state
(though some states may not select a transition.) In this case, the transitions
are taken in the document order of the atomic states that selected them.

    procedure microstep(enabledTransitions):
        exitStates(enabledTransitions)
        executeTransitionContent(enabledTransitions)
        enterStates(enabledTransitions)

#### procedure exitStates(enabledTransitions)

Compute the set of states to exit. Then remove all the states on statesToExit
from the set of states that will have invoke processing done at the start of the
next macrostep. (Suppose macrostep M1 consists of microsteps m11 and m12. We may
enter state s in m11 and exit it in m12. We will add s to statesToInvoke in m11,
and must remove it in m12. In the subsequent macrostep M2, we will apply invoke
processing to all states that were entered, and not exited, in M1.) Then convert
statesToExit to a list and sort it in exitOrder.

For each state s in the list, if s has a deep history state h, set the history
value of h to be the list of all atomic descendants of s that are members in the
current configuration, else set its value to be the list of all immediate
children of s that are members of the current configuration. Again for each
state s in the list, first execute any onexit handlers, then cancel any ongoing
invocations, and finally remove s from the current configuration.

    procedure exitStates(enabledTransitions):
        statesToExit = computeExitSet(enabledTransitions)
        for s in statesToExit:
            statesToInvoke.delete(s)
        statesToExit = statesToExit.toList().sort(exitOrder)
        for s in statesToExit:
            for h in s.history:
                if h.type == "deep":
                    f = lambda s0: isAtomicState(s0) and isDescendant(s0,s)
                else:
                    f = lambda s0: s0.parent == s
                historyValue[h.id] = configuration.toList().filter(f)
        for s in statesToExit:
            for content in s.onexit.sort(documentOrder):
                executeContent(content)
            for inv in s.invoke:
                cancelInvoke(inv)
            configuration.delete(s)

#### procedure computeExitSet(enabledTransitions)

For each transition t in enabledTransitions, if t is targetless then do nothing,
else compute the transition's domain. (This will be the source state in the case
of internal transitions) or the least common compound ancestor state of the
source state and target states of t (in the case of external transitions. Add to
the statesToExit set all states in the configuration that are descendants of the
domain.

    function computeExitSet(transitions)
        statesToExit = new OrderedSet
        for t in transitions:
            if t.target:
                domain = getTransitionDomain(t)
                for s in configuration:
                    if isDescendant(s,domain):
                        statesToExit.add(s)
        return statesToExit

#### procedure executeTransitionContent(enabledTransitions)

For each transition in the list of enabledTransitions, execute its executable
content.

    procedure executeTransitionContent(enabledTransitions):
        for t in enabledTransitions:
            executeContent(t)

#### procedure enterStates(enabledTransitions)

First, compute the list of all the states that will be entered as a result of
taking the transitions in enabledTransitions. Add them to statesToInvoke so that
invoke processing can be done at the start of the next macrostep. Convert
statesToEnter to a list and sort it in entryOrder. For each state s in the list,
first add s to the current configuration. Then if we are using late binding, and
this is the first time we have entered s, initialize its data model. Then
execute any onentry handlers. If s's initial state is being entered by default,
execute any executable content in the initial transition. If a history state in
s was the target of a transition, and s has not been entered before, execute the
content inside the history state's default transition. Finally, if s is a final
state, generate relevant Done events. If we have reached a top-level final
state, set running to false as a signal to stop processing.

    procedure enterStates(enabledTransitions):
        statesToEnter = new OrderedSet()
        statesForDefaultEntry = new OrderedSet()
        // initialize the temporary table for default content in history states
        defaultHistoryContent = new HashTable()
        computeEntrySet(enabledTransitions, statesToEnter, statesForDefaultEntry, defaultHistoryContent)
        for s in statesToEnter.toList().sort(entryOrder):
            configuration.add(s)
            statesToInvoke.add(s)
            if binding == "late" and s.isFirstEntry:
                initializeDataModel(datamodel.s,doc.s)
                s.isFirstEntry = false
            for content in s.onentry.sort(documentOrder):
                executeContent(content)
            if statesForDefaultEntry.isMember(s):
                executeContent(s.initial.transition)
            if defaultHistoryContent[s.id]:
                executeContent(defaultHistoryContent[s.id])
            if isFinalState(s):
                if isSCXMLElement(s.parent):
                    running = false
                else:
                    parent = s.parent
                    grandparent = parent.parent
                    internalQueue.enqueue(new Event("done.state." + parent.id, s.donedata))
                    if isParallelState(grandparent):
                        if getChildStates(grandparent).every(isInFinalState):
                            internalQueue.enqueue(new Event("done.state." + grandparent.id))


#### procedure computeEntrySet(transitions, statesToEnter, statesForDefaultEntry, defaultHistoryContent)

Compute the complete set of states that will be entered as a result of taking
'transitions'. This value will be returned in 'statesToEnter' (which is modified
by this procedure). Also place in 'statesForDefaultEntry' the set of all states
whose default initial states were entered. First gather up all the target states
in 'transitions'. Then add them and, for all that are not atomic states, add all
of their (default) descendants until we reach one or more atomic states. Then
add any ancestors that will be entered within the domain of the transition.
(Ancestors outside of the domain of the transition will not have been exited.)

    procedure computeEntrySet(transitions, statesToEnter, statesForDefaultEntry, defaultHistoryContent)
        for t in transitions:
            for s in t.target:
                addDescendantStatesToEnter(s,statesToEnter,statesForDefaultEntry, defaultHistoryContent)
            ancestor = getTransitionDomain(t)
            for s in getEffectiveTargetStates(t)):
                addAncestorStatesToEnter(s, ancestor, statesToEnter, statesForDefaultEntry, defaultHistoryContent)

#### procedure addDescendantStatesToEnter(state,statesToEnter,statesForDefaultEntry, defaultHistoryContent)

The purpose of this procedure is to add to statesToEnter 'state' and any of its
descendants that the state machine will end up entering when it enters 'state'.
(N.B. If 'state' is a history pseudo-state, we dereference it and add the
history value instead.) Note that this procedure permanently modifies both
statesToEnter and statesForDefaultEntry.

First, If state is a history state then add either the history values associated
with state or state's default target to statesToEnter. Then (since the history
value may not be an immediate descendant of 'state's parent) add any ancestors
between the history value and state's parent. Else (if state is not a history
state), add state to statesToEnter. Then if state is a compound state, add state
to statesForDefaultEntry and recursively call addStatesToEnter on its default
initial state(s). Then, since the default initial states may not be children of
'state', add any ancestors between the default initial states and 'state'.
Otherwise, if state is a parallel state, recursively call addStatesToEnter on
any of its child states that don't already have a descendant on statesToEnter.

    procedure addDescendantStatesToEnter(state,statesToEnter,statesForDefaultEntry, defaultHistoryContent):
        if isHistoryState(state):
            if historyValue[state.id]:
                for s in historyValue[state.id]:
                    addDescendantStatesToEnter(s,statesToEnter,statesForDefaultEntry, defaultHistoryContent)
                for s in historyValue[state.id]:
                    addAncestorStatesToEnter(s, state.parent, statesToEnter, statesForDefaultEntry, defaultHistoryContent)
            else:
                defaultHistoryContent[state.parent.id] = state.transition.content
                for s in state.transition.target:
                    addDescendantStatesToEnter(s,statesToEnter,statesForDefaultEntry, defaultHistoryContent)
                for s in state.transition.target:
                    addAncestorStatesToEnter(s, state.parent, statesToEnter, statesForDefaultEntry, defaultHistoryContent)
        else:
            statesToEnter.add(state)
            if isCompoundState(state):
                statesForDefaultEntry.add(state)
                for s in state.initial.transition.target:
                    addDescendantStatesToEnter(s,statesToEnter,statesForDefaultEntry, defaultHistoryContent)
                for s in state.initial.transition.target:
                    addAncestorStatesToEnter(s, state, statesToEnter, statesForDefaultEntry, defaultHistoryContent)
            else:
                if isParallelState(state):
                    for child in getChildStates(state):
                        if not statesToEnter.some(lambda s: isDescendant(s,child)):
                            addDescendantStatesToEnter(child,statesToEnter,statesForDefaultEntry, defaultHistoryContent)

#### procedure addAncestorStatesToEnter(state, ancestor, statesToEnter, statesForDefaultEntry, defaultHistoryContent)

Add to statesToEnter any ancestors of 'state' up to, but not including,
'ancestor' that must be entered in order to enter 'state'. If any of these
ancestor states is a parallel state, we must fill in its descendants as well.

    procedure addAncestorStatesToEnter(state, ancestor, statesToEnter, statesForDefaultEntry, defaultHistoryContent)
        for anc in getProperAncestors(state,ancestor):
            statesToEnter.add(anc)
            if isParallelState(anc):
                for child in getChildStates(anc):
                    if not statesToEnter.some(lambda s: isDescendant(s,child)):
                        addDescendantStatesToEnter(child,statesToEnter,statesForDefaultEntry, defaultHistoryContent)

#### procedure isInFinalState(s)

Return true if s is a compound `<state>` and one of its children is an active
`<final>` state (i.e. is a member of the current configuration), or if s is a
`<parallel>` state and isInFinalState is true of all its children.

    function isInFinalState(s):
        if isCompoundState(s):
            return getChildStates(s).some(lambda s: isFinalState(s) and configuration.isMember(s))
        elif isParallelState(s):
            return getChildStates(s).every(isInFinalState)
        else:
            return false

#### function getTransitionDomain(transition)

Return the compound state such that 1) all states that are exited or entered as
a result of taking 'transition' are descendants of it 2) no descendant of it has
this property.

    function getTransitionDomain(t)
        tstates = getEffectiveTargetStates(t)
        if not tstates:
            return null
        elif t.type == "internal" and isCompoundState(t.source) and tstates.every(lambda s: isDescendant(s,t.source)):
            return t.source
        else:
            return findLCCA([t.source].append(tstates))

#### function findLCCA(stateList)

The Least Common Compound Ancestor is the `<state>` or `<scxml>` element s such
that s is a proper ancestor of all states on stateList and no descendant of s
has this property. Note that there is guaranteed to be such an element since the
`<scxml>` wrapper element is a common ancestor of all states. Note also that
since we are speaking of proper ancestor (parent or parent of a parent, etc.)
the LCCA is never a member of stateList.

    function findLCCA(stateList):
        for anc in getProperAncestors(stateList.head(),null).filter(isCompoundStateOrScxmlElement):
            if stateList.tail().every(lambda s: isDescendant(s,anc)):
                return anc

#### function getEffectiveTargetStates(transition)

Returns the states that will be the target when 'transition' is taken,
dereferencing any history states.

    function getEffectiveTargetStates(transition)
        targets = new OrderedSet()
        for s in transition.target
            if isHistoryState(s):
                if historyValue[s.id]:
                    targets.union(historyValue[s.id])
                else:
                    targets.union(getEffectiveTargetStates(s.transition))
            else:
                targets.add(s)
        return targets


#### function getProperAncestors(state1, state2)

If state2 is null, returns the set of all ancestors of state1 in ancestry order
(state1's parent followed by the parent's parent, etc. up to an including the
`<scxml>` element). If state2 is non-null, returns in ancestry order the set of
all ancestors of state1, up to but not including state2. (A "proper ancestor" of
a state is its parent, or the parent's parent, or the parent's parent's parent,
etc.))If state2 is state1's parent, or equal to state1, or a descendant of
state1, this returns the empty set.

#### function isDescendant(state1, state2)

Returns 'true' if state1 is a descendant of state2 (a child, or a child of a
child, or a child of a child of a child, etc.) Otherwise returns 'false'.

#### function getChildStates(state1)

Returns a list containing all `<state>`, `<final>`, and `<parallel>` children of
state1.
