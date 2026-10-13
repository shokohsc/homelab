
## 2026-10-13
- learned-rules: added 3 rules from the Loki single-binary -> distributed / RustFS migration (object-store buckets need provisioning; SOPS MAC spans unencrypted fields; zero unused Helm component replicas).
- why: these were objective pitfalls hit during the migration, each cost real debugging or blocked a non-destructive change.
- benefit: future object-storage migrations and secret handling avoid the same dead ends.
