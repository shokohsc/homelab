---
name: self-improve
description: MUST load after generating or modifying application code. Reviews the solution, identifies objective improvements, updates coding guidance, and refines future behavior without changing project goals.
---

# Continuous Skill Improvement

## Purpose

Improve this skill over time without changing its original purpose.

The objective is to generate production-quality software while continuously refining the development process based on previous mistakes.

---

## Core Principles

These sections must never be removed:

- Simplicity
- Correctness
- Security
- Maintainability
- Small readable code
- Current best practices
- Avoid unnecessary abstractions

---

## After Every Completed Task

Perform a silent review.

Evaluate:

- Was code overly complicated?
- Were unnecessary dependencies introduced?
- Was there duplicated logic?
- Were modern language features ignored?
- Was architecture inconsistent?
- Was security overlooked?
- Was documentation insufficient?
- Was testing forgotten?
- Could a beginner maintain this code?

---

## Improvement Rules

If an improvement is objective rather than stylistic:

1. Update this skill.
2. Keep changes minimal.
3. Never rewrite the whole skill.
4. Remove obsolete guidance.
5. Prefer replacing rather than adding.
6. Keep the total size roughly constant.

---

## Never Modify

Never change:

- Primary objective
- Technology scope
- Simplicity first philosophy
- Security requirements
- Code quality standards

---

## Preferred Development Style

Always produce:

- Practical code
- Complete working examples
- Modern APIs
- Idiomatic Go
- Modern JavaScript
- Small functions
- Clear names
- Minimal dependencies

Avoid:

- Clever code
- Over-engineering
- Enterprise patterns without justification
- Excessive configuration
- Excessive abstraction

---

## Infrastructure Rules

Prefer:

- Kubernetes native
- Stateless services
- Immutable infrastructure
- GitOps
- OCI images
- BuildKit
- Skaffold
- FluxCD
- Talos Linux
- Cilium
- SOPS
- OpenTelemetry

Unless requirements dictate otherwise.

---

## Backend Rules

Prefer:

- Go standard library
- Context-aware APIs
- Structured logging
- Explicit errors
- Dependency injection only when useful
- Interfaces only when they solve a real problem

---

## Frontend Rules

Prefer:

- Vue 3
- Composition API
- Vite
- TypeScript when beneficial
- Fetch API
- Simple reactive state
- Accessibility

Avoid large frameworks unless requested.

---

## Review Loop

Whenever this skill changes:

Generate:

- what changed
- why
- expected benefit

Reject the modification if it increases complexity more than it increases quality.

The skill should evolve slowly through many small improvements rather than occasional large rewrites.

## Persistent Learning

When an objective lesson is discovered:

Append it to:

learned-rules.md

Rules must:

- fit on one line
- be technology agnostic when possible
- remove older contradictory rules
- never exceed 100 rules
