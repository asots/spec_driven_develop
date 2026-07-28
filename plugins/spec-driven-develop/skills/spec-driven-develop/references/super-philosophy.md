# S.U.P.E.R Architecture Philosophy

> Write code like building with LEGO — each brick has a single job, a standard interface, a clear direction, runs anywhere, and can be swapped at will.

This document defines architectural defaults for development work. Apply the principles relevant to the changed boundary and project type; do not turn them into universal scoring requirements for documentation, tooling, CLI, desktop, embedded, or already-constrained code.

---

## S — Single Purpose

From Unix philosophy.

- Each module, file, and function solves exactly one problem
- Prefer decomposition; power comes from composition
- One skill does one thing, one worker does one thing, one script does one thing

**Litmus test:** if you cannot describe a module's responsibility in a single sentence, it needs to be split.

**Anti-pattern:** a script that fetches data, computes metrics, renders charts, and sends notifications.

**Correct approach:**
```
fetch_data.py  -> data retrieval only, outputs JSON
compute.py     -> computation only, reads JSON writes JSON
render.py      -> rendering only, reads JSON generates HTML
notify.py      -> notification only, reads JSON calls webhook
```

---

## U — Unidirectional Flow

From Clean Architecture.

- Data always flows in one direction: input -> processing -> output
- Dependencies always point inward: outer layers depend on inner layers, inner layers know nothing about outer layers
- No reverse dependencies, no circular calls

**Layered model:**
```
+-------------------------------+
|  Infrastructure (API, DB, UI) |  <- outermost, replaceable at will
+-------------------------------+
|  Adapters (transform, format) |
+-------------------------------+
|  Core business (pure logic)   |  <- innermost, zero external deps
+-------------------------------+
```

**Litmus test:** can the core logic run unit tests with zero external services? If not, the dependency direction is wrong.

---

## P — Ports over Implementation

From Hexagonal Architecture.

- Define interface contracts (data structures, JSON Schema) before writing implementation
- Use intermediate formats (JSON files, standard data structures) to isolate upstream from downstream
- Swapping a data source, a rendering layer, or a notification channel requires zero changes to core logic

**Practices:**
1. Every module's input and output must be a serializable data structure
2. Module boundaries communicate via JSON files or standard data structures; in-process typed objects are fine, but cross-module interfaces must be serializable
3. Define explicit schemas — not "just read the code to figure out the format"

---

## E — Environment-Appropriate

Prefer explicit, portable configuration and dependencies, while respecting the runtime's real constraints.

- Configuration comes from the platform-appropriate source (environment variables, config files, OS settings, or device configuration), not hidden hardcoded assumptions
- Dependencies are explicitly declared; required system capabilities are documented
- Services should keep process state and persistence boundaries explicit
- CLI, desktop, embedded, and offline software may use platform-native files, logs, persistence, and lifecycle rules when those are intentional and documented
- Do not require stdout logging, Cloudflare Workers compatibility, or stateless processes outside a service/runtime context where they apply

**Configuration precedence (high to low):**
```
Project/runtime convention > environment variables or platform settings > config files > safe in-code defaults
```

**Checklist:**
- Are credentials and configuration read from the project's approved source?
- All dependencies explicitly declared in a dependency file?
- Are platform-specific paths, storage, and logging assumptions intentional and documented?
- Can the supported runtime reproduce the behavior without undocumented setup?

---

## R — Replaceable Parts

The natural consequence and ultimate goal of S + U + P + E.

- Any layer can be replaced without affecting others
- Replacement cost is the core metric of architecture quality
- If replacing one component triggers cascading changes in unrelated modules, the architecture is broken

**Replacement matrix:**
| Replacing          | Impact scope       | Correct approach                          |
|:-------------------|:-------------------|:------------------------------------------|
| Data source API    | Adapter layer only | Write new fetcher, output same JSON       |
| Frontend renderer  | Render layer only  | Read same JSON, swap render implementation|
| Notification channel| Notification layer | Swap webhook adapter                      |
| Deployment platform| Deploy config only | Change wrangler.toml or Dockerfile        |
| Programming language| Implementation only| JSON contracts unchanged, rewrite in any language |

---

## Quick Check Card

```
+------------------------------------------+
|         S.U.P.E.R Quick Check            |
|                                          |
|  Select the principles affected by this  |
|  task; do not score unrelated ones.      |
|  S  Does this module do only one thing?  |
|  U  Is the data flow unidirectional?     |
|  P  Are relevant boundaries explicit?    |
|  E  Does it fit the supported runtime?   |
|  R  Can its boundary change without ripple? |
|                                          |
|  Record gaps only when they affect the   |
|  task's acceptance or planned follow-up. |
+------------------------------------------+
```

---

## S.U.P.E.R Code Review Checklist (10 checks)

Run the checks that match the task's declared S.U.P.E.R drivers and changed boundaries. Use all ten for a cross-cutting architecture review or when the task explicitly claims broad S.U.P.E.R improvement. Keep the user-facing README aligned with this scope.

| Check | Principle |
|:------|:----------|
| Every new module/file has exactly one responsibility | S |
| No function does more than one conceptual thing | S |
| Data flows input → processing → output, no reverse deps | U |
| No circular imports introduced | U |
| Cross-module interfaces are schema-defined | P |
| Module I/O is serializable | P |
| No hardcoded paths, URLs, keys, or config values | E |
| All new dependencies explicitly declared | E |
| New modules can be replaced without changes to others | R |
| All tests pass after the change | — |

**Decision rule:** A failed relevant check must be fixed, explicitly deferred with acceptance evidence, or turned into a follow-up task. Unrelated checks are not scored.
