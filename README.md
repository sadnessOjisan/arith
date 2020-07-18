# arith

Rules for compiling and linking the typechecker/evaluator

Type
make to rebuild the executable file f
make windows to rebuild the executable file f.exe
make test to rebuild the executable and run it on input file test.f
make clean to remove all intermediate and temporary files
make depend to rebuild the intermodule dependency graph that is used
by make to determine which order to schedule
compilations. You should not need to do this unless
you add new modules or new dependencies between
existing modules. (The graph is stored in the file
.depend)

## make test したら何が起きるのかメモ

`make test` すると、

```
test: all
	./f test.f
```

が呼ばれる。

makefile においては、make all は make と同じ｡

all は

```
all: $(DEPEND) $(OBJS) f
```

とあるので、`make test` コンパイル結果として f を生成し、それを`./f test.f` としてテストしている。

このテストコード自体は

```
/* Examples for testing */

true;
if false then true else false;

0;
succ (pred 0);
iszero (pred (succ (succ 0)));
```

となっている。

プログラミングの基礎などにもあったが、こういうテスト方法は OCaml でよくやられるのか？

test の動きは分かったので、all のやり方を見ていく。

all は

```
all: $(DEPEND) $(OBJS) f
```

であり、

DEPEND は`lexer.ml parser.ml`, OBJS は`support.cmo syntax.cmo core.cmo parser.cmo lexer.cmo main.cmo`となっている。

そして f は、

```
f: $(OBJS) main.cmo
	@echo Linking $@
	ocamlc -o $@ $(COMMONOBJS) $(OBJS)
```

とあり、`ocamlc` を実行しています。
COMMONOBJS は何もないですが動きます。
適当な文字列 HOGEEEE とかに書き換えても動きます。

この@は自動命令というもので、ターゲット名が入ります。
つまり、

```
f: $(OBJS) main.cmo
	@echo Linking f
	ocamlc -o f support.cmo syntax.cmo core.cmo parser.cmo lexer.cmo main.cmo
```

となります。

ocamlc はバイトコードコンパイラです。

http://ocaml.jp/archive/ocaml-manual-3.06-ja/manual022.html を参照すると、

> .mli で終わる引数はコンパイルユニットのインターフェイスのソースファイルと認識されます。インターフェイスはコンパイルユニットが外部に公開する名前を指定します。値の名前とその型を宣言し、公開データ型を定義し、抽象データ型を宣言します。ocamlc はファイル x.mli なら、ファイル x.cmi を生成し、インターフェイスをコンパイルしたものを出力します。

> .ml で終わる引数はコンパイルユニットの実装のソースファイルとして認識されます。実装はユニットが外部に公開する名前の定義を持ち、副作用のある式なども持ちます。ocamlc はファイル x.ml なら、ファイル x.cmo を生成し、コンパイル済みオブジェクトバイトコードを出力します。

とあります。

さらにファイルの順番にも意味があり、

> .cmo で終わる引数はコンパイル済みオブジェクトバイトコードと認識されます。これらのファイルは (もしあれば) .ml 引数をコンパイルして得られたオブジェクトファイルや Objective Caml 標準ライブラリと一緒にリンクされて、単独実行ファイルが生成されます。コマンドラインでの .cmo や .ml の引数の順番には意味があります。コンパイルユニットはランタイム時その順で初期化され、初期化前のユニットのコンポーネントを使おうとしたらリンク時にエラーとなります。なのでファイル x.cmo はユニット x に参照を持つファイル .cmo より前に置かなければなりません。

-o オプションは

> -o exec-file
> リンカが出力するファイルの名前を指定します。デフォルトの出力名は Unix の伝統に則り a.out です。-a が指定されている場合は生成されるライブラリ名の指定になります。-output-obj が指定されている場合は生成されるファイル名の指定になります

とあり、コンパイル後のファイル名を指定できます。

つまり、`ocamlc -o $@ $(COMMONOBJS) $(OBJS)` は f というコンパイル後のコードを生成します。

でもここまでで、OBJS の support.cmo syntax.cmo core.cmo parser.cmo lexer.cmo main.cmo は作っていませんが、これはどこで作られたのでしょうか。

