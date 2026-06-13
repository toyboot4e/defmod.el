# Ideas / backlog

Loose design ideas not yet promoted to an ADR. Recording, not deciding.

## ~~`:if COND` — conditional load keyword~~ — DONE (ADR-0005)

Implemented: `:if COND` gates the whole Block. See `docs/adr/0005`.

## ~~`:ensure nil` — configure without installing~~ — DONE (ADR-0006)

Implemented as `:builtin`: skips Ensure for a package provided outside
package.el (a built-in, or installed by other means). See `docs/adr/0006`.
(A genuine sub-feature like `lsp-ui-imenu` is better folded into its parent
Block's `:config` than given its own `:builtin` Block.)
