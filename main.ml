(* Module Main: The main program.  Deals with processing the command
   line, reading files, building and connecting lexers and parsers, etc. 
   
   For most experiments with the implementation, it should not be
   necessary to change this file.
*)

open Format
open Support.Pervasive
open Support.Error
open Syntax
open Core

(* refは参照(https://ocaml.org/learn/tutorials/structure_of_ocaml_programs.ja.html) *)
let searchpath = ref [""]

let argDefs = [
  "-I",
      Arg.String (fun f -> searchpath := f::!searchpath), (* !で参照の中身を取り出す *)
      "Append a directory to the search path"]

let parseArgs () =
  (* in はローカルな式に名前をつけて定義する.  *)
  let inFile = ref (None : string option) in
  (* Arg.parse speclist anonfun usage_msg はコマンドラインをパースします。http://ocaml.jp/archive/ocaml-manual-3.06-ja/libref/Arg.html *)
  Arg.parse argDefs
     (fun s ->
       match !inFile with
         Some(_) -> err "You must specify exactly one input file"
       | None -> inFile := Some(s))
     "";

  (* inFileの実体を存在チェック *)
  match !inFile with
      None -> err "You must specify an input file"
    | Some(s) -> s

let openfile infile = 
  let rec trynext l = match l with
        [] -> err ("Could not find " ^ infile)
      | (d::rest) -> 
          let name = if d = "" then infile else (d ^ "/" ^ infile) in
          try open_in name (* 例外を投げうる. open_in name は nameを読み込んだ結果を返す *)
            with Sys_error m -> trynext rest
  in trynext !searchpath

let parseFile inFile =
  let pi = openfile inFile
  in let lexbuf = Lexer.create inFile pi
  in let result =
    try Parser.toplevel Lexer.main lexbuf with Parsing.Parse_error -> 
    error (Lexer.info lexbuf) "Parse error"
in
  Parsing.clear_parser(); close_in pi; result

let alreadyImported = ref ([] : string list)

let rec process_command  cmd = match cmd with
  | Eval(fi,t) -> 
      let t' = eval t in
      printtm_ATerm true t'; 
      force_newline();
      ()
  
let process_file f  =
  alreadyImported := f :: !alreadyImported;
  let cmds = parseFile f in
  let g  c =  
    open_hvbox 0;
    let results = process_command  c in
    print_flush();
    results
  in
    List.iter g  cmds

    (* ()はunit, いわゆるvoid *)
    (* let式は複数書ける, FYI: http://www.fos.kuis.kyoto-u.ac.jp/~igarashi/class/pl/03-ocaml.html *)
    (* 
    let 〈変数〉 = 〈式1〉 in 〈式2〉
であり，直観的には「〈式2〉の計算中，〈変数〉を〈式1〉(の値)とする」という意味で，〈式1〉を計算し，その値に〈変数〉という名前をつけ，〈式2〉の値を計算する．
     *)
let main () = 
  let inFile = parseArgs() in
  let _ = process_file inFile  in
  ()

let () = set_max_boxes 1000
let () = set_margin 67
let res = 
  Printexc.catch (fun () -> 
    try main();0 
    with Exit x -> x) 
  ()
let () = print_flush();
