# Chain of Custody

**Case CSFCL-IA2-2026-005**

A record of who handled the evidence, when, and what was done to it.

## Evidence description

| | |
|---|---|
| Description | Reconstructed filesystem of the Equifax ACIS dispute portal |
| Location | `evidence/acis-portal/` |
| File count | 7 |
| Total size | approximately 1.6 MB |
| Origin | Reconstructed from component versions in GAO-18-559 and the House Oversight Committee report |
| Hash algorithm | SHA-256 |

## Custody record

| Date | Time (IST) | Custodian | Action | Integrity check |
|---|---|---|---|---|
| _fill in_ | _fill in_ | Yashasvi Gupta | Evidence set assembled, baseline hashes recorded | Baseline established |
| _fill in_ | _fill in_ | Yashasvi Gupta | Examination run with Trivy 0.74.0 | PASS, hashes unchanged |
| _fill in_ | _fill in_ | Shubhpreet Kaur | Independent verification run on separate machine | _record result_ |
| _fill in_ | _fill in_ | Shweta Karandikar | Timeline and compliance analysis, no evidence access required | Not applicable |
| _fill in_ | _fill in_ | All | Report finalised, screenshots captured | _record result_ |

Fill in the dates as you actually do each step. Do not backdate entries. An
inaccurate custody record is worse than a sparse one.

## Handling controls

- No evidence file was opened for writing at any point.
- Trivy reads files only. It has no capability to modify what it scans.
- No vulnerable software was executed. No service was started and no network
  listener opened at any time.
- Every examination writes to a new timestamped directory, so no earlier result
  is overwritten.
- Git history provides an independent record of when each file entered the
  repository and what changed.
- `.gitattributes` disables line-ending conversion for `evidence/`, so the files
  stay byte-identical across Windows, macOS and Linux. Without it Git would
  rewrite the files on checkout and the hashes would no longer match.

## Verification by a third party

Anyone can confirm the evidence is unmodified:

```bash
git clone git@github.com:Yashvi2874/csfcl-ia2-equifax-trivy-forensics.git
cd csfcl-ia2-equifax-trivy-forensics
sha256sum evidence/acis-portal/lib/struts2-core-2.5.10.jar
```

The result must be:

```
7389713131d3f85aff34f09d8ef15d14e12a1d940b987aed72f148c1f6c36af2
```

On macOS use `shasum -a 256` instead of `sha256sum`.
