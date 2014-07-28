open Types

type action = All | NonLinear | TypeLevel | PiRule | Export
let action = ref All

let args = [
  ("--all",        Arg.Unit (fun _ -> action := All),       "Print all rules" ) ;
  ("-non-linear",  Arg.Unit (fun _ -> action := NonLinear), "Print non-linear rules" ) ;
  ("--type-level", Arg.Unit (fun _ -> action := TypeLevel), "Print type-level rules" ) ;
  ("--pi-rule",    Arg.Unit (fun _ -> action := PiRule),    "Print Pi rules" ) ;
  ("--export",     Arg.Unit (fun _ -> action := Export),    "Export to TPDB format" ) ]

let run md =
  let rs = Dko.get_rules md in
    match !action with
      | All -> Rules.print_all rs
      | NonLinear -> Rules.print_non_linear_rules rs
      | TypeLevel -> Rules.print_type_level_rules rs
      | PiRule -> Rules.print_pi_rules rs
      | Export -> Tpdb.export rs

let _ =
  try Arg.parse args run ("Usage: "^ Sys.argv.(0) ^" [options] files");
  with Sys_error err -> ( Printf.eprintf "ERROR %s.\n" err; exit 1 )
