open! Core

type t [@@deriving sexp_of]

(** [create ~max_length] creates a new [t] which stores at most [~max_length] states. *)
val create
  :  ?default_length:int
  -> ?sd_lengths:(Sd.Packed.t, int, Sd.Packed.comparator_witness) Map.t
  -> unit
  -> t

(** [get_state t i] returns [Some] of the [i]th most recent state from [t], or [None] if [t] doesn't have more than [i] states. O(log(n)) time complexity in length of [t]. *)
val nth_state : t -> int -> Robot_state.t option

(** [get_current_state t] is equivilant to [get_state 0]. O(1) time complexity. *)
val curr_state : t -> Robot_state.t

(** [add_state t state] adds [state] to [t]. O(log(n)) time complexity in length of [t]. *)
val add_empty_state : t -> t

val add_state : t -> Robot_state.t -> t

(** [use t state] replaces the current state with [Robot_state.use (curr_state t) state] *)
val use : t -> ?to_use:Sd.set option -> Robot_state.t -> t

val use_extras : t -> Robot_state.t -> t

(** [find t sd] is equivilant to [Robot_state.find (curr_state t) sd] *)
val find : t -> 'a Sd.t -> 'a option

val find_exn : t -> 'a Sd.t -> 'a

(** [find_past t n sd] is equivilant to [Robot_state.find (nth_state t n) sd] *)
val find_past : t -> int -> 'a Sd.t -> 'a option

val find_past_def : t -> default:'a -> int -> 'a Sd.t -> 'a
val find_past_last_def : t -> int -> 'a Sd.t -> 'a option

(** [mem t sd] is equivilant to [Robot_state.mem (curr_state t) sd] *)
val mem : t -> 'a Sd.t -> bool

(** [mem_past t n sd] is equivilant to [Robot_state.mem (nth_state t n) sd] *)
val mem_past : t -> int -> 'a Sd.t -> bool option

(** [memp t sd] is equivilant to [Robot_state.memp (curr_state t) sd] *)
val memp : t -> Sd.Packed.t -> bool

(** [memp_past t n sd] is equivilant to [Robot_state.memp (nth_state t n) sd] *)
val memp_past : t -> int -> Sd.Packed.t -> bool option

(** [max_length t] returns the maximum length of [t]. O(1) time complexity. *)
val max_length : t -> int

(** [length t] returns the length of [t]. O(n) time complexity in the length of [t]. *)
val length : t -> int
