open! Core
open Src

module type Model = sig
  type t

  val apply : Rsh.t -> t -> Rsh.t
  val sd_lengths : t -> (Sd.Packed.t, int, Sd.Packed.comparator_witness) Map.t
end

(* zTODO: maybe add some form of delay? *)
module M (Model : Model) = struct
  type t =
    { model : Model.t
    ; execution : unit Sd_lang.t (* zTODO: max_length should be inferred *)
    ; rsh : Rsh.t
    }

  let create model execution =
    { model; execution; rsh = Rsh.create ~sd_lengths:(Model.sd_lengths model) () }
  ;;

  let tick t =
    let rsh = Model.apply t.rsh t.model in
    Sd_lang.execute rsh t.execution;
    let rsh = Rsh.add_empty_state rsh in
    { t with rsh }
  ;;

  let rec run t ~ticks =
    match ticks with
    | None -> run (tick t) ~ticks
    | Some 0 -> ()
    | Some n -> run (tick t) ~ticks:(Some (n - 1))
  ;;
end