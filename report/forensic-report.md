# Forensic Examination Report

**Case CSFCL-IA2-2026-005**

| | |
|---|---|
| Case title | Forensic examination of the ACIS dispute portal |
| Case study | Equifax data breach, 2017 |
| Examiners | Yashasvi Gupta (16010123341), Shubhpreet Kaur (16010123328), Shweta Karandikar (16010123329) |
| Subject | CSFCL, IA2 |
| Primary tool | Trivy 0.74.0 (Aqua Security) |
| Supporting tools | sha256sum / shasum, CycloneDX 1.7 |
| Examination date | _fill in on the day you run it_ |
| Report date | _fill in_ |

---

## 1. Aim

To examine a reconstructed image of the Equifax ACIS dispute portal, verify the
integrity of that evidence, identify the vulnerability that allowed the 2017
breach, locate exposed credentials and configuration weaknesses, build a
timeline of events, and assess the findings against Indian law.

The investigation question is:

> What activities and digital evidence can be identified from the forensic
> image, and what sequence of events can be established from the artifacts?

## 2. Tools used

| Tool | Version | Purpose |
|---|---|---|
| Trivy | 0.74.0 | Vulnerability, secret, misconfiguration and SBOM analysis |
| sha256sum / shasum | GNU coreutils / macOS | Evidence hashing |
| CycloneDX | 1.7 | SBOM output format |
| Git | 2.x | Evidence versioning and chain of custody |

Our lab sessions covered FTK Imager, Autopsy, Volatility, Wireshark and
NetworkMiner. The IA2 brief excludes tools covered in the laboratory, so this
examination uses Trivy instead. Trivy was not used in any lab session.

## 3. Evidence handling

The rules followed throughout:

- The evidence set was hashed before examination and again afterwards.
- No evidence file was opened for writing at any point.
- Trivy reads files only. It does not modify what it scans.
- No vulnerable software was executed. Nothing was installed, no service was
  started, and no network listener was opened.
- All findings are traceable to a file and line number in the output.

---

## Activity 1 — Evidence identification

| Parameter | Observation |
|---|---|
| Evidence type | Reconstructed application filesystem (directory tree) |
| Evidence path | `evidence/acis-portal/` |
| File count | 7 |
| Total size | ~1.6 MB |
| Key artifact | `lib/struts2-core-2.5.10.jar` (1,632,834 bytes) |
| Acquisition | Reconstructed from the component versions documented in GAO-18-559 |
| Hash algorithm | SHA-256 |

**What type of forensic image was provided?**

A logical image, meaning a copy of the files and directory structure rather than
a bit-for-bit copy of a whole disk. A physical image would also capture
unallocated space and deleted file remnants. The distinction matters for
Activity 6 and is addressed there.

**What is the purpose of creating a forensic image?**

So the original evidence can be preserved untouched while examination happens on
a copy. If the examination corrupts something, the original is still intact, and
the hash of the original proves it was never altered.

**Why should the original evidence not be analysed directly?**

Opening a file can change its access timestamp. Running a tool against a live
system changes memory and can overwrite deleted data. Any of these turn the
evidence into something the defence can argue was contaminated. Working on a
verified copy avoids that.

---

## Activity 2 — Hash verification

Hashes were recorded before examination and recomputed afterwards. Both sets
are committed in the output directory.

| File | SHA-256 |
|---|---|
| `Dockerfile` | `187488120a5b2f1ec53a6406ad9c5109cfde74e0df606d51cd98b7279af50d77` |
| `config/.env` | `286edecd5b361431fb3312be0aba9dfa71aab0fbf07ac93589717d47be91dce0` |
| `config/acis-backup.pem` | `b59a33dccce23d8c2a2347e03b17753064239232ee5e2df6fd8eacc89d1c90ce` |
| `config/aws-credentials` | `ac80b7424ec90237014e5177843ebd7d4db52768a5aa35b8ddb048b6678a2617` |
| `config/database.properties` | `d1f5a1320a15b8389f9e316545e5b8c92cb2c74168881ba2c27580a83b5b7062` |
| `lib/struts2-core-2.5.10.jar` | `7389713131d3f85aff34f09d8ef15d14e12a1d940b987aed72f148c1f6c36af2` |
| `pom.xml` | `1fa533b14d30ad81fc653530221e5c381ae2f6143aa60513db155150e6ae0d1d` |

