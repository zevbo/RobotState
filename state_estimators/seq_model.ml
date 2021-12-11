open! Core
open! Src

type safety =
  | Safe
  | Warnings
  | Unsafe

type t =
  { estimators : Est.t list
  ; safety : safety
  }

let packed_to_str packed = String.t_of_sexp (Sd.Packed.sexp_of_t packed)

let key_dependencies logic =
  let dep = Sd_lang.dependencies logic in
  let curr_dep = Map.filter dep ~f:(fun n -> n = 0) in
  Map.key_set curr_dep
;;

let apply (state_history : Robot_state_history.t) t =
  List.fold_left t.estimators ~init:state_history ~f:(fun state_history est ->
      let est_safety =
        match t.safety with
        | Unsafe -> Est.Unsafe
        | Warnings -> Est.Warnings
        | Safe -> Est.Safe
      in
      let estimated_state = Est.execute ~safety:est_safety est state_history in
      Robot_state_history.use state_history estimated_state)
;;

exception Premature_sd_req of Sd.Packed.t
exception Overwriting_sd_estimate of Sd.Packed.t
exception Never_written_req of Sd.Packed.t

type check_failure =
  | Premature
  | Overwrite
  | Never_written

type check_status =
  | Passed
  | Failure of check_failure * Sd.Packed.t

let hash_set_mutable_union h1 h2 = Hash_set.iter h2 ~f:(fun key -> Hash_set.add h1 key)

let current_check (t : t) =
  List.fold_until
    ~init:(Set.empty (module Sd.Packed))
    ~f:(fun guaranteed t ->
      let required, estimating = key_dependencies t.logic, t.sds_estimating in
      let premature_sd = Set.find required ~f:(fun sd -> not (Set.mem guaranteed sd)) in
      let overwritten_sd = Set.find estimating ~f:(Set.mem guaranteed) in
      match premature_sd, overwritten_sd with
      | Some premature_sd, _ ->
        print_endline (String.t_of_sexp (Sd.Packed.sexp_of_t premature_sd));
        Continue_or_stop.Stop (Failure (Premature, premature_sd))
      | None, Some overwritten_sd ->
        Continue_or_stop.Stop (Failure (Overwrite, overwritten_sd))
      | None, None -> Continue_or_stop.Continue (Set.union guaranteed estimating))
    ~finish:(fun _ -> Passed)
    t.estimators
;;

let past_check t =
  let full_estimating =
    List.fold_left
      t.estimators
      ~init:(Set.empty (module Sd.Packed)) (* zTODO: fix to better Set.union *)
      ~f:(fun full_estimating t -> Set.union full_estimating t.sds_estimating)
  in
  let non_guranteed set = Set.find set ~f:(fun sd -> not (Set.mem full_estimating sd)) in
  match List.find_map t.estimators ~f:(fun est -> non_guranteed est.sds_estimating) with
  | None -> Passed
  | Some sd -> Failure (Never_written, sd)
;;

let check t =
  let current_check = current_check t in
  (* todo: add past check as well *)
  match current_check with
  | Passed -> past_check t
  | status -> status
;;

let create ?(safety = Safe) estimators =
  let model = { safety; estimators } in
  match safety with
  | Unsafe -> model
  | Safe ->
    (match check model with
    | Passed -> model
    | Failure (Premature, sd) -> raise (Premature_sd_req sd)
    | Failure (Overwrite, sd) -> raise (Overwriting_sd_estimate sd)
    | Failure (Never_written, sd) -> raise (Never_written_req sd))
  | Warnings ->
    (match check model with
    | Passed -> model
    | Failure (error, sd) ->
      let warning =
        match error with
        | Premature -> "premature require"
        | Overwrite -> "possible overwrite"
        | Never_written -> "unestimated past require"
      in
      printf "Est.Applicable warning: Detected %s of sd %s\n" warning (packed_to_str sd);
      model)
;;

let sd_lengths t =
  let max_indecies =
    List.fold
      t.estimators
      ~init:(Map.empty (module Sd.Packed))
      ~f:(fun sd_lengths est ->
        Map.merge_skewed
          sd_lengths
          (Sd_lang.dependencies est.logic)
          ~combine:(fun ~key:_key -> Int.max))
  in
  Map.map max_indecies ~f:(fun n -> n + 1)
;;
