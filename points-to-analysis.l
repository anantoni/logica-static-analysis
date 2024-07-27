@Engine("duckdb");

@Ground("AssignHeapAllocation");
@Ground("ActualParam");
@Ground("AssignLocal");
@Ground("AssignCast");
@Ground("ApplicationClass");
@Ground("MainClass");
@Ground("Method");
@Ground("Var-Type");
@Ground("ThisVar");
@Ground("VirtualMethodInvocation");
@Ground("SpecialMethodInvocation");
@Ground("StaticMethodInvocation");
@Ground("StoreArrayIndex");
@Ground("LoadArrayIndex");
@Ground("StoreStaticField");
@Ground("LoadStaticField");
@Ground("StoreInstanceField");
@Ground("LoadInstanceField");
@Ground("HeapAllocation_Type");
@Ground("ComponentType");
@Ground("SubtypeOf");
@Ground("MethodInvocation_Method");
@Ground("Instruction_Method");
@Ground("SpecialMethodInvocation_Base");
@Ground("VirtualMethodInvocation_Base");
@Ground("VirtualMethodInvocation_Descriptor");
@Ground("VirtualMethodInvocation_SimpleName");
@Ground("InitializedClass");
@Ground("ClassInitializer");
@Ground("ImplicitReachable");
@Ground("MethodLookup");
@Ground("ReturnVar");
@Ground("AssignReturnValue");

AssignHeapAllocation(..r) :-
    `('./facts/AssignHeapAllocation.csv')`(..r);

ActualParam(..r) :-
    `('./facts/ActualParam.csv')`(..r);

AssignLocal(..r) :-
    `('./facts/AssignLocal.csv')`(..r);

AssignCast(..r) :-
    `('./facts/AssignCast.csv')`(..r);

ApplicationClass(..r) :-
    `('./facts/ApplicationClass.csv')`(..r);

MainClass(..r) :-
    `('./facts/MainClass.csv')`(..r);

Method(..r) :-
    `('./facts/Method.csv')`(..r);

FormalParam(..r) :-
    `('./facts/FormalParam.csv')`(..r);

Var_Type(..r) :-
    `('./facts/Var-Type.csv')`(..r);

ThisVar(..r) :-
    `('./facts/ThisVar.csv')`(..r);

VirtualMethodInvocation(..r) :-
    `('./facts/VirtualMethodInvocation.csv')`(..r);

SpecialMethodInvocation(..r) :-
    `('./facts/SpecialMethodInvocation.csv')`(..r);

StaticMethodInvocation(..r) :-
    `('./facts/StaticMethodInvocation.csv')`(..r);

StoreArrayIndex(..r) :-
    `('./facts/StoreArrayIndex.csv')`(..r);

LoadArrayIndex(..r) :-
    `('./facts/LoadArrayIndex.csv')`(..r);

StoreStaticField(..r) :-
    `('./facts/StoreStaticField.csv')`(..r);

LoadStaticField(..r) :-
    `('./facts/LoadStaticField.csv')`(..r);

StoreInstanceField(..r) :-
    `('./facts/StoreInstanceField.csv')`(..r);

LoadInstanceField(..r) :-
    `('./facts/LoadInstanceField.csv')`(..r);

HeapAllocation_Type(..r) :-
    `('./facts/HeapAllocation_Type.csv')`(..r);

ComponentType(..r) :-
    `('./facts/ComponentType.csv')`(..r);

SubtypeOf(..r) :-
    `('./facts/SubtypeOf.csv')`(..r);

MethodInvocation_Method(..r) :-
    `('./facts/MethodInvocation_Method.csv')`(..r);

Instruction_Method(..r) :-
    `('./facts/Instruction_Method.csv')`(..r);

SpecialMethodInvocation_Base(..r) :- 
    `('./facts/SpecialMethodInvocation_Base.csv')`(..r);