**Result: PASS.** All seven hashes were identical before and after the
examination, confirming no evidence file was modified.

Source files: `evidence-hashes-before.txt`, `evidence-hashes-after.txt`.

**What is a hash value?**

A fixed-length fingerprint calculated from a file's contents. SHA-256 always
produces 64 hexadecimal characters regardless of input size.

**Why is hashing important in digital forensics?**

Because it makes tampering detectable. Changing one bit of a file changes
roughly half the bits of its hash, so any alteration is obvious. It is not
feasible to construct a different file with the same SHA-256 hash.

**What does a matching hash indicate?**

That the file is byte-for-byte identical to when the hash was taken. It does not
say anything about whether the file is genuine or who created it, only that it
has not changed.

---

## Activity 3 — Case creation

Trivy has no case-management interface, so the case structure was created
explicitly by the examination script.

| Parameter | Observation |
|---|---|
| Case ID | CSFCL-IA2-2026-005 |
| Examiners | Gupta, Kaur, Karandikar |
| Case directory | `output/<UTC timestamp>/` |
| Evidence source | `evidence/acis-portal/` |
| Scanners run | vuln (rootfs), vuln (manifest), secret, misconfig, SBOM |
| Output formats | JSON (machine-readable), table (human-readable) |

Each run writes to a directory named with the UTC timestamp, so repeated
examinations never overwrite each other. This is the equivalent of opening a new
case in Autopsy.

---

## Activity 4 — Filesystem examination

Two scans were run. `trivy rootfs` reads compiled artifacts using their embedded
Maven metadata and Trivy's local Java database. `trivy fs` reads the declared
dependency manifest.

**Results**

| Scan | Findings | Critical | High | Medium |
|---|---|---|---|---|
| `rootfs` (compiled artifacts) | 21 | 7 | 10 | 4 |
| `fs` (declared dependencies) | 86 | 22 | 52 | 12 |

**Files identified**

| S.No. | Filename | Path | Type | Significance |
|---|---|---|---|---|
| 1 | `struts2-core-2.5.10.jar` | `lib/` | Java library | The vulnerable component. Root cause of the breach |
| 2 | `pom.xml` | `/` | Maven manifest | Declares four outdated dependencies |
| 3 | `database.properties` | `config/` | Config | Three plaintext database passwords |
| 4 | `aws-credentials` | `config/` | Config | Two AWS key pairs |
| 5 | `acis-backup.pem` | `config/` | Private key | Unprotected RSA private key |
| 6 | `.env` | `config/` | Config | Session secret and GitHub token |
| 7 | `Dockerfile` | `/` | Build definition | Five hardening failures |

**Which file system is present?**

The evidence is a logical directory tree rather than a mounted filesystem image,
so no filesystem type is recorded. On the original Equifax host the application
ran on Linux under Apache Tomcat.

**Which operating system appears to be installed?**

The `Dockerfile` specifies `FROM tomcat:latest`, a Debian-based Linux image.

**How many user accounts can be identified?**

One. See Activity 5.

---

## Activity 5 — User account investigation

| S.No. | Username | Evidence location | Relevant activity |
|---|---|---|---|
| 1 | `root` | `Dockerfile:6` (`USER root`) | The application runs with full system privileges |
| 2 | `acis_app` | `database.properties:8` | Application database account |
| 3 | `acis_ro` | `database.properties:11` | Read-only database account |
| 4 | `consumer_svc` | `database.properties:14` | Account for a separate consumer database |
| 5 | `audit_svc` | `database.properties:16` | Account for the audit database |

