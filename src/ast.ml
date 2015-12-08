type op = | Add | Sub | Mult | Div 
          | Equal | Neq | Less | Leq | Greater | Geq 
          | LogAnd (* && *)
          | LogOr (* || *)

type bool = True | False

type expr =
    NumLiteral of string
  | StrLiteral of string
  | ListLiteral of expr list (* ex. [1, 3, 42.33] *)
  | DictLiteral of (expr * expr) list (* ex. [(key, value)] *)
  | Boolean of bool
  | Id of string
  | Binop of expr * op * expr
  | Call of string * expr list
  | Access of string * expr (* for dict and list element access *)
  | MemberVar of string * string (* parent variable, the accessed member *)
  | MemberCall of string * string * expr list (* parent variable, accessed funct, parameters *)
  | Undir of string * string (* id, id *)
  | Dir of string * string (* id, id *)
  | UndirVal of string * string * expr (* id, id, weight *)
  | DirVal of string * string * expr (* id, id, weight *)
  | BidirVal of expr * string * string * expr (* weight, id, id, weight *)
  | NoOp of string
  | Noexpr

(* b/c nums can be either float or int just treat them as strings *)
(*type edge_expr =
| Undir of string * string (* id, id *)
| Dir of string * string (* id, id *)
| UndirVal of string * string * expr (* id, id, weight *)
| DirVal of string * string * expr (* id, id, weight *)
| BidirVal of expr * string * string * expr (* weight, id, id, weight *)
| NoOp of string
*)


type alt_stmt =
    Block of alt_stmt list
  | Expr of expr
  | Vdecl of string * string (* (type, id) *)
  | ListDecl of  string * string (* elem_type, id *)
  | DictDecl of string * string * string (* key_type, elem_type, id *)
  | Assign of string * expr
(*   | AssignList of string * expr  *)(* when a list of expressions is assigned to a variable *)
  | Return of expr
  | If of expr * alt_stmt * alt_stmt
  | For of string * string * alt_stmt list (* temp var, iterable var, var decls, stmts *)
  | While of expr * alt_stmt list (* condition, var decls, stmt list *)
  
type func_decl = {
    rtype : string; 
    fname : string;
    formals : (string * string) list;
    (*locals : string list;*)
    body : alt_stmt list;
  }

type stmt =
 | Alt_stmt of alt_stmt
 | Fdecl of func_decl

(* program: ist of vars, function defs, commands not within a function  
    funcs : func_decl list;
                cmds :
*)
type program =  stmt list 

(* type program = string list * func_decl list *)

(*/////////////////////////////////////////////////////////////////////////////
                              /* PRETTY PRINTER */
///////////////////////////////////////////////////////////////////////////// *)

(* prepends prelist at the head of postlst *)
let rec base_concat postlst = function
  | [] -> postlst
  | hd :: tl -> base_concat (hd :: postlst) tl 

let concat prelst postlst = base_concat postlst (List.rev prelst)

let rec string_of_expr = function
    NumLiteral(l) -> l
  | StrLiteral(l) -> "\"" ^ l ^ "\""
  | ListLiteral(el) -> "[" ^ String.concat "," (List.map string_of_expr el) ^ "]"
 (*) | DictLiteral(k,v) -> "[" ^ String.concat "," (List.map string_of_expr el) ^ "]" *)
  | Boolean(b) -> if b = True then "true" else "false"
  | Id(s) -> s
  | Binop(e1, o, e2) ->
      string_of_expr e1 ^ " " ^
      (match o with
	         Add -> "+"  
          | Sub -> "-" 
          | Mult -> "*" 
          | Div -> "/"
          | Equal -> "==" 
          | Neq -> "!="
          | Less -> "<" 
          | Leq -> "<=" 
          | Greater -> ">" 
          | Geq -> ">="
          | LogAnd -> "&&"
          | LogOr -> "||"
        ) ^ " " ^

      string_of_expr e2
  | Undir (s1, s2) -> s1 ^ " -- " ^ s2  
  | Dir (s1, s2) -> s1 ^ " --> " ^ s2
  | UndirVal (s1, s2, w) -> s1 ^ " --[" ^ string_of_expr w ^ "] " ^ s2 
  | DirVal (s1, s2, w) -> s1 ^ " -->[" ^ string_of_expr w ^ "] " ^ s2
  | BidirVal (w1, s1, s2, w2) -> s1 ^ " [" ^ string_of_expr w1 ^ "]--[" ^ string_of_expr w2 ^ "] " ^ s2 
  | NoOp (s) -> s
  | Call(f, el) ->
      f ^ "(" ^ String.concat ", " (List.map string_of_expr el) ^ ")"
  | Access (s, e1) -> s ^ "[" ^ string_of_expr e1 ^ "]"
  | MemberVar (s1, s2) -> s1 ^ "." ^ s2
  | MemberCall (s1, s2, el) -> s1 ^ "." ^ s2 ^ "(" ^ String.concat ", " (List.map string_of_expr el) ^ ")"
  | Noexpr -> ""

let rec string_of_stmt = function
    Block(stmts) ->
      "{\n" ^ String.concat "" (List.map string_of_stmt stmts) ^ "}\n"
  | Expr(expr) -> string_of_expr expr ^ ";\n";
  | Vdecl(dt, id) -> dt ^ " " ^ id ^ ";\n";
  | ListDecl(dt, id) -> "list <" ^ dt ^ "> " ^ id ^ ";\n"
  | DictDecl(kdt, vdt, id) -> "dict <" ^ kdt ^ ", " ^ vdt ^ "> " ^ id ^ ";\n"
  | Assign(v, e) -> v ^ " = " ^ string_of_expr e ^ ";"
(*   | AssignList(id, el) -> " ~TODO~ " *)
  | Return(expr) -> "return " ^ string_of_expr expr ^ ";\n";
  | If(e, s, Block([])) -> "if (" ^ string_of_expr e ^ ")\n" ^ string_of_stmt s
  | If(e, s1, s2) ->  "if (" ^ string_of_expr e ^ ")\n" ^
      string_of_stmt s1 ^ "else\n" ^ string_of_stmt s2
  | For(e1, e2, sl) ->
      "for (" ^ e1  ^ " in " ^ e2 
      ^ ") { " ^ String.concat "\n" (List.map string_of_stmt sl) ^ " }"
  | While(e, sl) -> "while (" ^ string_of_expr e ^ ") {" ^ String.concat "\n" (List.map string_of_stmt sl) ^ " }"

let string_of_vdecl id = "type " ^ id ^ ";\n"

let string_of_fdecl fdecl =
  "def " ^ fdecl.rtype ^ " " ^ fdecl.fname ^ "(" ^ 
    String.concat ", " (List.map (fun f -> fst f ^ " " ^ snd f) fdecl.formals) ^
     ")\n{\n" ^
  (*String.concat "" (List.map string_of_vdecl fdecl.locals) ^*)
  String.concat "" (List.map string_of_stmt fdecl.body) ^
  "}\n"

let string_of_program (funcs,  cmds) =
  String.concat "\n" (List.map string_of_fdecl funcs) ^
  String.concat "\n" (List.map string_of_stmt cmds)
