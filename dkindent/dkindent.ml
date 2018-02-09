open Basic
open Cmd
open Pp

module T = struct
  let mk_prelude _ i =
    Env.init i;
    Format.printf "#NAME %a.@.@." print_mident i

  let mk_declaration _ i st ty =
    let st_str = match st with
      | Signature.Static -> ""
      | Signature.Definable -> "def "
    in
    Format.printf "@[<2>%s%a :@ %a.@]@.@." st_str print_ident i print_term ty

  let mk_definition _ i ty t = match ty with
    | None -> Format.printf "@[<hv2>def %a@ :=@ %a.@]@.@." print_ident i print_term t
    | Some ty ->
        Format.printf "@[<hv2>def %a :@ %a@ :=@ %a.@]@.@."
          print_ident i print_term ty print_term t

  let mk_opaque _ i ty t = match ty with
    | None -> Format.printf "@[<hv2>{%a}@ :=@ %a.@]@.@." print_ident i print_term t
    | Some ty ->
        Format.printf "@[<hv2>{%a}@ :@ %a :=@ %a.@]@.@."
          print_ident i print_term ty print_term t

  let mk_rules l =
    Format.printf "@[<v0>%a@].@.@." (print_list "" print_untyped_rule) l

  let mk_command _ cmd =
    match cmd with
    | Whnf te         -> Format.printf "#WHNF@ %a." print_term te
    | Hnf te          -> Format.printf "#HNF@ %a." print_term te
    | Snf te          -> Format.printf "#SNF@ %a." print_term te
    | OneStep te      -> Format.printf "#STEP@ %a." print_term te
    | NSteps (n,te)   -> Format.printf "#NSTEPS@ #%i@ %a." n print_term te
    | Conv (exp,ass,t1,t2) when exp && (not ass)
      -> Format.printf "#CHECK@ %a==@ %a."
           print_term t1 print_term t2
    | Conv (exp,ass,t1,t2) when (not exp) && (not ass)
      -> Format.printf "#CHECKNOT@ %a==@ %a."
           print_term t1 print_term t2
    | Inhabit (exp,ass,te,ty) when exp && (not ass)
      -> Format.printf "#CHECK@ %a::@ %a."
           print_term te print_term ty
    | Inhabit (exp,ass,te,ty) when (not exp) && (not ass)
      -> Format.printf "#CHECKNOT@ %a::@ %a."
           print_term te print_term ty
    | Conv (exp,ass,t1,t2) when exp && ass
      -> Format.printf "#ASSERT@ %a==@ %a."
           print_term t1 print_term t2
    | Conv (exp,ass,t1,t2) when (not exp) && ass
      -> Format.printf "#ASSERTNOT@ %a==@ %a."
           print_term t1 print_term t2
    | Inhabit (exp,ass,te,ty) when exp && ass
      -> Format.printf "#ASSERT@ %a::@ %a."
           print_term te print_term ty
    | Inhabit (exp,ass,te,ty) when (not exp) && ass
      -> Format.printf "#ASSERTNOT@ %a::@ %a."
           print_term te print_term ty
    | Inhabit (_,_,_,_)-> assert false
    | Conv (_,_,_,_)   -> assert false
    | Infer te        -> Format.printf "#INFER@ %a." print_term te
    | InferSnf te     -> Format.printf "#INFERSNF@ %a." print_term te
    | Require md      -> Format.printf "#NAME %a.@.@." print_mident md
    | Gdt (m0,v)      ->
      begin match m0 with
        | None -> Format.printf "#GDT@ %a." print_ident v
        | Some m -> Format.printf "#GDT@ %a.%a." print_mident m print_ident v
      end
    | Print str         -> Format.printf "#PRINT \"%s\"." str
    | Other (cmd,_)     -> failwith (Format.sprintf "Unknown command '%s'.\n" cmd)

  let mk_ending _ = ()
end

module P = Parser.Make(T)

let parse lb =
  try
    P.prelude Lexer.token lb ;
    while true do P.line Lexer.token lb done
  with
    | Lexer.EndOfFile -> ()
    | P.Error       -> Errors.fail (Lexer.get_loc lb)
                         "Unexpected token '%s'." (Lexing.lexeme lb)

let process_chan ic = parse (Lexing.from_channel ic)
let process_file name =
  (* Print.debug "Processing file %s\n" name; *)
  let ic = open_in name in
  process_chan ic;
  close_in ic

let from_stdin = ref false
let files = ref []
let add_file f = files := f :: !files

let options =
  [ "-stdin", Arg.Set from_stdin, " read from stdin";
    "-default-rule", Arg.Set print_default, "print default name for rules without name"
  ]

let  _ =
  Arg.parse options add_file "usage: dkindent file [file...]";
  if !from_stdin
    then process_chan stdin
    else List.iter process_file (List.rev !files)