**Who appears to be the primary user?**

`root`. Trivy finding DS-0002 (HIGH) at `Dockerfile:6` confirms the container
runs as root rather than a dedicated service account.

**What evidence supports this conclusion?**

The explicit `USER root` instruction, flagged by Trivy as
*"Image user should not be 'root'"*.

**Which directories contain user-related information?**

`config/`, which holds every credential file found.

The presence of `consumer_svc` and `audit_svc` credentials on the ACIS host is
significant. It shows this single server held credentials for databases beyond
its own function, which is the condition that allowed the real attackers to
reach 48 unrelated databases.

---

## Activity 6 — Deleted file analysis

No deleted files were recovered, and it is important to say why rather than
leave the section blank.

The evidence set is a logical image. Deleted file recovery depends on reading
unallocated space on a physical disk image, where the file contents survive
until overwritten. A logical image contains only files that currently exist, so
there is nothing to recover from it.

Trivy has no file-carving capability. It is a scanner, not a recovery tool.
Recovering deleted files from this system would require a physical image and a
carving tool such as PhotoRec or Foremost. That is outside the scope of this
examination and outside the capability of the assigned tool.

**Why can deleted files sometimes be recovered?**

Because deleting a file usually removes only its directory entry and marks its
blocks as free. The contents stay on disk until something else writes over them.

**Does deleting a file immediately remove its contents?**

No, not on a conventional magnetic or unencrypted flash volume. On SSDs the TRIM
command can zero blocks quickly, and full-disk encryption makes recovery
impractical, so the answer depends on the storage technology.

**What forensic significance can deleted files have?**

Deletion often indicates intent. A file deleted shortly before seizure is
frequently more interesting than the files left in place.

---

## Activity 7 — Artifact and metadata examination

Trivy identifies Java artifacts from metadata embedded inside the JAR. The JAR
is a ZIP archive, and its internal records carry timestamps and build
information equivalent to EXIF data on a photograph.

**Metadata recovered from `struts2-core-2.5.10.jar`**

| Field | Value |
|---|---|
| Archive format | ZIP, made by v2.0 UNIX |
| Internal build timestamp | 2017-01-27 10:38:42 |
| `pom.properties` groupId | `org.apache.struts` |
| `pom.properties` artifactId | `struts2-core` |
| `pom.properties` version | `2.5.10` |
| Path in evidence | `evidence/acis-portal/lib/` |
| SHA-256 | `7389713131d3f85aff34f09d8ef15d14e12a1d940b987aed72f148c1f6c36af2` |

The build timestamp of 27 January 2017 matters for the timeline. It shows the
component predates the vulnerability disclosure of 7 March 2017, so the software
was already deployed when the flaw became public knowledge. This is the
difference between a zero-day and a failure to patch.

**What information can metadata provide?**

Origin, version, build date, toolchain, and sometimes the author or machine that
produced the artifact. Here it gave the exact library version, which is what
made vulnerability matching possible.

**Did you find useful metadata?**

Yes. The `pom.properties` entry identified the component precisely enough to
match it against 21 published vulnerabilities without needing to look at the
code.

**Can metadata alone prove who created an artifact?**

No. Metadata is written by software and can be edited, stripped or forged. It is
supporting evidence and needs corroboration from an independent source such as a
build server log or a signature.

---

## Activity 8 — Browser artifact analysis

Not applicable to this evidence set, with justification.

Browser artifacts, meaning history, cookies, cache and download records, are
created by a user browsing on a workstation. The evidence here is a server-side
web application. It serves requests, it does not make them, so it has no browser
profile, no history database and no cookie store.

Recording a section as not applicable, with the reason, is standard forensic
practice. Inventing artifacts to fill a template would be misrepresentation.

