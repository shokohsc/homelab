## 2026-10-15

- learned-rules.md: added rule on handling secrets when the encryption key is unavailable.
  - What: placeholder secret manifests + the exact encrypt command instead of plaintext or stalling.
  - Why: a task required adding sops-encrypted secrets but the agent had no key and the repo was public.
  - Benefit: public repos stay leak-free and the change is still deliverable, with a clear hand-off.
## 2026-10-16

- learned-rules: OSS Loki and VictoriaMetrics only support time-based retention (no size cap); set retention to 1 week and size the PVC to fit.

## 2026-10-18

- learned-rules: always run `tofu validate` with the pinned provider after writing Terraform.
  - What: provider schemas enforce value enums that fmt/review miss (routeros `add_default_route` = "yes"/"no").
  - Why: a dual-WAN mikrotik change passed fmt but `tofu validate` rejected `add_default_route = "false"`.
  - Benefit: schema-level mistakes surface in seconds locally instead of at plan/apply time.