VirtualMethodInvocation_Base(..r) :- 
    `('./facts/VirtualMethodInvocation_Base.csv')`(..r); 

VirtualMethodInvocation_Descriptor(..r) :- 
    `('./facts/VirtualMethodInvocation_Descriptor.csv')`(..r); 

VirtualMethodInvocation_SimpleName(..r) :- 
    `('./facts/VirtualMethodInvocation_SimpleName.csv')`(..r);

InitializedClass(..r) :- 
    `('./facts/InitializedClass.csv')`(..r);

ClassInitializer(..r) :-
    `('./facts/ClassInitializer.csv')`(..r);

ImplicitReachable(..r) :-
    `('./facts/ImplicitReachable.csv')`(..r);

MethodLookup(..r) :-
    `('./facts/MethodLookup.csv')`(..r);

ReturnVar(..r) :-
    `('./facts/ReturnVar.csv')`(..r);

AssignReturnValue(..r) :-
    `('./facts/AssignReturnValue.csv')`(..r);

ComponentType(..r) :-
    `('./facts/ComponentType.csv')`(..r);

@Ground("SupertypeOf");
SupertypeOf(supertype, type) :-
    SubtypeOf(type, supertype);     

/**
 * Invocation assignments
 */
@Ground("Assign");
Assign(actual, formal) distinct :-
   CallGraphEdge(invocation, method),
   FormalParam(index, method, formal),
   ActualParam(index, invocation, actual);

Assign(return, local) distinct :-
   CallGraphEdge(invocation, method),
   ReturnVar(return, method),
   AssignReturnValue(invocation, local);

@Ground("VarPointsTo");
VarPointsTo(heap, var) distinct :-
  AssignHeapAllocation(instruction, index, heap, var, inmethod, linenumber),
  Reachable(inmethod);

/**
 *  Variable points to heap object via assignment
 */

VarPointsTo(heap, to) distinct :-
   Assign(from, to),
   VarPointsTo(heap, from);

/**
 *  Local Assignments
 */

VarPointsTo(heap, to) distinct :-
   Reachable(inmethod),
   AssignLocal(from, to, inmethod),
   VarPointsTo(heap, from);

/**
 * Cast Assignments
 */

VarPointsTo(heap, to) distinct :-
    Reachable(method),
    AssignCast(type, from, to, method),
    SupertypeOf(type, heaptype),
    HeapAllocation_Type(heap, heaptype),
    VarPointsTo(heap, from);

/**
 * Arrays
 */
@Ground("ArrayIndexPointsTo");
ArrayIndexPointsTo(baseheap, heap) distinct :-
   Reachable(inmethod),
   StoreArrayIndex(from, base, inmethod),
   VarPointsTo(baseheap, base),
   VarPointsTo(heap, from),
   HeapAllocation_Type(heap, heaptype),
   HeapAllocation_Type(baseheap, baseheaptype),
   ComponentType(baseheaptype, componenttype),
   SupertypeOf(componenttype, heaptype);

VarPointsTo(heap, to) distinct :-
   Reachable(inmethod),
   LoadArrayIndex(base, to, inmethod),
   VarPointsTo(baseheap, base),
   ArrayIndexPointsTo(baseheap, heap),
   Var_Type(to, type),
   HeapAllocation_Type(baseheap, baseheaptype),
   ComponentType(baseheaptype, basecomponenttype),
   SupertypeOf(type, basecomponenttype);

/**
 * Load instance fields
 */

VarPointsTo(heap, to) distinct :-
   Reachable(inmethod),
   LoadInstanceField(base, signature, to, inmethod),
   VarPointsTo(baseheap, base),
   InstanceFieldPointsTo(heap, signature, baseheap);

/**
 * Store instance fields
 */
@Ground("InstanceFieldPointsTo");
InstanceFieldPointsTo(heap, fld, baseheap) distinct :-
  Reachable(inmethod),
  StoreInstanceField(from, base, fld, inmethod),
  VarPointsTo(heap, from),
  VarPointsTo(baseheap, base);