The equivalent evidence for a server is the web access log. Equifax's own
detection eventually came from network traffic inspection rather than any
browser artifact, once the expired certificate on their inspection device was
renewed on 29 July 2017.

---

## Activity 9 — Keyword and credential search

Trivy's secret scanner was run with a custom rule file,
`scripts/trivy-secret-rules.yaml`, written for this case. The default rules
detect well-known token formats but do not catch application-specific password
patterns, so two custom rules were added to find the ACIS database credentials.

**Findings: 10 secrets across 4 files (8 critical, 2 high)**

| Severity | Location | Rule | Finding |
|---|---|---|---|
| CRITICAL | `config/database.properties:9` | `acis-db-password` | ACIS database password in plaintext |
| CRITICAL | `config/database.properties:15` | `acis-db-password` | Consumer database password in plaintext |
| CRITICAL | `config/database.properties:17` | `acis-db-password` | Audit database password in plaintext |
| CRITICAL | `config/aws-credentials:2` | `aws-access-key-id` | AWS access key ID |
| CRITICAL | `config/aws-credentials:3` | `aws-secret-access-key` | AWS secret access key |
| CRITICAL | `config/aws-credentials:7` | `aws-access-key-id` | Second AWS access key ID |
| CRITICAL | `config/aws-credentials:8` | `aws-secret-access-key` | Second AWS secret access key |
| CRITICAL | `config/.env:4` | `github-pat` | GitHub personal access token |
| HIGH | `config/.env:3` | `acis-session-secret` | Application session secret |
| HIGH | `config/acis-backup.pem:2` | `private-key` | RSA private key |

**Which keyword produced the most significant evidence?**

`db.password`, through the custom `acis-db-password` rule. It found the three
plaintext database passwords in `database.properties`, including credentials for
the consumer and audit databases. This is the artifact that explains how a
single compromised web server became a breach of 48 databases.

**Note on false positives**

An earlier version of this evidence set used Amazon's published example key
`AKIAIOSFODNN7EXAMPLE`. Trivy did not flag it, because that value is
allow-listed to avoid false positives in documentation. The keys were replaced
with synthetic values matching the same format, after which all four were
detected. This is a useful illustration that a scanner's output depends on its
rule set, and that a clean result is not proof of a clean system.

---

## Activity 10 — Configuration and file signature analysis

**Misconfigurations found: 5**

| Severity | ID | Location | Finding |
|---|---|---|---|
| CRITICAL | DS-0031 | `Dockerfile:9` | Secret passed via `ENV` (`DB_PASSWORD`) |
| CRITICAL | DS-0031 | `Dockerfile:10` | Secret passed via `ENV` (`AWS_ACCESS_KEY_ID`) |
| HIGH | DS-0002 | `Dockerfile:6` | Image user should not be `root` |
| MEDIUM | DS-0001 | `Dockerfile:3` | `:latest` tag used for base image |
| LOW | DS-0026 | `Dockerfile` | No `HEALTHCHECK` defined |

**File signature analysis**

No file was found whose contents contradicted its extension. Two observations
are still worth recording:

- `config/aws-credentials` has no extension at all, yet contains credential
  data. Extension-based tooling would skip it. Trivy inspects content, so it was
  scanned regardless.
- `lib/struts2-core-2.5.10.jar` is identified by `file` as *Zip archive data*,
  which is correct. A `.jar` is a ZIP container, and Trivy reads its internal
  structure rather than trusting the extension.

**Why might an investigator deliberately change a file extension?**

To evade tools that classify by extension, to slip a file past an upload filter,
or to hide data in plain sight. It is a weak technique against content-based
analysis, because the file's internal signature, the "magic bytes" at the start,
still identifies the true type.

The `DS-0001` finding on `:latest` is relevant beyond hardening. A floating tag
means the exact base image cannot be determined after the fact, which is a
reproducibility problem for any later investigation.

