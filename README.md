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
