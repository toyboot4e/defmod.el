# mod.el

`defmod` — an Emacs package-configuration macro that **only schedules**:
keywords say *when*, never *what*. What happens is always plain Elisp you
write yourself; the expansion is exactly the code you would write by hand.

```elisp
(defmod vertico
  :init   (setopt vertico-cycle t)   ; startup, before vertico loads
  :config (vertico-mode 1))          ; once vertico has loaded

(defmod foo
  :defer                             ; load only when a trigger fires
  :init (keymap-global-set "C-c f" #'foo-cmd)  ; the trigger
  :config (foo-setup))

(defmod consult-projectile
  :vc (:url "https://example.com/consult-projectile")
  :after (consult projectile)        ; load once both are in
  :config (consult-projectile-mode 1))
```

## Grammar

```
(defmod NAME
  [:vc (SPEC...)]            ; install from VC (package-vc spec) instead of archives
  [:defer | :after (FEATS...)]
  [:init FORMS...]           ; run at startup
  [:config FORMS...])        ; run once NAME has loaded
```

- **Instant (default):** `require` at startup, `:config` right after.
- **`:defer`:** nothing loads at startup; loading rides on the package's own
  autoloads, triggered by whatever you registered in `:init` (a keybinding,
  a hook, an `auto-mode-alist` entry). `:config` waits in
  `with-eval-after-load`.
- **`:after (FEATS...)`:** the package is `require`d the moment all FEATS
  have loaded.
- Every Block installs its package first when missing (package.el, or
  package-vc with `:vc`).
- The grammar is strict: unknown keywords, duplicate keywords, forms outside
  a stage, and `:defer` + `:after` together are expansion-time errors.

There are no operation keywords (`:bind`, `:hook`, `:custom`, ...) and no
conditions (`:when`) — that is plain Elisp, written in a stage or around the
Block. See `CONTEXT.md` for the project glossary and `docs/adr/` for why.

## Development

`nix develop`, then `just ci` (byte-compile with warnings as errors,
package-lint + checkdoc, ERT suite). License: CC0-1.0.