---

## Activity 11 — Timeline reconstruction

Times are taken from artifact metadata, published CVE records and the
congressional record of the incident.

| Date | Artifact / source | Event |
|---|---|---|
| 2017-01-27 10:38 | JAR internal build timestamp | `struts2-core-2.5.10` built and later deployed to ACIS |
| 2017-03-07 | NVD, CVE-2017-5638 | Vulnerability published. Patch available same day |
| 2017-03-08 | US-CERT notification | Equifax warned to patch |
| 2017-03-09 | Internal Equifax notification | Instruction issued to patch within 48 hours. Not applied to ACIS |
| 2017-03-15 | Equifax vulnerability scan | Scan run, failed to detect the unpatched host |
| 2017-05-13 | Incident record | Attackers exploit CVE-2017-5638 and gain access |
| 2017-05 to 07 | `database.properties` equivalent | Plaintext credentials found and used to reach 48 databases |
| 2017-07-29 | Certificate renewal | Expired certificate on inspection device renewed, exfiltration becomes visible |
| 2017-07-30 | Incident record | ACIS taken offline. 76 days after intrusion |
| 2017-09-07 | Public disclosure | Breach announced, approx. 147 million people affected |

**Sequence**

Vulnerable component deployed → vulnerability disclosed and patch released →
patch not applied to ACIS → scan fails to detect → exploitation → plaintext
credentials enable lateral movement → detection blocked by expired certificate →
detection on certificate renewal → containment and disclosure.

**What sequence can be reconstructed?**

The evidence shows a failure of process rather than a sophisticated attack. The
component was built in January, the flaw was published in March with a patch
available the same day, and the server was still vulnerable in May. Every
technical control that should have caught this, patching, scanning, credential
management, segmentation and traffic inspection, failed independently.

---

## Activity 12 — Evidence correlation

| Evidence A | Evidence B | Evidence C | Correlation |
|---|---|---|---|
| CVE-2017-5638 in `struts2-core-2.5.10` (CVSS 9.8) | Plaintext credentials in `database.properties` | `USER root` in `Dockerfile:6` | Remote code execution as root, with credentials readable on disk. Initial access converts directly into full database access |
| JAR build date 2017-01-27 | CVE published 2017-03-07 | Exploitation 2017-05-13 | The component predates disclosure by six weeks and exploitation followed disclosure by 67 days. This was a patching failure, not a zero-day |
| `consumer_svc` credentials on the ACIS host | `audit_svc` credentials on the same host | No network segmentation | One compromised host carried credentials for unrelated systems, explaining lateral movement to 48 databases |
| `DS-0031` secrets in `ENV` | `DS-0001` `:latest` base image | `DS-0026` no healthcheck | Systemic weakness in build practice, not a single oversight |

**What conclusion can be drawn when multiple independent artifacts support the
same event?**

Confidence increases substantially. A single artifact can be explained away as
misconfiguration, a coincidence or a tool error. When the vulnerability record,
the credential file and the privilege setting all point to the same attack path,
and the timestamps are consistent, the alternative explanations fall away. This
is corroboration, and it is what distinguishes a finding from a guess.

---

## Activity 13 — Evidence tagging

| Evidence ID | Artifact | Location | SHA-256 (first 16) | Reason for selection |
|---|---|---|---|---|
| Evidence-01 | `struts2-core-2.5.10.jar` | `evidence/acis-portal/lib/` | `7389713131d3f85a` | Contains CVE-2017-5638, the breach root cause |
| Evidence-02 | `database.properties` | `evidence/acis-portal/config/` | `d1f5a1320a15b838` | Three plaintext database passwords enabling lateral movement |
| Evidence-03 | `Dockerfile` | `evidence/acis-portal/` | `187488120a5b2f1e` | Root execution and secrets in environment variables |
| Evidence-04 | `aws-credentials` | `evidence/acis-portal/config/` | `ac80b7424ec90237` | Two cloud key pairs exposed |
| Evidence-05 | `acis-backup.pem` | `evidence/acis-portal/config/` | `b59a33dccce23d8c` | Unprotected private key |
| Evidence-06 | `.env` | `evidence/acis-portal/config/` | `286edecd5b361431` | Session secret and version-control token |
| Evidence-07 | `pom.xml` | `evidence/acis-portal/` | `1fa533b14d30ad81` | Declares four outdated dependencies, 86 vulnerabilities |

