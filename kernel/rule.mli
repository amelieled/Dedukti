open Basic
open Term

(** Rewrite rules *)

(** {2 Patterns} *)

(** Basic representation of pattern *)
type pattern =
  | Var      of loc * ident * int * pattern list (** Applied DB variable *)
  | Pattern  of loc * name * pattern list        (** Applied constant    *)
  | Lambda   of loc * ident * pattern            (** Lambda abstraction  *)
  | Brackets of term                             (** Bracket of a term   *)

val get_loc_pat : pattern -> loc

val pattern_to_term : pattern -> term

(** {2 Rewrite Rules} *)

type rule_name =
  | Beta
  | Delta of name
  (** Rules associated to the definition of a constant *)
  | Gamma of bool * name
  (** Rules of lambda pi modulo. The first parameter indicates whether
      the name of the rule has been given by the user. *)

val rule_name_eq : rule_name -> rule_name -> bool

type 'a rule =
  {
    name: rule_name;
    ctx : 'a context;
    pat : pattern;
    rhs : term
  }
(** A rule is formed with
    - a name
    - an annotated context
    - a left-hand side pattern
    - a right-hand side term
*)

val get_loc_rule : 'a rule -> loc

type untyped_rule = term option rule
(** Rule where context is partially annotated with types *)

type typed_rule = term rule
(** Rule where context is fully annotated with types *)

(** {2 Errors} *)

type rule_error =
  | BoundVariableExpected          of loc * pattern
  | DistinctBoundVariablesExpected of loc * ident
  | VariableBoundOutsideTheGuard   of loc * term
  | UnboundVariable                of loc * ident * pattern
  | AVariableIsNotAPattern         of loc * ident
  | NonLinearNonEqArguments        of loc * ident
  | NotEnoughArguments             of loc * ident * int * int * int
  | NonLinearRule                  of loc * rule_name

exception Rule_error of rule_error

(** {2 Printing} *)

val pp_rule_name       : rule_name       printer
val pp_untyped_rule    : 'a rule         printer
val pp_typed_rule      : typed_rule      printer
val pp_part_typed_rule : untyped_rule    printer
val pp_pattern         : pattern         printer
