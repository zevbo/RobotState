open! Core

type t [@@deriving sexp_of]

(** [empty] is a [t] with no data *)
val empty : t

(** [mem t sd] returns whether or not [t] has data stored for
   [sd]. O(log(n)) time complexity in size of [t]. *)
val mem : t -> 'a Sd.t -> bool

(** [memp t packed] returns whether or not [t] has data stored for
   [packed]. O(log(n)) time complexity in size of [t]. *)
val memp : t -> Sd.Packed.t -> bool

(** [find t sd] returns [Some] (the current binding) of [sd] in [t],
   or [None] if no such binding exists. O(log(n)) time complexity in
   size of [t]. *)
val find : t -> 'a Sd.t -> 'a option

(** [find_exn t sd] is an unsafe version of find *)
val find_exn : t -> 'a Sd.t -> 'a

(** [set t sd v] sets the given [sd] to [v]. O(log(n)) time complexity
   in size of [t]. *)
val set : t -> 'a Sd.t -> 'a -> t

(** [remove t sd] removes the current binding for [sd] if such binding
   exists. O(log(n)) time complexity in size of [t]. *)
val remove : t -> 'a Sd.t -> t

(** [remove t packed] removes the current binding for [packed] if such
   binding exists. O(log(n)) time complexity in size of [t]. *)
val removep : t -> Sd.Packed.t -> t

(** [use t1 ?to_use t2] calls [set t1 (get t2 sd)] for each [sd] where
   (a) there exists a binding in [t2] and (b) it is in [?to_use] or
   [?to_use] is [None]. O(m*log(n + m)) time complexity where n is the
   size of [t1] and m is the size of [t2]. *)
val use : t -> ?to_use:Sd.set option -> t -> t

val use_extras : t -> t -> t

(** [trim_to t sd_set] removes all [sd]s from [t] that are in [sd_set] *)
val trim_to : t -> Sd.set -> t

(** [keys t] returns a list of all [sd] for which there exists a
   binding in [t]. O(n) time complexity in size of [t]. *)
val keys : t -> Sd.set
