type t
type safety

val create_safety
  :  ?default:Safety_level.t
  -> ?premature_sd_req:Safety_level.t
  -> ?overwritten_sd:Safety_level.t
  -> ?never_written_sd_req:Safety_level.t
  -> ?node_safety:Sd_est.safety
  -> unit
  -> safety

(** safety defaults to maximum safety *)
val create : ?end_cond:bool Sd_func.t -> Sd_est.t list -> t

val rsh : t -> Rsh.t

(* max_ticks = -1 -> no max *)
val run : ?no_end_cond:bool -> ?min_ms:float -> ?max_ticks:int -> t -> unit
val tick : t -> t

exception Premature_sd_req of Sd.Packed.t [@@deriving sexp]
exception Overwriting_sd_estimate of Sd.Packed.t [@@deriving sexp]
exception Never_written_req of Sd.Packed.t [@@deriving sexp]