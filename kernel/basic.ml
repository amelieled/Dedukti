(** Basic Datatypes *)

(** {2 Identifiers (hashconsed strings)} *)

type ident = string

let string_of_ident s = s

let ident_eq s1 s2 = s1 == s2 || s1 = s2

type mident = string

let string_of_mident s = s

let mident_eq = ident_eq

type name = mident * ident

let mk_name md id = (md, id)

let name_eq (m, s) (m', s') = mident_eq m m' && ident_eq s s'

let md = fst

let id = snd

module WS = Weak.Make (struct
  type t = ident

  let equal = ident_eq

  let hash = Hashtbl.hash
end)

let hash_ident = WS.create 251

let mk_ident = WS.merge hash_ident

let hash_mident = WS.create 251

let mk_mident md = WS.merge hash_mident md

let dmark = mk_ident "$"

module IdentSet = Set.Make (struct
  type t = ident

  let compare = compare
end)

module MidentSet = Set.Make (struct
  type t = mident

  let compare = compare
end)

module NameSet = Set.Make (struct
  type t = name

  let compare = compare
end)

(** {2 Lists with Length} *)

module LList = struct
  type 'a t = {len : int; lst : 'a list}

  let nil = {len = 0; lst = []}

  let cons x {len; lst} = {len = len + 1; lst = x :: lst}

  let len x = x.len

  let lst x = x.lst

  let is_empty x = x.len = 0

  let of_list lst = {len = List.length lst; lst}

  let of_array arr = {len = Array.length arr; lst = Array.to_list arr}

  let map f {len; lst} = {len; lst = List.map f lst}

  let mapi f {len; lst} = {len; lst = List.mapi f lst}

  let nth l i =
    assert (i < l.len);
    List.nth l.lst i
end

(** {2 Localization} *)

type loc = int * int

let dloc = (-1, -1)

let mk_loc l c = (l, c)

let of_loc l = l

(** {2 Debugging} *)

module Debug = struct
  type flag = string * bool ref

  let new_flag v m = (m, ref v)

  let set value (_, fl) = fl := value

  let register_flag = new_flag false

  let enable_flag = set true

  let disable_flag = set false

  let do_debug fmt =
    Format.(
      kfprintf
        (fun _ ->
          pp_print_newline err_formatter ();
          pp_print_flush err_formatter ())
        err_formatter fmt)

  let ignore_debug fmt = Format.(ifprintf err_formatter) fmt

  let debug (msg, fl) =
    if !fl then fun fmt -> do_debug ("[%s] " ^^ fmt) msg else ignore_debug
    [@@inline]

  let debug_eval (_, fl) clos = if !fl then clos ()

  let d_warn = new_flag true "Warning"

  let d_notice = new_flag false "Notice"
end

(** {2 Misc functions} *)

let bind_opt f = function None -> None | Some x -> f x

let map_opt f = function None -> None | Some x -> Some (f x)

let fold_map (f : 'b -> 'a -> 'c * 'b) (b0 : 'b) (alst : 'a list) : 'c list * 'b
    =
  let clst, b2 =
    List.fold_left
      (fun (accu, b1) a ->
        let c, b2 = f b1 a in
        (c :: accu, b2))
      ([], b0) alst
  in
  (List.rev clst, b2)

let split x =
  let rec aux acc n l =
    if n <= 0 then (List.rev acc, l)
    else aux (List.hd l :: acc) (n - 1) (List.tl l)
  in
  aux [] x

let rev_mapi f l =
  let rec rmap_f i accu = function
    | []     -> accu
    | a :: l -> rmap_f (i + 1) (f i a :: accu) l
  in
  rmap_f 0 [] l

let concat l1 = function [] -> l1 | l2 -> l1 @ l2

(** {2 Printing functions} *)

type 'a printer = Format.formatter -> 'a -> unit

let string_of fp = Format.asprintf "%a" fp

let pp_ident fmt id = Format.fprintf fmt "%s" id

let pp_mident fmt md = Format.fprintf fmt "%s" md

let pp_name fmt (md, id) = Format.fprintf fmt "%a.%a" pp_mident md pp_ident id

let pp_loc fmt = function
  | -1, -1 -> Format.fprintf fmt "unspecified location"
  | l, -1  -> Format.fprintf fmt "line:%i" l
  | l, c   -> Format.fprintf fmt "line:%i column:%i" l c

let format_of_sep str fmt () : unit = Format.fprintf fmt "%s" str

let pp_list sep pp fmt l =
  Format.pp_print_list ~pp_sep:(format_of_sep sep) pp fmt l

let pp_llist sep pp fmt l = pp_list sep pp fmt (LList.lst l)

let pp_arr sep pp fmt a = pp_list sep pp fmt (Array.to_list a)

let pp_lazy pp fmt l = Format.fprintf fmt "%a" pp (Lazy.force l)

let pp_option def pp fmt = function
  | None   -> Format.fprintf fmt "%s" def
  | Some a -> Format.fprintf fmt "%a" pp a

let pp_pair pp_fst pp_snd fmt x =
  Format.fprintf fmt "(%a, %a)" pp_fst (fst x) pp_snd (snd x)

let pp_triple pp_fst pp_snd pp_thd fmt (x, y, z) =
  Format.fprintf fmt "(%a, %a, %a)" pp_fst x pp_snd y pp_thd z
