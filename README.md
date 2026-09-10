# Forensic examination of the ACIS dispute portal

Case study of the 2017 Equifax breach, examined with Trivy.

CSFCL (Cyber Security Forensics and Compliance Laws), IA2, case
CSFCL-IA2-2026-005.

| | |
|---|---|
| Examiners | Yashasvi Gupta (16010123341), Shubhpreet Kaur (16010123328), Shweta Karandikar (16010123329) |
| Primary tool | [Trivy](https://trivy.dev/) 0.74.0, Aqua Security |
| Supporting | `sha256sum` / `shasum`, CycloneDX 1.7 |
| Evidence | `evidence/acis-portal/`, 7 files |

## The question

> What activities and digital evidence can be identified from the forensic
> image, and what sequence of events can be established from the artifacts?

In 2017 Equifax lost the personal data of about 147 million people. The way in
was one unpatched server running Apache Struts, vulnerable to CVE-2017-5638. The
patch had been available for 65 days.

This repository rebuilds that server as an evidence set and examines it, asking
something the original investigators could not: was the breach detectable before
it happened?

It was. The scan takes under four seconds and reports the root cause as its
highest-severity finding.

## Why Trivy

The IA2 brief asks for tools not covered in the lab. Our lab sessions used FTK
Imager, Autopsy, Volatility, Wireshark and NetworkMiner, so all of those are
out. Trivy was assigned to our group and was not used in any lab session.

It also fits the case. Each Equifax failure maps to a Trivy scanner:

| Equifax failure | Scanner used |
|---|---|
| Unpatched Struts (CVE-2017-5638) | `trivy rootfs --scanners vuln` |
| No accurate asset inventory | `trivy rootfs --format cyclonedx` |
| Database passwords in plaintext | `trivy fs --scanners secret` with custom rules |
| Weak server hardening | `trivy fs --scanners misconfig` |

## Running it

Works on Windows (Git Bash), macOS and Linux.

```bash
git clone git@github.com:Yashvi2874/csfcl-ia2-equifax-trivy-forensics.git
cd csfcl-ia2-equifax-trivy-forensics

bash scripts/install-trivy.sh      # installs to ~/bin, no admin rights
bash scripts/run-investigation.sh  # runs every scanner, hashes everything
```

Output goes to a timestamped directory under `output/`. The first run downloads
Trivy's vulnerability database, around 1 GB, so give it a few minutes.

Nothing vulnerable is ever executed. Trivy reads files the way you read a zip
archive without running the programs inside it. There is no live service, no
exploit code and no network listener at any point.

## What's here

```
evidence/acis-portal/      the seized filesystem
  lib/                     struts2-core-2.5.10.jar, the vulnerable component
  config/                  plaintext credentials, keys, environment files
  pom.xml                  declared dependencies
  Dockerfile               build definition
scripts/
  install-trivy.sh         cross-platform installer
  run-investigation.sh     the whole examination in one command
  summarise.py             parses Trivy JSON into a findings summary
  trivy-secret-rules.yaml  custom rules for the ACIS credentials
report/
  forensic-report.md       the main report, all 13 activities
  evidence-log.md          every artifact with its hash
  chain-of-custody.md      who handled what, when
docs/
  01-case-background.md    what happened at Equifax and why
  02-methodology.md        how the examination was done
  03-indian-compliance.md  IT Act, SPDI, CERT-In, DPDP, CICRA analysis
  video-script.md          10 minute script, three speaking parts
  run-and-screenshot-guide.md   step by step for the demo
output/                    scan results, committed as evidence
screenshots/               screenshots supporting the report
```

Start with [`report/forensic-report.md`](report/forensic-report.md).

## Findings

| Category | Count |
|---|---|
| Vulnerabilities in compiled artifacts | 21, of which 7 critical |
| Vulnerabilities in declared dependencies | 86, of which 22 critical |
| Exposed secrets | 10, of which 8 critical |
| Misconfigurations | 5, of which 2 critical |

Primary finding:

```
CVE-2017-5638   CRITICAL   CVSS v3 9.8
org.apache.struts:struts2-core 2.5.10  ->  fixed in 2.3.32, 2.5.10.1
struts2: RCE when performing file upload based on Jakarta Multipart parser
```

Evidence integrity was verified before and after the examination. All seven
SHA-256 hashes were identical, so the examination did not alter the evidence.

Counts shift over time as new CVEs are published against the same component
versions. Record the scan date with any figure you quote.

## About the data

Every credential, key and hostname under `evidence/` is invented for coursework.
See [`evidence/SYNTHETIC-DATA-NOTICE.md`](evidence/SYNTHETIC-DATA-NOTICE.md). No
real Equifax system, customer record or credential appears anywhere here.

## Sources

- US Government Accountability Office, GAO-18-559
- US House Committee on Oversight and Government Reform, December 2018
- NVD entry for CVE-2017-5638, Apache Struts advisory S2-045
- [Trivy documentation](https://trivy.dev/docs/)
