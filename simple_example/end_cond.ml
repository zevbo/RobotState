open Sd_logic
open Core
open Sd_func

let end_cond =
  let+ x = sd Sds.x in
  Float.(x > 100.)
;;