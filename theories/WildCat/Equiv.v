(* -*- mode: coq; mode: visual-line -*-  *)

Require Import Basics.Utf8 Basics.Overture Basics.Tactics Basics.Equivalences.
Require Import WildCat.Core.

(** We declare a scope for printing [CatEquiv] as [≅] *)
Declare Scope wc_iso_scope.

(** * Equivalences in wild categories *)

(** We could define equivalences in any wild 1-category as bi-invertible maps, or in a wild 2-category as half-adjoint equivalences.  However, in concrete cases there is often an equivalent definition of equivalences that we want to use instead, and the important property we need is that it's logically equivalent to (quasi-)isomorphism. In [cat_hasequivs] below, we show that bi-invertible maps do provide a [HasEquivs] structure for any wild 1-category. *)

Class HasEquivs (A : Type) `{Is1Cat A} :=
{
  CatEquiv' : A -> A -> Type where "a $<~> b" := (CatEquiv' a b);
  CatIsEquiv' : forall a b, (a $-> b) -> Type;
  cate_fun' : forall a b, (a $<~> b) -> (a $-> b);
  cate_isequiv' : forall a b (f : a $<~> b), CatIsEquiv' a b (cate_fun' a b f);
  cate_buildequiv' : forall a b (f : a $-> b), CatIsEquiv' a b f -> CatEquiv' a b;
  cate_buildequiv_fun' : forall a b (f : a $-> b) (fe : CatIsEquiv' a b f),
      cate_fun' a b (cate_buildequiv' a b f fe) $== f;
  cate_inv' : forall a b (f : a $<~> b), b $-> a;
  cate_issect' : forall a b (f : a $<~> b),
    cate_inv' _ _ f $o cate_fun' _ _ f $== Id a;
  cate_isretr' : forall a b (f : a $<~> b),
      cate_fun' _ _ f $o cate_inv' _ _ f $== Id b;
  catie_adjointify' : forall a b (f : a $-> b) (g : b $-> a)
    (r : f $o g $== Id b) (s : g $o f $== Id a), CatIsEquiv' a b f;
}.

(** Since apparently a field of a record can't be the source of a coercion (Coq complains about the uniform inheritance condition, although as officially stated that condition appears to be satisfied), we redefine all the fields of [HasEquivs]. *)

Definition CatEquiv {A} `{HasEquivs A} (a b : A)
  := @CatEquiv' A _ _ _ _ _ a b.

Notation "a $<~> b" := (CatEquiv a b).
Infix "≅" := CatEquiv : wc_iso_scope.
Arguments CatEquiv : simpl never.

Definition cate_fun {A} `{HasEquivs A} {a b : A} (f : a $<~> b)
  : a $-> b
  := @cate_fun' A _ _ _ _ _ a b f.

Coercion cate_fun : CatEquiv >-> Hom.

(* Being an equivalence should be a typeclass, but we have to redefine it to work around https://github.com/coq/coq/issues/8994 . *)
Class CatIsEquiv {A} `{HasEquivs A} {a b : A} (f : a $-> b)
  := catisequiv : CatIsEquiv' a b f.

Global Instance cate_isequiv {A} `{HasEquivs A} {a b : A} (f : a $<~> b)
  : CatIsEquiv f
  := cate_isequiv' a b f.

Definition Build_CatEquiv {A} `{HasEquivs A} {a b : A}
           (f : a $-> b) {fe : CatIsEquiv f}
  : a $<~> b
  := cate_buildequiv' a b f fe.

Definition cate_buildequiv_fun {A} `{HasEquivs A} {a b : A}
           (f : a $-> b) {fe : CatIsEquiv f}
  : cate_fun (Build_CatEquiv f) $== f
  := cate_buildequiv_fun' a b f fe.

Definition catie_adjointify {A} `{HasEquivs A} {a b : A}
           (f : a $-> b) (g : b $-> a)
           (r : f $o g $== Id b) (s : g $o f $== Id a)
  : CatIsEquiv f
  := catie_adjointify' a b f g r s.

Definition cate_adjointify {A} `{HasEquivs A} {a b : A}
           (f : a $-> b) (g : b $-> a)
           (r : f $o g $== Id b) (s : g $o f $== Id a)
  : a $<~> b
  := Build_CatEquiv f (fe:=catie_adjointify f g r s).

(** This one we define to construct the whole inverse equivalence. *)
Definition cate_inv {A} `{HasEquivs A} {a b : A} (f : a $<~> b) : b $<~> a.
Proof.
  simple refine (cate_adjointify _ _ _ _).
  - exact (cate_inv' a b f).
  - exact f.
  - exact (cate_issect' a b f).
  - exact (cate_isretr' a b f).
Defined.

Notation "f ^-1$" := (cate_inv f).

Definition cate_issect {A} `{HasEquivs A} {a b} (f : a $<~> b) 
  : f^-1$ $o f $== Id a.
Proof.
  refine (_ $@ cate_issect' a b f).
  refine (_ $@R f).
  apply cate_buildequiv_fun'.
Defined.

Definition cate_isretr {A} `{HasEquivs A} {a b} (f : a $<~> b)
  : f $o f^-1$ $== Id b.
Proof.
  refine (_ $@ cate_isretr' a b f).
  refine (f $@L _).
  apply cate_buildequiv_fun'.
Defined.

(** If [g] is a section of an equivalence, then it is the inverse. *)
Definition cate_inverse_sect {A} `{HasEquivs A} {a b} (f : a $<~> b)
  (g : b $-> a) (p : f $o g $== Id b)
  : cate_fun f^-1$ $== g.
Proof.
  refine ((cat_idr _)^$ $@ _).
  refine ((_ $@L p^$) $@ _).
  refine (cat_assoc_opp _ _ _ $@ _).
  refine (cate_issect f $@R _ $@ _).
  apply cat_idl.
Defined.

(** If [g] is a retraction of an equivalence, then it is the inverse. *)
Definition cate_inverse_retr {A} `{HasEquivs A} {a b} (f : a $<~> b)
  (g : b $-> a) (p : g $o f $== Id a)
  : cate_fun f^-1$ $== g.
Proof.
  refine ((cat_idl _)^$ $@ _).
  refine ((p^$ $@R _) $@ _).
  refine (cat_assoc _ _ _ $@ _).
  refine (_ $@L cate_isretr f $@ _).
  apply cat_idr.
Defined.

(** It follows that the inverse of the equivalence you get by adjointification is homotopic to the inverse [g] provided. *)
Definition cate_inv_adjointify {A} `{HasEquivs A} {a b : A}
  (f : a $-> b) (g : b $-> a) (r : f $o g $== Id b) (s : g $o f $== Id a)
  : cate_fun (cate_adjointify f g r s)^-1$ $== g.
Proof.
  apply cate_inverse_sect.
  exact ((cate_buildequiv_fun f $@R _) $@ r).
Defined.

(** The identity morphism is an equivalence *)
Global Instance catie_id {A} `{HasEquivs A} (a : A)
  : CatIsEquiv (Id a)
  := catie_adjointify (Id a) (Id a) (cat_idl (Id a)) (cat_idl (Id a)).

Definition id_cate {A} `{HasEquivs A} (a : A)
  : a $<~> a
  := Build_CatEquiv (Id a).

Global Instance reflexive_cate {A} `{HasEquivs A}
  : Reflexive (@CatEquiv A _ _ _ _ _)
  := id_cate.

Global Instance symmetric_cate {A} `{HasEquivs A}
  : Symmetric (@CatEquiv A _ _ _ _ _)
  := fun a b f => cate_inv f.

(** Equivalences can be composed. *)
Global Instance compose_catie {A} `{HasEquivs A} {a b c : A}
  (g : b $<~> c) (f : a $<~> b)
  : CatIsEquiv (g $o f).
Proof.
  refine (catie_adjointify _ (f^-1$ $o g^-1$) _ _).
  - refine (cat_assoc _ _ _ $@ _).
    refine ((_ $@L cat_assoc_opp _ _ _) $@ _).
    refine ((_ $@L (cate_isretr _ $@R _)) $@ _).
    refine ((_ $@L cat_idl _) $@ _).
    apply cate_isretr.
  - refine (cat_assoc _ _ _ $@ _).
    refine ((_ $@L cat_assoc_opp _ _ _) $@ _).
    refine ((_ $@L (cate_issect _ $@R _)) $@ _).
    refine ((_ $@L cat_idl _) $@ _).
    apply cate_issect.
Defined.

Definition compose_cate {A} `{HasEquivs A} {a b c : A}
  (g : b $<~> c) (f : a $<~> b) : a $<~> c
  := Build_CatEquiv (g $o f).

Notation "g $oE f" := (compose_cate g f).

Definition compose_cate_fun {A} `{HasEquivs A}
           {a b c : A} (g : b $<~> c) (f : a $<~> b)
  : cate_fun (g $oE f) $== g $o f.
Proof.
  apply cate_buildequiv_fun.
Defined.

Definition compose_cate_funinv {A} `{HasEquivs A}
           {a b c : A} (g : b $<~> c) (f : a $<~> b)
  : g $o f $== cate_fun (g $oE f).
Proof.
  apply gpd_rev.
  apply cate_buildequiv_fun.
Defined.

Definition id_cate_fun {A} `{HasEquivs A} (a : A) 
  : cate_fun (id_cate a) $== Id a.
Proof.
  apply cate_buildequiv_fun.
Defined.

Definition compose_cate_assoc {A} `{HasEquivs A}
           {a b c d : A} (f : a $<~> b) (g : b $<~> c) (h : c $<~> d)
  : cate_fun ((h $oE g) $oE f) $== cate_fun (h $oE (g $oE f)).
Proof.
  refine (compose_cate_fun _ f $@ _ $@ cat_assoc f g h $@ _ $@
                           compose_cate_funinv h _).
  - refine (compose_cate_fun h g $@R _).
  - refine (_ $@L compose_cate_funinv g f).
Defined.

Definition compose_cate_idl {A} `{HasEquivs A}
           {a b : A} (f : a $<~> b)
  : cate_fun (id_cate b $oE f) $== cate_fun f.
Proof.
  refine (compose_cate_fun _ f $@ _ $@ cat_idl f).
  refine (cate_buildequiv_fun _ $@R _).
Defined.

Definition compose_cate_idr {A} `{HasEquivs A}
           {a b : A} (f : a $<~> b)
  : cate_fun (f $oE id_cate a) $== cate_fun f.
Proof.
  refine (compose_cate_fun f _ $@ _ $@ cat_idr f).
  refine (_ $@L cate_buildequiv_fun _).
Defined.

Global Instance transitive_cate {A} `{HasEquivs A}
  : Transitive (@CatEquiv A _ _ _ _ _)
  := fun a b c f g => g $oE f.

(** Some more convenient equalities for equivalences. The naming scheme is similar to [PathGroupoids.v].*)

Definition compose_V_hh {A} `{HasEquivs A} {a b c : A} (f : b $<~> c) (g : a $-> b) :
  f^-1$ $o (f $o g) $== g :=
  (cat_assoc _ _ _)^$ $@ (cate_issect f $@R g) $@ cat_idl g.

Definition compose_h_Vh {A} `{HasEquivs A} {a b c : A} (f : c $<~> b) (g : a $-> b) :
  f $o (f^-1$ $o g) $== g :=
  (cat_assoc _ _ _)^$ $@ (cate_isretr f $@R g) $@ cat_idl g.

Definition compose_hh_V {A} `{HasEquivs A} {a b c : A} (f : b $-> c) (g : a $<~> b) :
  (f $o g) $o g^-1$ $== f :=
  cat_assoc _ _ _ $@ (f $@L cate_isretr g) $@ cat_idr f.

Definition compose_hV_h {A} `{HasEquivs A} {a b c : A} (f : b $-> c) (g : b $<~> a) :
  (f $o g^-1$) $o g $== f :=
  cat_assoc _ _ _ $@ (f $@L cate_issect g) $@ cat_idr f.

(** Equivalences are both monomorphisms and epimorphisms (but not the converse). *)

Definition cate_monic_equiv {A} `{HasEquivs A} {a b : A} (e : a $<~> b)
  : Monic e.
Proof.
  intros c f g p.
  refine ((compose_V_hh e _)^$ $@ _ $@ compose_V_hh e _).
  exact (_ $@L p).
Defined.

Definition cate_epic_equiv {A} `{HasEquivs A} {a b : A} (e : a $<~> b)
  : Epic e.
Proof.
  intros c f g p.
  refine ((compose_hh_V _ e)^$ $@ _ $@ compose_hh_V _ e).
  exact (p $@R _).
Defined.

(** Some lemmas for moving equivalences around.  Naming based on EquivGroupoids.v.  More could be added. *)

Definition cate_moveR_eM {A} `{HasEquivs A} {a b c : A} (e : b $<~> a) (f : b $<~> c) (g : a $<~> c)
  (p : cate_fun g $== f $o e^-1$)
  : g $o e $== f.
Proof.
  apply (cate_epic_equiv e^-1$).
  exact (compose_hh_V _ _ $@ p).
Defined.

Definition cate_moveR_Ve {A} `{HasEquivs A} {a b c : A} (e : b $<~> a) (f : b $<~> c) (g : c $<~> a)
  (p : cate_fun e $== g $o f)
  : g^-1$ $o e $== f.
Proof.
  apply (cate_monic_equiv g).
  exact (compose_h_Vh _ _ $@ p).
Defined.

Definition cate_moveL_V1 {A} `{HasEquivs A} {a b : A} {e : a $<~> b} (f : b $-> a)
  (p : e $o f $== Id _)
  : f $== cate_fun e^-1$.
Proof.
  apply (cate_monic_equiv e).
  exact (p $@ (cate_isretr e)^$).
Defined.

Definition cate_moveL_1V {A} `{HasEquivs A} {a b : A} {e : a $<~> b} (f : b $-> a)
  (p : f $o e $== Id _)
  : f $== cate_fun e^-1$.
Proof.
  apply (cate_epic_equiv e).
  exact (p $@ (cate_issect e)^$).
Defined.

Definition cate_moveR_V1 {A} `{HasEquivs A} {a b : A} {e : a $<~> b} (f : b $-> a)
  (p : Id _ $== e $o f)
  : cate_fun e^-1$ $== f.
Proof.
  apply (cate_monic_equiv e).
  exact (cate_isretr e $@ p).
Defined.

Definition cate_moveR_1V {A} `{HasEquivs A} {a b : A} {e : a $<~> b} (f : b $-> a)
  (p : Id _ $== f $o e)
  : cate_fun e^-1$ $== f.
Proof.
  apply (cate_epic_equiv e).
  exact (cate_issect e $@ p).
Defined.

(** Lemmas about the underlying map of an equivalence. *)

Definition cate_inv2 {A} `{HasEquivs A} {a b : A} {e f : a $<~> b} (p : cate_fun e $== cate_fun f)
  : cate_fun e^-1$ $== cate_fun f^-1$.
Proof.
  apply cate_moveL_V1.
  exact ((p^$ $@R _) $@ cate_isretr _).
Defined.

Definition cate_inv_compose {A} `{HasEquivs A} {a b c : A} (e : a $<~> b) (f : b $<~> c)
  : cate_fun (f $oE e)^-1$ $== cate_fun (e^-1$ $oE f^-1$).
Proof.
  refine (_ $@ (compose_cate_fun _ _)^$).
  apply cate_inv_adjointify.
Defined.

Definition cate_inv_V {A} `{HasEquivs A} {a b : A} (e : a $<~> b)
  : cate_fun (e^-1$)^-1$ $== cate_fun e.
Proof.
  apply cate_moveR_V1.
  symmetry; apply cate_issect.
Defined.

(** Any sufficiently coherent functor preserves equivalences.  *)
Global Instance iemap {A B : Type} `{HasEquivs A} `{HasEquivs B}
       (F : A -> B) `{!Is0Functor F, !Is1Functor F}
       {a b : A} (f : a $<~> b)
  : CatIsEquiv (fmap F f).
Proof.
  refine (catie_adjointify (fmap F f) (fmap F f^-1$) _ _).
  - refine ((fmap_comp F f^-1$ f)^$ $@ fmap2 F (cate_isretr _) $@ fmap_id F _).
  - refine ((fmap_comp F f f^-1$)^$ $@ fmap2 F (cate_issect _) $@ fmap_id F _).
Defined.

Definition emap {A B : Type} `{HasEquivs A} `{HasEquivs B}
           (F : A -> B) `{!Is0Functor F, !Is1Functor F}
           {a b : A} (f : a $<~> b)
  : F a $<~> F b
  := Build_CatEquiv (fmap F f).

Definition emap_id {A B : Type} `{HasEquivs A} `{HasEquivs B}
  (F : A -> B) `{!Is0Functor F, !Is1Functor F} {a : A}
  : cate_fun (emap F (id_cate a)) $== cate_fun (id_cate (F a)).
Proof.
  refine (cate_buildequiv_fun _ $@ _).
  refine (fmap2 F (id_cate_fun a) $@ _ $@ (id_cate_fun (F a))^$).
  rapply fmap_id.
Defined.

Definition emap_compose {A B : Type} `{HasEquivs A} `{HasEquivs B}
  (F : A -> B) `{!Is0Functor F, !Is1Functor F}
  {a b c : A} (f : a $<~> b) (g : b $<~> c)
  : cate_fun (emap F (g $oE f)) $== fmap F (cate_fun g) $o fmap F (cate_fun f).
Proof.
  refine (cate_buildequiv_fun _ $@ _).
  refine (fmap2 F (compose_cate_fun _ _) $@ _).
  rapply fmap_comp.
Defined.

(** A variant. *)
Definition emap_compose' {A B : Type} `{HasEquivs A} `{HasEquivs B}
  (F : A -> B) `{!Is0Functor F, !Is1Functor F}
  {a b c : A} (f : a $<~> b) (g : b $<~> c)
  : cate_fun (emap F (g $oE f)) $== cate_fun ((emap F g) $oE (emap F f)).
Proof.
  refine (emap_compose F f g $@ _).
  symmetry.
  refine (compose_cate_fun _ _ $@ _).
  exact (cate_buildequiv_fun _ $@@ cate_buildequiv_fun _).
Defined.

Definition emap_inv {A B : Type} `{HasEquivs A} `{HasEquivs B}
  (F : A -> B) `{!Is0Functor F, !Is1Functor F}
  {a b : A} (e : a $<~> b)
  : cate_fun (emap F e)^-1$ $== cate_fun (emap F e^-1$).
Proof.
  refine (cate_inv_adjointify _ _ _ _ $@ _).
  exact (cate_buildequiv_fun _)^$.
Defined.

(** When we have equivalences, we can define what it means for a category to be univalent. *)
Definition cat_equiv_path {A : Type} `{HasEquivs A} (a b : A)
  : (a = b) -> (a $<~> b).
Proof.
  intros []; reflexivity.
Defined.

Class IsUnivalent1Cat (A : Type) `{HasEquivs A}
  := { isequiv_cat_equiv_path : forall a b, IsEquiv (@cat_equiv_path A _ _ _ _ _ a b) }.
Global Existing Instance isequiv_cat_equiv_path.

Definition cat_path_equiv {A : Type} `{IsUnivalent1Cat A} (a b : A)
  : (a $<~> b) -> (a = b)
  := (cat_equiv_path a b)^-1.

(** ** Core of a 1-category *)

Record core (A : Type) := { uncore : A }.
Arguments uncore {A} c.
Arguments Build_core {A} a : rename.

Global Instance isgraph_core {A : Type} `{HasEquivs A}
  : IsGraph (core A).
Proof.
  srapply Build_IsGraph.
  intros a b ; exact (uncore a $<~> uncore b).
Defined.

Global Instance is01cat_core {A : Type} `{HasEquivs A}
  : Is01Cat (core A).
Proof.
  srapply Build_Is01Cat ; cbv.
  - intros; apply id_cate.
  - intros a b c ; apply compose_cate.
Defined.

Global Instance is2graph_core {A : Type} `{HasEquivs A}
  : Is2Graph (core A).
Proof.
  intros a b.
  apply Build_IsGraph.
  intros f g ; exact (cate_fun f $== cate_fun g).
Defined.

Global Instance is01cat_core_hom {A : Type} `{HasEquivs A} (a b : core A)
  : Is01Cat (a $-> b).
Proof.
  srapply Build_Is01Cat.
  - intro f; cbn; apply Id.
  - intros f g h; cbn; apply cat_comp.
Defined.

Global Instance is0gpd_core_hom {A : Type} `{HasEquivs A} (a b : core A)
  : Is0Gpd (a $-> b).
Proof.
  apply Build_Is0Gpd.
  intros f g ; cbv.
  apply gpd_rev.
Defined.

Global Instance is0functor_core_postcomp {A : Type} `{HasEquivs A}
       (a b c : core A) (h : b $-> c) :
  Is0Functor (cat_postcomp a h).
Proof.
  apply Build_Is0Functor.
  intros f g al; cbn in h.
  exact (compose_cate_fun h f
           $@ (h $@L al)
           $@ (compose_cate_fun h g)^$).
Defined.

Global Instance is0functor_core_precomp {A : Type} `{HasEquivs A}
       (a b c : core A) (h : a $-> b) :
  Is0Functor (cat_precomp c h).
Proof.
  apply Build_Is0Functor.
  intros f g al; cbn in h.
  (** Why can't coq resolve this? *)
  refine (compose_cate_fun f h
           $@ (_ $@R h)
           $@ (compose_cate_fun g h)^$).
  exact al.
Defined.

Global Instance is1cat_core {A : Type} `{HasEquivs A}
  : Is1Cat (core A).
Proof.
  rapply Build_Is1Cat.
  - intros; apply compose_cate_assoc.
  - intros; apply compose_cate_idl.
  - intros; apply compose_cate_idr.
Defined.

Global Instance is0gpd_core {A : Type} `{HasEquivs A}
  : Is0Gpd (core A).
Proof.
  apply Build_Is0Gpd.
  intros a b f; cbn in *; exact (f^-1$).
Defined.

Global Instance is1gpd_core {A : Type} `{HasEquivs A}
  : Is1Gpd (core A).
Proof.
  apply Build_Is1Gpd; cbn ; intros a b f;
    refine (compose_cate_fun _ _ $@ _ $@ (id_cate_fun _)^$).
  - apply cate_issect.
  - apply cate_isretr.
Defined.

Global Instance hasequivs_core {A : Type} `{HasEquivs A}
  : HasEquivs (core A).
Proof.
  srapply Build_HasEquivs.
  1: exact (fun a b => a $-> b).  (* In [core A], i.e. [CatEquiv' (uncore a) (uncore b)]. *)
  all: intros a b f; cbn; intros.
  - exact Unit.  (* Or [CatIsEquiv' (uncore a) (uncore b) (cate_fun f)]? *)
  - exact f.
  - exact tt.    (* Or [cate_isequiv' _ _ _]? *)
  - exact f.
  - reflexivity.
  - exact f^-1$.
  - refine (compose_cate_fun _ _ $@ _).
    refine (cate_issect _ $@ _).
    symmetry; apply id_cate_fun.
  - refine (compose_cate_fun _ _ $@ _).
    refine (cate_isretr _ $@ _).
    symmetry; apply id_cate_fun.
  - exact tt.
Defined.

(** * Initial objects and terminal objects are all respectively equivalent. *)

Lemma cate_isinitial A `{HasEquivs A} (x y : A)
  : IsInitial x -> IsInitial y -> x $<~> y.
Proof.
  intros inx iny.
  srapply (cate_adjointify (inx y).1 (iny x).1).
  1: exact (((iny _).2 _)^$ $@ (iny _).2 _).
  1: exact (((inx _).2 _)^$ $@ (inx _).2 _).
Defined.

Lemma cate_isterminal A `{HasEquivs A} (x y : A)
  : IsTerminal x -> IsTerminal y -> x $<~> y.
Proof.
  intros tex tey.
  srapply (cate_adjointify (tey x).1 (tex y).1).
  1: exact (((tey _).2 _)^$ $@ (tey _).2 _).
  1: exact (((tex _).2 _)^$ $@ (tex _).2 _).
Defined.

Lemma isinitial_cate A `{HasEquivs A} (x y : A)
  : x $<~> y -> IsInitial x -> IsInitial y.
Proof.
  intros f inx z.
  exists ((inx z).1 $o f^-1$).
  intros g.
  refine (_ $@ compose_hh_V _ f).
  refine (_ $@R _).
  exact ((inx z).2 _).
Defined.

Lemma isterminal_cate A `{HasEquivs A} (x y : A)
  : x $<~> y -> IsTerminal x -> IsTerminal y.
Proof.
  intros f tex z.
  exists (f $o (tex z).1).
  intros g.
  refine (_ $@ compose_h_Vh f _).
  refine (_ $@L _).
  exact ((tex z).2 _).
Defined.

(** * There is a default notion of equivalence for a 1-category, namely bi-invertibility. *)

(** We do not use the half-adjoint definition, since we can't prove adjointification for that definition. *)

Class Cat_IsBiInv {A} `{Is1Cat A} {x y : A} (f : x $-> y) := {
  cat_equiv_inv : y $-> x;
  cat_eisretr : f $o cat_equiv_inv $== Id y;
  cat_equiv_inv' : y $-> x;
  cat_eissect' : cat_equiv_inv' $o f $== Id x;
}.

Arguments cat_equiv_inv {A}%type_scope { _ _ _ _ x y} f {_}.
Arguments cat_eisretr {A}%type_scope { _ _ _ _ x y} f {_}.
Arguments cat_equiv_inv' {A}%type_scope { _ _ _ _ x y} f {_}.
Arguments cat_eissect' {A}%type_scope { _ _ _ _ x y} f {_}.

Arguments Build_Cat_IsBiInv {A}%type_scope {_ _ _ _ x y f} cat_equiv_inv cat_eisretr cat_equiv_inv' cat_eissect'.

Record Cat_BiInv A `{Is1Cat A} (x y : A) := {
  cat_equiv_fun :> x $-> y;
  cat_equiv_isequiv : Cat_IsBiInv cat_equiv_fun;
}.

Global Existing Instance cat_equiv_isequiv.

(** The two inverses are necessarily homotopic. *)
Definition cat_inverses_homotopic {A} `{Is1Cat A} {x y : A} (f : x $-> y) {bif : Cat_IsBiInv f}
  : cat_equiv_inv f $== cat_equiv_inv' f.
Proof.
  refine ((cat_idl _)^$ $@ _).
  refine (cat_prewhisker (cat_eissect' f)^$ _ $@ _).
  refine (cat_assoc _ _ _ $@ _).
  refine (cat_postwhisker _ (cat_eisretr f) $@ _).
  apply cat_idr.
Defined.

(** Therefore we can prove [eissect] for the first inverse as well. *)
Definition cat_eissect {A} `{Is1Cat A} {x y : A} (f : x $-> y) {bif : Cat_IsBiInv f}
  : cat_equiv_inv f $o f $== Id x
  := (cat_inverses_homotopic f $@R f) $@ cat_eissect' f.

(** This shows that any 1-category satisfies [HasEquivs].  We do not make it an instance, since we may want to use a different [HasEquivs] structure in particular cases. *)
Definition cat_hasequivs A `{Is1Cat A} : HasEquivs A.
Proof.
  srapply Build_HasEquivs; intros x y.
  1: exact (Cat_BiInv _ x y).
  all:intros f; cbn beta in *.
  - exact (Cat_IsBiInv f).
  - exact f.
  - exact _.
  - apply Build_Cat_BiInv.
  - intros; reflexivity.
  - exact (cat_equiv_inv f).
  - apply cat_eissect.
  - apply cat_eisretr.
  - intros g r s.
    exact (Build_Cat_IsBiInv g r g s).
Defined.
