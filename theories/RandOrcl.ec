require import Int.
require import Fun.
require import Map. import OptionGet.

type from.
type to.

op dsample : to distr. (* Distribution to use on the target type *)
op qO : int.           (* Maximum number of calls by the adversary *)
op default : to.       (* Default element to return on error by wrapper *)

(* A signature for random oracles from "from" to "to". *)
module type Oracle =
{
  fun init():unit
  fun o(x:from):to
}.

module type ARO = { fun o(x:from):to }.

theory ROM.
  (* Bare random oracle for use in schemes *)
  module RO:Oracle = {
    var m : (from, to) map

    fun init() : unit = {
      m = empty;
    }
  
    fun o(x:from) : to = {
      var y : to;
      y = $dsample;
      if (!in_dom x m) m.[x] = y;
      return proj (m.[x]);
    }
  }.

  lemma lossless_init : islossless RO.init.
  proof. fun;wp;skip;trivial. qed.

  lemma lossless_o : mu dsample cpTrue = 1%r => islossless RO.o.
  proof. 
   intros Hs;fun;wp;simplify. 
   rnd 1%r cpTrue;skip; first by trivial.
   by apply Hs.
  qed.

end ROM.

(* Wrappers for use by an adversary:
     - counting requests,
     - tracking the set of requests,
     - tracking the sequence of requests *)
theory WRO_Int.
  module ARO(R:Oracle):Oracle = {
    var log:int

    fun init():unit = {
      R.init();
      log = 0;
    }

    fun o(x:from): to = {
      var r:to;
      if (log < qO)
      {
        log = log + 1;
        r = R.o(x);
      }
      else
        r = default;
      return r;
    }
  }.
  
end WRO_Int.

theory WRO_Set.
  require import Set.
  module ARO(R:Oracle):Oracle = {
    var log:from set

    fun init():unit = {
      R.init();
      log = Set.empty;
    }

    fun o(x:from): to = {
      var r:to;
      if (card log < qO)
      {
        log = add x log;
        r = R.o(x);
      }
      else
        r = default;
      return r;
    }
  }.

  lemma lossless_init : 
     forall (R<:Oracle), islossless R.init =>
      bd_hoare [ ARO(R).init : true ==> true] = 1%r.  (* islossless ARO(R).init : parse error*) 
  proof. intros R HR;fun;wp;call HR;skip;by trivial. qed.

  lemma lossless_o : 
     forall (R<:Oracle), islossless R.o =>
      bd_hoare [ ARO(R).o : true ==> true] = 1%r.  
  proof. 
    intros R HR;fun;wp.
    if.
      call HR;wp;skip;by trivial.
    wp;skip;by trivial.
  save.

  lemma RO_lossless_init : islossless ARO(ROM.RO).init.
  proof. apply (lossless_init ROM.RO);apply ROM.lossless_init. qed.

  lemma RO_lossless_o : mu dsample cpTrue = 1%r => islossless ARO(ROM.RO).o.
  proof. intros Hs;apply (lossless_o ROM.RO);apply ROM.lossless_o;apply Hs. qed.

end WRO_Set.

theory WRO_List.
  require import List.
  module ARO(R:Oracle):Oracle = {
    var log:from list

    fun init():unit = {
      R.init();
      log = [];
    }

    fun o(x:from): to = {
      var r:to;
      if (length log < qO)
      {
        log = x :: log;
        r = R.o(x);
      }
      else
        r = default;
      return r;
    }
  }.
end WRO_List.

theory IND_RO.
  module type ARO = { fun o(x:from): to }.
  module type RO_adv(X:ARO) = { fun a(): bool }.

  module IND_RO(R:Oracle,A:RO_adv) = {
    module Adv = A(R)

    fun main(): bool = {
      var b:bool;
      R.init();
      b = Adv.a();
      return b;
    }
  }.
end IND_RO.