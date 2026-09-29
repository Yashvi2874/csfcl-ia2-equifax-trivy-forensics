# Forensic examination of the Equifax 2017 breach, using Trivy

**Case CSFCL-IA2-2026-005** · Cyber Security Forensics and Compliance Laws, IA2

| | |
|---|---|
| Examiners | Yashasvi Gupta (16010123341), Shubhpreet Kaur (16010123328), Shweta Karandikar (16010123329) |
| Tool | [Trivy](https://trivy.dev/) 0.74.0 (Aqua Security) |
| Repository | https://github.com/Yashvi2874/csfcl-ia2-equifax-trivy-forensics |

## What this is

In 2017 Equifax lost the personal data of about 147 million people. The way in
was one web server running Apache Struts with a known flaw, CVE-2017-5638. The
fix had been public for 67 days when the attackers got in.

This repository rebuilds the vulnerable server as a small evidence set and
examines it with Trivy, asking one question: **could the attack have been seen
before it happened?**

It could. A scan of the evidence takes a few seconds and reports CVE-2017-5638
as its top finding.

## Why Trivy

The breach came down to one vulnerable software component that nobody had
patched. Trivy reads a system's files without running them, works out which
software and versions are present, and matches them against public
vulnerability databases. The same tool finds passwords left in files, checks
configuration for unsafe settings, and writes a list of every component it
found. That lets us rebuild a version of the Equifax server and show each
failure happening on real software, found by a real tool. Trivy only reads
files, so the evidence is never run or changed.

## Repository layout

```
evidence/acis-portal/      the seized filesystem (a rebuilt Equifax server)
  lib/struts2-core-2.5.10.jar   the real, vulnerable Apache Struts library
  config/                       plaintext credentials, keys, environment file
  pom.xml                       declared libraries
  Dockerfile                    how the server is built
scripts/
  install-trivy.sh          installs Trivy into ~/bin, no admin rights
  run-investigation.sh      the whole examination in one command
  show-cve.py               prints the vulnerability findings as a table
  summarise.py              prints the closing summary
  trivy-secret-rules.yaml   custom rules for the ACIS credentials
output/                     the results of one examination run, committed as evidence
report/
  CSFCL-IA2-2026-005-Forensic-Report.docx    the forensic report
  CSFCL-IA2-2026-005-Presentation.pptx        the presentation
```

## How to reproduce the examination

Works on Windows (Git Bash), macOS and Linux.

```bash
git clone https://github.com/Yashvi2874/csfcl-ia2-equifax-trivy-forensics.git
cd csfcl-ia2-equifax-trivy-forensics

bash scripts/install-trivy.sh      # installs Trivy into ~/bin
bash scripts/run-investigation.sh  # runs every scan and hashes everything
```

The script writes a new timestamped folder under `output/`, and also copies it
to `output/latest/`. The `output/` folder already holds one committed run so the
results can be read without running anything. Add `--offline` to the run command
on a machine with no internet, once Trivy's database has been downloaded once.

Nothing vulnerable is ever executed. Trivy reads the files the way you can list
what is inside a zip archive without running the programs in it.

## Headline findings

- **CVE-2017-5638**, critical, CVSS 3.1 score 9.8, in `struts2-core 2.5.10`,
  fixed in 2.3.32 and 2.5.10.1. This is the flaw that breached Equifax.
- Of 21 flaws Trivy lists in the library today, only 2 were public before the
  intrusion on 13 May 2017, and only one of those was critical: CVE-2017-5638.
- 11 secrets across 4 files, including four plaintext database passwords.
- 5 failed configuration checks, including the server running as root.
- Evidence integrity: every file's SHA-256 hash was identical before and after
  the examination, so nothing was altered.

## The data is synthetic

Every credential, key and hostname under `evidence/` is invented for coursework.
Only the Struts library is a real file. See
[`evidence/SYNTHETIC-DATA-NOTICE.md`](evidence/SYNTHETIC-DATA-NOTICE.md). No real
Equifax system, customer record or credential appears anywhere here.

## Sources

- US Government Accountability Office, *Actions Taken by Equifax and Federal
  Agencies in Response to the 2017 Breach*, GAO-18-559 (2018).
- US House Committee on Oversight and Government Reform, *The Equifax Data
  Breach* (December 2018).
- NVD entry for CVE-2017-5638; Apache Struts security bulletin S2-045.
