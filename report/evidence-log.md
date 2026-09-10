# Evidence Log

**Case CSFCL-IA2-2026-005**

Every artifact examined, with its hash and why it was selected. Full hashes are
in `output/<timestamp>/evidence-hashes-before.txt`.

| Evidence ID | Artifact | Location | SHA-256 | Findings | Reason for selection |
|---|---|---|---|---|---|
| Evidence-01 | `struts2-core-2.5.10.jar` | `evidence/acis-portal/lib/` | `7389713131d3f85aff34f09d8ef15d14e12a1d940b987aed72f148c1f6c36af2` | 21 CVEs, 7 critical | Contains CVE-2017-5638, the root cause of the breach |
| Evidence-02 | `database.properties` | `evidence/acis-portal/config/` | `d1f5a1320a15b8389f9e316545e5b8c92cb2c74168881ba2c27580a83b5b7062` | 3 critical secrets | Plaintext passwords for three databases, including two unrelated systems |
| Evidence-03 | `Dockerfile` | `evidence/acis-portal/` | `187488120a5b2f1ec53a6406ad9c5109cfde74e0df606d51cd98b7279af50d77` | 5 misconfigurations | Root execution, secrets in environment variables, floating base image tag |
| Evidence-04 | `aws-credentials` | `evidence/acis-portal/config/` | `ac80b7424ec90237014e5177843ebd7d4db52768a5aa35b8ddb048b6678a2617` | 4 critical secrets | Two cloud key pairs exposed on disk |
| Evidence-05 | `acis-backup.pem` | `evidence/acis-portal/config/` | `b59a33dccce23d8c2a2347e03b17753064239232ee5e2df6fd8eacc89d1c90ce` | 1 high secret | Unprotected RSA private key |
| Evidence-06 | `.env` | `evidence/acis-portal/config/` | `286edecd5b361431fb3312be0aba9dfa71aab0fbf07ac93589717d47be91dce0` | 2 secrets | Session secret and version-control token |
| Evidence-07 | `pom.xml` | `evidence/acis-portal/` | `1fa533b14d30ad81fc653530221e5c381ae2f6143aa60513db155150e6ae0d1d` | 86 CVEs, 22 critical | Declares four outdated dependencies |

## Artifacts produced by the examination

| File | Contents |
|---|---|
| `01-rootfs-vulnerabilities.json` / `.txt` | Vulnerabilities in compiled artifacts |
| `02-manifest-vulnerabilities.json` / `.txt` | Vulnerabilities in declared dependencies |
| `03-secrets.json` / `.txt` | Exposed credentials |
| `04-misconfigurations.json` / `.txt` | Configuration weaknesses |
| `05-sbom-cyclonedx.json` | Software bill of materials |
| `evidence-hashes-before.txt` | Integrity baseline taken before examination |
| `evidence-hashes-after.txt` | Integrity verification taken after examination |
| `artefact-hashes.txt` | SHA-256 of every file above |

Each output file is itself hashed in `artefact-hashes.txt`, so the reports can be
shown to be unaltered after the examination.
