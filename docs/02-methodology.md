# Methodology

How the examination was carried out, and why each choice was made.

## Tool selection

The IA2 brief asks for tools excluding those covered in the laboratory. Our lab
sessions were:

| Tutorial | Title | Tools covered |
|---|---|---|
| 1 | FTK Imager and Autopsy | Autopsy, FTK Imager, Sleuth Kit, EnCase |
| 2 | Memory Forensics using Volatility | Volatility, DumpIt, WinHex |
| 3 | Network Forensics | Wireshark, NetworkMiner, tcpdump, Snort |
| 4 | Browser Forensics | Autopsy, FTK Imager |

That excludes the tools the generic activity sheet suggests. Trivy was assigned
to our group and appears in none of the lab sessions.

## Why Trivy suits this case

Trivy is a scanner from Aqua Security. It reads files and compares what it finds
against public vulnerability databases. Its scanners map onto the documented
Equifax failures:

| Equifax failure | Scanner |
|---|---|
| Unpatched Struts | `rootfs --scanners vuln` |
| No asset inventory | `--format cyclonedx` |
| Plaintext credentials | `--scanners secret` |
| Weak hardening | `--scanners misconfig` |

## Examination sequence

1. Record SHA-256 hashes of every evidence file before touching anything.
2. Scan compiled artifacts with `trivy rootfs`.
3. Scan the declared dependency manifest with `trivy fs`.
4. Search for credentials with `trivy fs --scanners secret` plus custom rules.
5. Check configuration with `trivy fs --scanners misconfig`.
6. Generate a CycloneDX software bill of materials.
7. Re-hash the evidence and compare against the baseline.
8. Hash every artifact produced.

All of this is in `scripts/run-investigation.sh`, so the examination is
reproducible rather than a sequence of ad-hoc commands.

## Three decisions worth explaining

**`rootfs` rather than `fs` for the JAR.** `trivy fs` only reads dependency
manifests such as `pom.xml`. Pointed at a `.jar` it reports *"Supported files
for scanner(s) not found"* and returns nothing. JAR analysis needs `trivy
rootfs`, which reads compiled artifacts using their embedded Maven metadata.
That is also the better forensic framing, since a rootfs scan is an examination
of a seized filesystem.

**`--offline-scan` everywhere.** Without it, Trivy contacts Maven Central to
resolve transitive dependencies. Maven Central rate-limits, and during
development it returned `429 Too Many Requests` and aborted the scan with a
FATAL error. `--offline-scan` removes that dependency, so the examination cannot
be interrupted by an external service during a live demonstration. The trade-off
is that transitive dependencies are not resolved, which is acceptable because
the `rootfs` scan covers the compiled artifacts directly.

**Custom secret rules.** Trivy's default rules detect well-known token formats
such as AWS keys and GitHub tokens. They do not detect application-specific
password patterns, so the plaintext ACIS database passwords went unfound. Two
custom rules in `scripts/trivy-secret-rules.yaml` fixed that. This is worth
noting in its own right: a scanner finds what its rules describe, so a clean
result is evidence about the rule set as much as about the system.

## Evidence integrity

Hashes are taken before and after examination and compared with `diff`. If they
match, the examination did not modify the evidence.

`.gitattributes` disables Git's line-ending conversion for `evidence/` and
`output/`. Without it Git rewrites LF to CRLF on Windows checkout, which changes
file contents, which changes their hashes. The integrity check would then pass
on one machine and fail on another.

## Limitations

- The evidence set is a reconstruction, not a seized original. It demonstrates
  method rather than the actual Equifax disk.
- A logical image supports no deleted-file recovery.
- A server-side application has no browser artifacts.
- Trivy reports published vulnerabilities only. It cannot find a flaw with no
  CVE, so a clean scan is not proof of a secure system.
- Vulnerability counts change as new CVEs are published against the same
  component versions. Record the scan date alongside any count.
