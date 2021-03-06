Set Warnings "-notation-overridden,-parsing".
From Coq Require Import Arith.Arith.
Add LoadPath "/Users/jikl/demos/coq/software-foundation-exercise/logic_foundation" as LF.
From LF Require Import Maps.
From LF Require Import Imp.
From PLF Require Import SmallStep.

Hint Constructors multi : db.

Inductive tm : Type :=
| tru : tm
| fls : tm
| test : tm -> tm -> tm -> tm
| zro : tm
| scc : tm -> tm
| prd : tm -> tm
| iszro : tm -> tm.

Inductive bvalue : tm -> Prop :=
| bv_tru : bvalue tru
| bv_fls : bvalue fls.

Inductive nvalue : tm -> Prop :=
| nv_zro : nvalue zro
| nv_scc : forall t, nvalue t -> nvalue (scc t).

Definition value (t : tm) := bvalue t \/ nvalue t.

Hint Constructors bvalue nvalue : db.

Hint Unfold value : db.
Hint Unfold update : db.

Reserved Notation "t1 '-->' t2" (at level 40).

Inductive step : tm -> tm -> Prop :=
| ST_TestTru : forall t1 t2, (test tru t1 t2) --> t1
| ST_TestFls : forall t1 t2, (test fls t1 t2) --> t2
| ST_Test : forall t1 t1' t2 t3,
    t1 --> t1' ->
    (test t1 t2 t3) --> (test t1' t2 t3)
| ST_Scc : forall t1 t1',
    t1 --> t1' ->
    (scc t1) --> (scc t1')
| ST_PrdZro : (prd zro) --> zro
| ST_PrdScc : forall t1,
    nvalue t1 ->
    (prd (scc t1)) --> t1
| ST_Prd : forall t1 t1',
    t1 --> t1' ->
    (prd t1) --> (prd t1')
| ST_IszroZro :
    (iszro zro) --> tru
| ST_IszroScc : forall t1,
    nvalue t1 ->
    (iszro (scc t1)) --> fls
| ST_Iszro : forall t1 t1',
    t1 --> t1' ->
    (iszro t1) --> (iszro t1')
               
where "t1 '-->' t2" := (step t1 t2).

Hint Constructors step : db.

Notation step_normal_form := (normal_form step).

Definition stuck (t : tm) : Prop :=
  step_normal_form t /\ ~ value t.

Hint Unfold stuck : db.

Example some_term_is_stuck :
  exists t, stuck t.
Proof.
  exists (test zro zro zro).
  unfold stuck. split.
  - unfold step_normal_form.
    intro H. destruct H.
    inversion H. inversion H4.
  - intro H. inversion H.
    + inversion H0.
    + inversion H0.
Qed.

Lemma value_is_nf : forall t,
    value t -> step_normal_form t.
Proof.
  intros t H. inversion H.
  - inversion H0.
    + unfold step_normal_form.
      intro H2. destruct H2. inversion H2.
    + unfold step_normal_form.
      intro H2. destruct H2. inversion H2.
  - induction H0.
    + unfold step_normal_form.
      intro H1. destruct H1. inversion H0.
    + unfold step_normal_form.
      intro H1. destruct H1.
      inversion H1. subst.
      assert (Hv : value t).
      { unfold value. right. apply H0. }
      apply IHnvalue in Hv. unfold step_normal_form in Hv.
      apply Hv. eapply ex_intro. apply H3.
Qed.

Theorem step_deterministic :
  deterministic step.
Proof with eauto.
  unfold deterministic.
  intros x y1 y2 Hy1 Hy2.
  generalize dependent y2.
  induction Hy1; intros y2 Hy2;
    inversion Hy2; subst; try reflexivity.
  - inversion H3.
  - inversion H3.
  - inversion Hy1.
  - inversion Hy1.
  - apply IHHy1 in H3. rewrite H3. reflexivity.
  - apply IHHy1 in H0. rewrite H0. reflexivity.
  - inversion H0.
  - inversion H1. subst.
    assert (Hnf: step_normal_form t1).
    { apply value_is_nf. unfold value. right. apply H. }
    unfold step_normal_form in Hnf. unfold not in Hnf.
    exfalso. apply Hnf. eapply ex_intro. apply H2.
  - inversion Hy1.
  - inversion Hy1; subst.
    assert (Hnf: step_normal_form y2).
    { apply value_is_nf. unfold value. right. apply H0. }
    unfold step_normal_form in Hnf. unfold not in Hnf.
    exfalso. apply Hnf. eapply ex_intro. apply H1.
  - apply IHHy1 in H0. rewrite H0. reflexivity.
  - inversion H0.
  - inversion H1; subst.
    assert (Hnf: step_normal_form t1).
    { apply value_is_nf. unfold value. right. apply H. }
    unfold step_normal_form in Hnf. unfold not in Hnf.
    exfalso. apply Hnf. eapply ex_intro. apply H2.
  - inversion Hy1.
  - inversion Hy1; subst.
    assert (Hnf: step_normal_form t0).
    { apply value_is_nf. unfold value. right. apply H0. }
    unfold step_normal_form in Hnf. unfold not in Hnf.
    exfalso. apply Hnf. eapply ex_intro. apply H1.
  - apply IHHy1 in H0. rewrite H0. reflexivity.
Qed.

Inductive ty : Type :=
| Bool : ty | Nat : ty.

Reserved Notation "'|-' t '?' T" (at level 40).

Inductive has_type : tm -> ty -> Prop :=
| T_Tru :
  |- tru ? Bool
| T_Fls :
  |- fls ? Bool
| T_Test : forall t1 t2 t3 T,
    |- t1 ? Bool ->
    |- t2 ? T ->
    |- t3 ? T ->
    |- test t1 t2 t3 ? T
| T_Zro :
  |- zro ? Nat
| T_Scc : forall t1,
  |- t1 ? Nat ->
  |- scc t1 ? Nat
| T_Prd : forall t1,
    |- t1 ? Nat ->
    |- prd t1 ? Nat
| T_Iszro : forall t1,
    |- t1 ? Nat ->
    |- iszro t1 ? Bool
where "'|-' t '?' T" := (has_type t T).

Hint Constructors has_type : db.

Example has_type_1 :
  |- test fls zro (scc zro) ? Nat.
Proof.
  apply T_Test.
  - apply T_Fls.
  - apply T_Zro.
  - apply T_Scc. apply T_Zro.
Qed.

Example has_type_not :
  ~ (|- test fls zro tru ? Bool).
Proof.
  intro H. inversion H. inversion H5.
Qed.

Example scc_has_type_nat__hastype_nat : forall t,
    |- scc t ? Nat ->
    |- t ? Nat.
Proof.
  intros t H. inversion H. apply H1.
Qed.

Lemma bool_canonical : forall t,
    |- t ? Bool -> value t -> bvalue t.
Proof.
  intros t H1 H2.
  inversion H2.
  - assumption.
  - inversion H.
    + rewrite <- H0 in H1. inversion H1.
    + rewrite <- H3 in H1. inversion H1.
Qed.

Lemma nat_canonical : forall t,
    |- t ? Nat -> value t -> nvalue t.
Proof.
  intros t H1 H2.
  inversion H1; subst.
  - inversion H2.
    + inversion H4.
    + apply H4.
  - constructor.
  - inversion H2.
    + inversion H0.
    + apply H0.
  - inversion H2.
    + inversion H0.
    + apply H0.
Qed.

Theorem progress : forall t T,
    |- t ? T ->
       value t \/ exists t', t --> t'.
Proof.
  intros t T H. induction H. 
  - left. left. apply bv_tru.
  - left. left. apply bv_fls.
  - right. destruct IHhas_type1.
    + inversion H; subst.
      * eapply ex_intro; constructor.
      * eapply ex_intro; constructor.
      * inversion H2. inversion H6. inversion H6.
      * inversion H2. inversion H4. inversion H4.
    + destruct H2. exists (test x t2 t3).
      apply ST_Test. apply H2.
  - left. right. constructor.
  - destruct IHhas_type.
    + inversion H0.
      * inversion H1; rewrite <- H2 in H; inversion H.
      * inversion H1.
        left. right. apply nv_scc. apply nv_zro.
        left. right. apply nv_scc. apply nv_scc. apply H2.
    + destruct H0. right. exists (scc x).
      apply ST_Scc. apply H0.
  - destruct IHhas_type.
    + inversion H0.
      * inversion H1; rewrite <- H2 in H; inversion H.
      * inversion H1.
        right. exists zro. apply ST_PrdZro.
        right. exists t. apply ST_PrdScc. apply H2.
    + destruct H0. right. exists (prd x). apply ST_Prd. apply H0.
  - destruct IHhas_type.
    + inversion H0.
      * inversion H1; rewrite <- H2 in H; inversion H.
      * inversion H1.
        right. exists tru. apply ST_IszroZro.
        right. exists fls. apply ST_IszroScc. apply H2.
    + destruct H0. right. exists (iszro x). apply ST_Iszro. apply H0.
Qed.

Theorem preservation : forall t t' T,
    |- t ? T ->
    t --> t' ->
    |- t' ? T.
Proof.
  intros t t' T H1 H2.
  generalize dependent t'.
  induction H1.
  - intros t' H2. inversion H2.
  - intros t' H2. inversion H2.
  - intros t' H2. inversion H2; subst.
    + apply H1_0.
    + apply H1_1.
    + apply T_Test.
      * apply IHhas_type1. apply H4.
      * apply H1_0.
      * apply H1_1.
  - intros t' H2. inversion H2.
  - intros t' H2. inversion H2; subst.
    apply T_Scc. apply IHhas_type. apply H0.
  - intros t' H2. inversion H2; subst.
    + apply T_Zro.
    + inversion H1. apply H3.
    + apply T_Prd. apply IHhas_type. apply H0.
  - intros t' H2. inversion H2; subst.
    + apply T_Tru.
    + apply T_Fls.
    + apply T_Iszro. apply IHhas_type. apply H0.
Qed.

Theorem proservation': forall t t' T,
    |- t ? T ->
    t --> t' ->
    |- t' ? T.
Proof with eauto.
  intros t t' T H1 H2.
  generalize dependent T.
  induction H2; intros T H1.
  - inversion H1; subst. apply H5.
  - inversion H1; subst. apply H6.
  - apply T_Test.
    + apply IHstep. inversion H1; subst. apply H4.
    + inversion H1; subst. apply H6.
    + inversion H1; subst. apply H7.
  - inversion H1; subst. apply T_Scc. apply IHstep. apply H0.
  - inversion H1. apply T_Zro.
  - inversion H1; subst. inversion H2. apply H3.
  - inversion H1; subst. apply T_Prd. apply IHstep. apply H0.
  - inversion H1; subst. apply T_Tru.
  - inversion H1; subst. apply T_Fls.
  - inversion H1; subst. apply T_Iszro. apply IHstep. apply H0.
Qed.

Definition multistep := (multi step).
Notation "t1 '-->*' t2" := (multistep t1 t2) (at level 40).

Corollary soundness : forall t t' T,
    |- t ? T ->
    t -->* t' ->
    ~(stuck t').
Proof.
  intros t t' T HT P. induction P; intros [R S].
  destruct (progress x T HT); auto.
  apply IHP. apply (preservation x y T HT H).
  unfold stuck. split; auto.
Qed.

