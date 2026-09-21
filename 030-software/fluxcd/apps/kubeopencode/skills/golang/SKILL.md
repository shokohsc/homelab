---
name: golang
description: MUST load whenever writing or modifying Go code.
---

Prefer:

- stdlib
- context propagation
- explicit errors
- slog
- table driven tests
- small packages
- constructors only when useful

Avoid:

- interface pollution
- globals
- reflection
- hidden goroutines
- panic except fatal startup
