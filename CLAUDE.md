# defmod.el

`defmod` — a package-configuration macro for Emacs that only schedules:
keywords say *when*, never *what*. Fast uncompiled startup through explicit
deferral; internals small enough to read in one sitting.

## Required reading

- `CONTEXT.md` — the project glossary. Use its terms exactly (Block, Stage,
  Load Mode, Trigger, Ensure, Skeleton). When a design question arises,
  check whether the glossary already answers it.
- `docs/adr/` — architecture decision records. Do not contradict an ADR
  without an explicit decision to supersede it. In particular: no operation
  keywords (0001), instant loading by default (0002), fixed-skeleton
  single-pass expansion (0003), CC0 clean room (0004).

## Hard rules

- Emacs 30.1 is the floor; zero external runtime dependencies. The
  *expansion* may reference only built-ins plus package.el/package-vc.
- `lisp/defmod.el` has ZERO `require`s — preloaded built-ins only. It
  loads uncompiled at every startup, so every dependency is startup cost
  (measured: `cl-lib` ~8ms; `pcase`, `cl-lib`, `subr-x` are NOT preloaded,
  `seq` is). This means: `cond` instead of `pcase`, no `cl-lib`, no
  `when-let`. The test file is exempt (`cl-lib` for `cl-letf` is fine in
  tests — tests are not startup code).
- One package file: `lisp/defmod.el`, providing `defmod`. The package
  prefix is `defmod` (`defmod-` public, `defmod--` private) — the file is
  NOT named mod.el because `defmod` must pass package-lint's prefix check,
  and `mod` is the built-in modulo function.
- All elisp files: lexical binding, checkdoc-clean docstrings (CI fails on
  violations). Copyright/license header lives in `lisp/defmod.el` ONLY;
  other files keep the minimal skeleton (first-line summary, Commentary,
  Code, provide, ends-here).
- Engine discipline (docs/adr/0003): one forward parse pass filling Slots,
  one visible assembly template. No `eval` at expansion time, no keyword
  sorting, no recursive handlers, no dynamic-variable accumulators. If a
  change seems to need one of these, stop and discuss.
- Grammar is strict: unknown keywords, duplicate keywords, stage-less
  forms, and `:defer`+`:after` together are expansion-time errors. Errors
  are plain `error` (not `user-error`) so `--debug-init` points at the
  offending form, with the format `"defmod NAME: MESSAGE"`, e.g.
  `(error "defmod foo: duplicate keyword %s" key)` — block name first,
  greppable. (Verified: the byte-compiler does not warn on the lowercase
  format string.)
- License is CC0-1.0, NOT GPL (docs/adr/0004): never copy code from
  leaf.el, use-package, setup.el, or Emacs internals — all GPL. We studied
  leaf.el's source closely during design; ideas and architecture are fine,
  reproduced code is a license violation.

## Test rules

- Tests are ERT in `test/defmod-test.el`, run with `just test` (batch).
- Expansion tests are the primary kind: `should`-`equal` the
  `macroexpand-1` of a `defmod` form against the literal expected
  expansion. The three Load Modes (instant, `:defer`, `:after`) each keep
  at least one golden expansion test.
- Every strict-grammar error path has a `should-error` test. A new error
  message ships with its test in the same change.
- Expansion tests use raw `should` + `equal` — no wrapper macro; when a
  golden fails, the comparison must be directly visible.
- Behavioral tests (does `:config` actually run on load?) stub the package
  system — `cl-letf` `package-installed-p` to t — and trigger deferral by
  `provide`-ing a fake feature in-process. Tests never touch the network
  or the package archives. This ceremony lives in ONE fixture macro at the
  top of `test/defmod-test.el` (which must also clean up fake features and
  their `after-load-alist` entries); no separate test-utils file until a
  second test file exists.
- A change to the grammar or a Load Mode updates the golden expansion
  tests in the same commit; a failing golden test is a design change, not
  a test to silence.

## Workflow

- `just compile` / `just lint` / `just test` / `just ci` (all of them).
  Compile is staged into `.stage/` with `byte-compile-error-on-warn`;
  lint is package-lint AND checkdoc, both failing.
- `nix develop` provides the devShell (Emacs with package-lint, just).
  There is deliberately no `nix run` app — a macro has no playground.
- CI is `nix develop --command just ci` on GitHub Actions.
- Conventional-commit-style subject prefixes are preferred: `fix:`, `feat:`,
  `docs:`, `test:`, `refactor:`, `build:`, `dev:` (repo chores/tooling), etc.
  Keep the block-name-first error convention separate — this is about commit
  subjects, not error strings.
