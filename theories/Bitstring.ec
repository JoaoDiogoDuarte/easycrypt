require        Distr.
require        Bool.
require import Int.
require        Array.

(* We make a clone of the array theory so we
   can further restrict to fixed size arrays. *)
clone Array as Bits.
export Bits.

type bitstring = bool array.

(* Conversions for interaction with other array types *)
op to_array: bitstring -> bool Array.array.

axiom to_array_length: forall bs,
  Array.length (to_array bs) = length bs.

axiom to_array_get: forall bs i,
  0 <= i => i < length bs =>
  Array.__get (to_array bs) i = bs.[i].

op from_array: bool Array.array -> bitstring.

axiom from_array_length: forall bs,
  length (from_array bs) = Array.length bs.

axiom from_array_get: forall bs i,
  0 <= i => i < Array.length bs =>
  (from_array bs).[i] = Array.__get bs i.

lemma to_array_from_array: forall bs,
  from_array (to_array bs) = bs.
proof.
intros bs;
  apply (extensionality<:bool> (from_array (to_array bs)) bs _);
  trivial.
save.

lemma from_array_to_array: forall bs,
  to_array (from_array bs) = bs.
proof.
intros bs;
  apply (Array.extensionality<:bool> (to_array (from_array bs)) bs _);
  trivial.
save.

(* Xor *)
op (^^)(bs0 bs1:bitstring): bitstring = map2 Bool.xorb bs0 bs1.

lemma xor_length: forall (bs0 bs1:bitstring),
  length bs0 = length bs1 =>
  length (bs0 ^^ bs1) = length bs0
by [].

lemma xor_get: forall (bs0 bs1:bitstring) (i:int),
  length bs0 = length bs1 =>
  0 <= i => i < length bs0 =>
  (bs0 ^^ bs1).[i] = Bool.xorb bs0.[i] bs1.[i]
by [].

(* Zero for bitstrings *)
op zeros: int -> bitstring.

axiom zeros_length: forall (l:int),
  0 <= l =>
  length (zeros l) = l.

axiom zeros_get: forall (l i:int),
  0 <= l => 0 <= i => i < l =>
  (zeros l).[i] = false.

(* Lemmas *)
lemma xor_nilpotent: forall (bs:bitstring),
  bs ^^ bs = zeros (length bs).
proof.
intros bs;
  apply (extensionality<:bool> (bs ^^ bs) (zeros (length bs)) _);
  trivial.
save.

lemma xor_assoc : forall (x y z : bitstring), 
length(x) = length(y) => length(y) = length(z) =>
 (x ^^ y) ^^ z = x ^^ (y ^^ z).
proof.
 intros x y z Hleq1 Hleq2.
 apply (extensionality<:bool>  ((x ^^ y) ^^ z) (x ^^ (y ^^ z)) _).
 delta (==);simplify.
 split;try trivial.
 delta (^^);simplify.
 intros i H H0.
 rewrite (map2_get<:bool,bool,bool> (map2 Bool.xorb x y) z Bool.xorb i _ _ _);
try trivial.
 rewrite (map2_get<:bool,bool,bool> x y Bool.xorb i _ _ _);
try trivial.
 rewrite (map2_get<:bool,bool,bool> x (map2 Bool.xorb y z)  Bool.xorb i _ _ _);
try trivial.
save.

lemma xor_zeroes_neutral : forall (x : bitstring),
x ^^ zeros(length(x)) = x.
proof.
 intros x.
 apply (extensionality<:bool> (x^^ zeros(length x)) x _).
 trivial.
save.

require import Real.
require import Distr.

(* Uniform distributions on length-parametric bitstrings *)
theory Dbitstring.
  op dbitstring: int -> bitstring distr.

  axiom supp_def: forall (k:int, s:bitstring),
    in_supp s (dbitstring k) <=> length s = k.

  axiom mu_x_def_in: forall (k:int, s:bitstring),
    length s = k => mu_x (dbitstring k) s = 1%r/(2^k)%r.

  axiom mu_x_def_other: forall (k:int, s:bitstring),
    length s <> k => mu_x (dbitstring k) s = 0%r.

  axiom mu_weight_pos: forall (k:int), 0 <= k =>
    mu_weight (dbitstring k) = 1%r.

  axiom mu_weight_neg: forall (k:int), k < 0 =>
    mu_weight (dbitstring k) = 0%r.
end Dbitstring.
