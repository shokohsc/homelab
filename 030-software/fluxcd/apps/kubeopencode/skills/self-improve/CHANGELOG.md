## 2026-10-15

## 2026-10-13
- learned-rules: added 3 rules from the Loki single-binary -> distributed / RustFS migration (object-store buckets need provisioning; SOPS MAC spans unencrypted fields; zero unused Helm component replicas).
- why: these were objective pitfalls hit during the migration, each cost real debugging or blocked a non-destructive change.
- benefit: future object-storage migrations and secret handling avoid the same dead ends.
- learned-rules.md: added rule on handling secrets when the encryption key is unavailable.
  - What: placeholder secret manifests + the exact encrypt command instead of plaintext or stalling.
  - Why: a task required adding sops-encrypted secrets but the agent had no key and the repo was public.
  - Benefit: public repos stay leak-free and the change is still deliverable, with a clear hand-off.
## 2026-10-16

- learned-rules: OSS Loki and VictoriaMetrics only support time-based retention (no size cap); set retention to 1 week and size the PVC to fit.
## 2026-10-18

- learned-rules: `gh pr create` in CI containers needs explicit `--head`/`--base` even after a successful `git push -u`.
- learned-rules: always run `tofu validate` with the pinned provider after writing Terraform.
  - What: provider schemas enforce value enums that fmt/review miss (routeros `add_default_route` = "yes"/"no").
  - Why: a dual-WAN mikrotik change passed fmt but `tofu validate` rejected `add_default_route = "false"`.
  - Benefit: schema-level mistakes surface in seconds locally instead of at plan/apply time.
## 2026-10-19

- learned-rules: a GitHub PAT without the `workflow` scope cannot push changes under `.github/workflows/`.
  - What: put build-time config (e.g. `VITE_API_BASE`) in the Dockerfile/build step instead of a CI workflow edit.
  - Why: the push was rejected until the workflow change was reverted.
  - Benefit: deploy-time config lands without needing an elevated token scope or stalling on a rejected push.
## 2026-10-20

- learned-rules: event-driven config scripts never fire for state that already exists at apply time.
  - What: a mikrotik dhcp-client `script` was meant to rewrite a probe route's gateway, but the lease was already bound so the script never ran; the distance-1 default stayed "active" by recursively resolving its probe through the mobile WAN's default, silently egressing all VLAN traffic via mobile.
  - Why: lease-event scripts only trigger on subsequent lease changes, and recursive check-gateway resolution hides the failure behind an "active" route flag.
  - Benefit: prefer native declarative options (DHCP-installed default with distance) over event scripts, and verify actual egress per VLAN instead of trusting route status or pings to fixed IPs.
