open Printf

(* type expr = Int of int | Bool of bool | IfThen of expr * expr
type ('a,'b) gexpr = Int of int | Bool of bool | IfThen of 'a * 'b
type expr = ((bool,int) gexpr, (bool,int) gexpr) gexpr *)
type ('a, 'b) glist = Nil | Cons of 'a * 'b
 (* [@@deriving gt {show}] *)

class type virtual
   ['tpoT,'type_itself,'gt_a_for_a,'gt_a_for_b,'gt_a_for_self,'inh,'syn] glist_meta_tt =
   object
     method  virtual c_Nil  : 'inh -> ('inh,'type_itself,'syn,'tpoT) GT.a -> 'syn
     method  virtual c_Cons : 'inh -> ('inh,'type_itself,'syn,'tpoT) GT.a ->
           'gt_a_for_a -> 'gt_a_for_b -> 'syn
   end
class type virtual ['a,'ia,'sa,'b,'ib,'sb,'inh,'syn] glist_tt =
  object
    inherit
      [ < a: 'ia -> 'a -> 'sa; b: 'ib -> 'b -> 'sb >  as 'tpoT
      , ('a, 'b) glist
      , ('ia,'a,'sa,'tpoT) GT.a
      , ('ib,'b,'sb,'tpoT) GT.a
      , ('inh,('a, 'b) glist,'syn,'tpoT) GT.a
      , 'inh,'syn ] glist_meta_tt
      method  t_glist :
        ('ia -> 'a -> 'sa) ->
        ('ib -> 'b -> 'sb) -> 'inh -> ('a,'b) glist -> 'syn
  end

let rec glist_meta_gcata fa fb (tpo: 'tpoT) trans (initial_inh: 'inh) subj : 'syn =
  let self = glist_meta_gcata fa fb tpo trans in
   match subj with
   | Nil  -> trans#c_Nil initial_inh (GT.make self subj tpo)
   | Cons (p0,p1) ->
       trans#c_Cons initial_inh (GT.make self subj tpo) (fa p0) (fb p1)

let glist_gcata fa fb transformer initial_inh subj =
  let parameter_transforms_obj = object method a = fa method b = fb end  in
  glist_meta_gcata
    (fun x  -> GT.make fa x parameter_transforms_obj)
    (fun x  -> GT.make fb x parameter_transforms_obj)
    parameter_transforms_obj transformer initial_inh subj

class virtual ['tpoT,'type_itself,'gt_a_for_a,'gt_a_for_b,'gt_a_for_self,'inh,'syn] glist_meta_t =
  object (self : 'self)
    constraint 'self =
      ('tpoT,'type_itself,'gt_a_for_a,'gt_a_for_b,'gt_a_for_self,'inh,'syn) #glist_meta_tt
end
class virtual ['tpoT
  ,'a,'ia,'sa,'gt_a_for_a
  ,'b,'ib,'sb,'gt_a_for_b
  ,'gt_a_for_self,'inh,'syn] glist_t =
  object
    inherit ['tpoT, ('a,'b)glist ,'gt_a_for_a,'gt_a_for_b,'gt_a_for_self,'inh,'syn] glist_meta_t
end

class ['tpoT,'a,'a_holder,'b,'b_holder,'self_holder] show_meta_glist
    (for_a: 'a_holder -> string)
    (for_b: 'b_holder -> string)
  =
  object (this)
    inherit
      ['tpoT
      ,'a,unit,string,'a_holder
      ,'b,unit,string,'b_holder
      ,(unit,('a_holder,'b_holder) glist,string,'tpoT) GT.a
      ,unit,string ] glist_t
     method c_Cons inh subj (p0 : 'a_holder) (p1 : 'b_holder) =
       "Cons (" ^ ((String.concat ", " [for_a p0; for_b p1]) ^ ")")
     method c_Nil inh subj = "Nil ()"
   end

class ['a,'b] show_glist = object
  inherit
    [ < a: unit -> 'a -> string; b: unit -> 'b -> string >  as 'tpoT
    , 'a,(unit,'a,string,'tpoT) GT.a
    , 'b,(unit,'b,string,'tpoT) GT.a
    , ('a, 'b) glist ]
      show_meta_glist (fun pa  -> pa.GT.fx ()) (fun pb -> pb.GT.fx ())
end

let glist = {
  GT.gcata = glist_gcata;
  GT.plugins =
     (object
        method show fa fb =
          glist_gcata (GT.lift fa) (GT.lift fb) (new show_glist) ()
      end)
}

let () =
  let rec show fa xs =
    glist_gcata (GT.lift fa) (GT.lift @@ show fa) (new show_glist) () xs
    in
  printf "%s\n%!" (show string_of_int (Nil));
  printf "%s\n%!" (show string_of_int (Cons (2, Nil)));
  printf "%s\n%!" (show string_of_int (Cons (2, Cons (2, Nil))));
()


(* *************************************************************** *)
type 'a list = ('a, 'a list) glist

let list_meta_gcata fa x = glist_meta_gcata fa (fun x -> x) x

let list_gcata fa transformer initial_inh subj =
  let parameter_transforms_obj = object method a = fa end  in
  list_meta_gcata
    (* fa *)
    (fun x  -> GT.make fa x parameter_transforms_obj)
    parameter_transforms_obj transformer initial_inh subj
(* ????? *)

(* class virtual
  ['tpoT,'type_itself
  ,'gt_a_for_a
  ,'inh,'syn] list_meta_t = object
   (* (self : 'self) *)
    inherit ['tpoT,'type_itself,'gt_a_for_a,'type_itself,'inh,'syn] glist_meta_t
 end *)

(* class virtual
  ['tpoT,'a,'ia,'sa,'gt_a_for_a,'inh,'syn] list_t =
  object (this)
    inherit  ['tpoT, 'a list, 'gt_a_for_a, 'inh, 'syn]
      list_meta_t
end *)

class virtual ['tpoT,'a,'a_holder, 'self_holder] show_meta_list for_a for_me =

  (* let rec for_b = function
  | Nil -> "Nil ()"
  | Cons (p0,p1) -> "Cons (" ^ ((for_a p0) ^ ", " ^ (for_b p1) ^ ")")
  in *)

  object (this)
    inherit ['tpoT, 'a, 'a_holder, 'a list, 'self_holder, 'a_holder list] show_meta_glist
      for_a
      for_me
end

class ['a, 'self_holder] show_list for_me = object(this)
  inherit [ < a: unit -> 'a -> string > as 'tpoT
          , 'a
          , (unit, 'a, string, 'tpoT) GT.a
          , 'self_holder
          ] show_meta_list (fun pa -> pa.GT.fx ()) (for_me)

  (* method t_list transform_a x = list_gcata transform_a this x *)
end

(*
let list = {
  GT.gcata = list_gcata;
  GT.plugins =
     (object
        method show fa = list_gcata (GT.lift fa) (new show_list) ()
      end)
} *)


let () =
  let rec show fa xs =
    list_gcata (GT.lift fa) (new show_list (show fa)) () xs
  in
  printf "%s\n%!" (show string_of_int (Nil));
  printf "%s\n%!" (show (fun x -> x) (Cons ("FUCK", Nil)));
  printf "%s\n%!" (show string_of_int (Cons (1, Cons (1, Nil))));
()
