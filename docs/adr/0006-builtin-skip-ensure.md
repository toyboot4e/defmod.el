# Configure without installing via `:builtin`

`defmod` has a `:builtin` flag keyword: it drops the Ensure step, so a Block
configures and loads a package that is **not installed through package.el** — a
built-in (`proced`, `prolog-mode`, `javascript-mode`) or a package installed by
other means (system package manager, manual checkout). Everything else about the
Block is unchanged; only the `(unless (package-installed-p …) (package-install
…))` form is omitted.

`:builtin` and `:vc` are mutually exclusive — one says "do not install," the
other "install from this VC source" — and combining them is an expansion-time
error.

## Why a keyword and not plain Elisp

Until now CONTEXT.md's Ensure invariant was absolute: "every Block installs its
package if missing." Dogfooding a large config showed that breaks for every
built-in a user wants to configure — leaf/use-package both ship `:ensure nil`
for exactly this. The plain-Elisp fallback (a bare `setopt` / `with-eval-after-load`
with no Block) loses the one thing the Block gives you: NAME stated once, with
its Stages and Load Mode read off in one place. `:builtin` keeps built-ins
first-class while making the "no install" decision explicit and greppable.

This still honours ADR-0001: `:builtin` is *scheduling/provisioning* (whether to
install), not an operation keyword (what happens).

## Engine discipline (ADR-0003)

`:builtin` is one boolean Slot from the single forward parse pass; the assembly
template splices the Ensure form in only when it is absent. No new `eval`,
recursion, or sorting. The `:builtin`/`:vc` conflict is a single post-parse
check, matching the existing Load-Mode conflict checks.

## Scope / non-goals

- `:builtin` does not solve a NAME-vs-feature mismatch (e.g. `javascript-mode`
  the command vs the `js` feature). A built-in whose feature differs from its
  Block name should be `:defer`red (no `require`) or configured under its real
  feature name — same as it would be by hand.
- A genuine sub-feature of an installed package (`lsp-ui-imenu` inside `lsp-ui`)
  is better folded into the parent Block's `:config` than given its own
  `:builtin` Block — there is nothing separate to load.

## Consequences

- The Ensure invariant now reads "every Block installs its package if missing,
  *unless* `:builtin`."
- Golden tests pin the no-Ensure expansion (instant and deferred); an error test
  pins the `:builtin` + `:vc` conflict (both orders).