#### suffix

それが、

```
# Compile an ML module interface
%.cmi : %.mli
	ocamlc -c $(OCAMLCFLAGS) $<

# Compile an ML module implementation
%.cmo : %.ml
	ocamlc -c $(OCAMLCFLAGS) $<

# Generate ML files from a parser definition file
parser.ml parser.mli: parser.mly
	@rm -f parser.ml parser.mli
	ocamlyacc -v parser.mly
	@chmod -w parser.ml parser.mli

# Generate ML files from a lexer definition file
%.ml %.mli: %.mll
	@rm -f $@
	ocamllex $<
    @chmod -w $@
```

といった suffix がついたコードです。

#### depend

その仕組みが depend です。

FYI: https://ocaml.jp/archive/ocaml-manual-3.06-ja/manual027.html

> ocamldep コマンドは Objective Caml のソース群をスキャンして他のコンパイルユニットへの参照 (依存関係) を探します。 依存関係の出力は make コマンドの形式で、これを利用すると make が正しい順番でソースファイルをコンパイルでき、ソースファイルを一部変更したとき必要なところだけ再コンパイルできるようになります。

実際、

````

core.cmo : syntax.cmi support.cmi core.cmi
core.cmx : syntax.cmx support.cmx core.cmi
core.cmi : syntax.cmi support.cmi
lexer.cmo : support.cmi parser.cmi
lexer.cmx : support.cmx parser.cmx
main.cmo : syntax.cmi support.cmi parser.cmi lexer.cmo core.cmi
main.cmx : syntax.cmx support.cmx parser.cmx lexer.cmx core.cmx
parser.cmo : syntax.cmi support.cmi parser.cmi
parser.cmx : syntax.cmx support.cmx parser.cmi
parser.cmi : syntax.cmi support.cmi
support.cmo : support.cmi
support.cmx : support.cmi
support.cmi :
syntax.cmo : support.cmi syntax.cmi
syntax.cmx : support.cmx syntax.cmi
syntax.cmi : support.cmi

```

が出力されます。
make のルールを作ることができます。

makefileでは `include .depend` と書かれています。

##### TIP

make の -p, --print-data-base オプション、makefile を読み込んで得られたデータベース(規則と変数の値)を出力する。 特に指定しない限り、その後の動作は通常通りである。また、 -v オプションで得られるバージョン情報も出力する。 ファイルを全く再構築することなく、データベースの表示だけを行うには make -p -f/dev/nul を用いること。 (https://linuxjm.osdn.jp/html/GNU_make/man1/make.1.html)
```
````

\$< : 最初の依存するファイルの名前

% は wildcard

make はターゲットのファイルを書く
タスクとして使うこともできる
同一ファイル名があるとそのタスクは使えないので、.PHONY は，タスクターゲットを宣言するためのターゲットを使うこともある

.depend の中身を全部消して make

```
❯ make
ocamlc -c -unsafe-string support.ml
File "support.ml", line 1:
Error: Could not find the .cmi file for interface support.mli.
make: *** [support.cmo] Error 2
```

- ml
  - OCaml のファイル
- mli
  - モジュールインタフェース
  - .mli ファイルは、 マッチする .ml ファイルの直前にコンパイルされなければならない。
- cmi
  - インターフェイスをコンパイルしたもの
  - _.mli をコンパイルすると _.cmi が出力される
  - _.mli が無い場合は _.ml から \*.cmi が生成される
- cmo
  - 実装をコンパイルしたもの
  - _.ml を ocamlc でコンパイルすると _.cmo が出力される
- cmx
  - コンパイル済みオブジェクトコードと認識されます。

---

ocamlc の option,

ocaml -c ...

> コンパイルのみ行ない、リンクを行いません。 ソースコードファイルからコンパイル済みファイルを生成しますが、実行ファイルは生成しません。 このオプションはモジュールを分割コンパイルするのに便利です。
> (https://ocaml.jp/refman/ch08s02.html)

### 疑問

.depend はなぜ必要か
-> make が正しい順番でソースファイルをコンパイルでき、ソースファイルを一部変更したとき必要なところだけ再コンパイルできる