/**
 * Load static fields
 */

VarPointsTo(heap, to) distinct :-
  Reachable(inmethod),
  LoadStaticField(fld, to, inmethod),
  StaticFieldPointsTo(heap, fld);

/**
 * Store static fields
 */
@Ground("StaticFieldPointsTo");
StaticFieldPointsTo(heap, fld) distinct :-
    Reachable(method),
    StoreStaticField(from, fld, inmethod),
    VarPointsTo(heap, from),
    inmethod = method;

VarPointsTo(heap, this) distinct :-
  Reachable(method),
  Instruction_Method(invocation, inmethod),
  VirtualMethodInvocation_Base(invocation, base),
  VarPointsTo(heap, base),
  HeapAllocation_Type(heap, heaptype),
  VirtualMethodInvocation_SimpleName(invocation, simplename),
  VirtualMethodInvocation_Descriptor(invocation, descriptor),
  MethodLookup(simplename, descriptor, heaptype, tomethod),
  ThisVar(tomethod, this);

/**
 *   Call graph creation
 **/
@Ground("Reachable");
Reachable(tomethod) distinct :-
  Reachable(inmethod),
  Instruction_Method(invocation, inmethod),
  VirtualMethodInvocation_Base(invocation, base),
  VarPointsTo(heap, base),
  HeapAllocation_Type(heap, heaptype),
  VirtualMethodInvocation_SimpleName(invocation, simplename),
  VirtualMethodInvocation_Descriptor(invocation, descriptor),
  MethodLookup(simplename, descriptor, heaptype, tomethod);

@Ground("CallGraphEdge");
CallGraphEdge(invocation, tomethod) distinct :-
  Reachable(inmethod),
  Instruction_Method(invocation, inmethod),
  VirtualMethodInvocation_Base(invocation, base),
  VarPointsTo(heap, base),
  HeapAllocation_Type(heap, heaptype),
  VirtualMethodInvocation_SimpleName(invocation, simplename),
  VirtualMethodInvocation_Descriptor(invocation, descriptor),
  MethodLookup(simplename, descriptor, heaptype, tomethod);

Reachable(tomethod) distinct :-
  Reachable(inmethod),
  StaticMethodInvocation(invocation, index, tomethod, inmethod);

CallGraphEdge(invocation, tomethod) distinct :-
   Reachable(inmethod),
   StaticMethodInvocation(invocation, index, tomethod, inmethod);

Reachable(tomethod) distinct :- 
   Reachable(inmethod),
   Instruction_Method(invocation, inmethod),
   SpecialMethodInvocation_Base(invocation, base),
   VarPointsTo(heap, base),
   MethodInvocation_Method(invocation, tomethod),
   ThisVar(tomethod, this);

CallGraphEdge(invocation, tomethod) distinct :-
   Reachable(inmethod),
   Instruction_Method(invocation, inmethod),
   SpecialMethodInvocation_Base(invocation, base),
   VarPointsTo(heap, base),
   MethodInvocation_Method(invocation, tomethod),
   ThisVar(tomethod, this);

VarPointsTo(heap, this) distinct :-
   Reachable(inmethod),
   Instruction_Method(invocation, inmethod),
   SpecialMethodInvocation_Base(invocation, base),
   VarPointsTo(heap, base),
   MethodInvocation_Method(invocation, tomethod),
   ThisVar(tomethod, this);

/**
 * Implicitly reachable methods are invoked by the JVM on startup.
 */
Reachable(method) distinct :-
    ImplicitReachable(method);

/**
 * If a class needs to be initialized, then its class initializer is
 * invoked.
 *
 * Note that InitializedClass already deals with superclasses that
 * needs to be initialized as well, so we don't need to invoke class
 * initializers of the super class here.
 */
Reachable(clinit) distinct :-
   InitializedClass(class),
   ClassInitializer(class, clinit);

