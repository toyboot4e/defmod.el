# Instant loading by default

A Block with no Load Mode keyword `require`s its package at startup and runs `:config` immediately; laziness is opt-in via `:defer` (load when a Trigger fires) or `:after FEATS` (load when the named features have all loaded). We rejected leaf's implicit rule (deferred whenever a trigger keyword like `:bind` is present — impossible here, since ADR-0001 removed trigger keywords) and deferred-by-default (a no-trigger block's `:config` silently never runs; every always-on package needs an extra token). Explicitness won: a `defmod` block does exactly what it says, and grepping `:defer`/`:after` versus their absence gives the complete startup-load picture.

## Consequences

- Startup speed is the user's responsibility per block: an undecorated Block costs a full `require` at startup. The "fast" goal is met by writing `:defer` deliberately, not by inference.
- `:defer` and `:after` are mutually exclusive — they are the same axis (when does the package load), not composable flags.