Full hashes are in `output/<timestamp>/evidence-hashes-before.txt`.

---

## 4. Final findings

| Area | Finding |
|---|---|
| Operating system | Debian Linux via `tomcat:latest` base image |
| File system | Logical directory image, no filesystem metadata captured |
| Primary user | `root`, confirmed by `Dockerfile:6` |
| Important files | 7 evidence files, all tagged Evidence-01 to Evidence-07 |
| Deleted evidence | None recoverable. Logical image, no unallocated space |
| Browser activity | Not applicable. Server-side application |
| Metadata findings | JAR built 2017-01-27, identified as `struts2-core 2.5.10` |
| Vulnerabilities | 21 in compiled artifacts, 86 in declared dependencies |
| Exposed secrets | 10 across 4 files |
| Misconfigurations | 5, including 2 critical |
| Asset inventory | SBOM generated in CycloneDX 1.7 |
| Evidence integrity | PASS, all hashes identical before and after |

**Overall finding**

The examination shows that the compromise of the ACIS portal was preventable and
detectable before it occurred. The component `struts2-core 2.5.10` carried
CVE-2017-5638, rated CVSS 9.8, for which a fix existed in versions 2.3.32 and
2.5.10.1 from 7 March 2017. Six further critical remote-code-execution
vulnerabilities were present in the same component.

The consequences of exploitation were made far worse by two conditions found on
the same host. The application ran as `root`, so code execution meant full system
control. Credentials for the consumer and audit databases were stored in
plaintext on a host that had no functional need for them, so a single foothold
gave access to unrelated systems.

A single Trivy scan of this filesystem, taking under four seconds, reports the
root cause as its highest-severity finding. Had such a scan been part of routine
practice, the vulnerable host would have been identified in March 2017, two
months before exploitation.

The evidence supports a conclusion of inadequate security process rather than a
sophisticated attack.

## 5. Limitations

Stated so the findings are not read more widely than they support:

- The evidence set is a reconstruction based on published incident reports, not
  a seized original. It demonstrates method, not the actual Equifax disk.
- A logical image cannot support deleted-file recovery (Activity 6).
- A server-side application has no browser artifacts (Activity 8).
- Trivy reports known, published vulnerabilities. It cannot find a flaw that has
  no CVE, so a clean scan is not proof of a secure system.
- Vulnerability counts depend on database contents at scan time and will change
  as new CVEs are published against the same component versions.

## 6. Submission checklist

- [x] Original evidence not modified
- [x] Hash values recorded
- [x] Image integrity verified
- [x] Case created
- [x] File system examined
- [x] User accounts identified
- [x] Deleted files addressed (documented as not applicable, with reason)
- [x] Artifacts examined
- [x] Metadata examined
- [x] Browser artifacts addressed (documented as not applicable, with reason)
- [x] Keywords searched
- [x] Timeline created
- [x] Evidence tagged
- [x] Evidence hashes recorded
- [ ] Screenshots included
- [ ] Video recorded

## 7. Sources

- US Government Accountability Office, GAO-18-559, *Actions Taken by Equifax and
  Federal Agencies in Response to the 2017 Breach*
- US House Committee on Oversight and Government Reform, *The Equifax Data
  Breach*, December 2018
- NVD, CVE-2017-5638
- Apache Struts security bulletin S2-045
- Trivy documentation, https://trivy.dev/docs/
