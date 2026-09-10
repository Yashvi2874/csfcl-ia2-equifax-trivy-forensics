# Case Background: the Equifax Breach, 2017

## What Equifax is

Equifax is one of three large American credit bureaus, alongside Experian and
TransUnion. A credit bureau collects financial information about individuals,
loans, credit cards, repayment history, addresses, dates of birth, and sells
credit reports and scores to lenders.

The people whose data it holds are not its customers. They never signed up and
cannot opt out. Banks supply the data. In the United States that includes Social
Security Numbers, which function as a national identity number for financial
purposes.

That is what makes the breach serious. The victims had no relationship with the
company that lost their data.

## The vulnerability

**CVE-2017-5638**, disclosed 7 March 2017, published as Apache Struts advisory
S2-045. CVSS v3 base score 9.8.

Apache Struts is a Java framework used to build web applications. The flaw was
in the Jakarta Multipart parser, the part that handles file uploads. A malformed
`Content-Type` HTTP header was passed into an OGNL expression evaluator instead
of being treated as text, so an attacker could put an expression in that header
and have the server execute it.

The result is remote code execution: the attacker runs commands on the server
without needing any credentials. Affected versions were Struts 2.3.5 to 2.3.31
and 2.5 to 2.5.10. Fixed in 2.3.32 and 2.5.10.1, released the same day as the
disclosure.

The ACIS host in this case study runs `struts2-core 2.5.10`, inside the affected
range by one release.

## Timeline

| Date (2017) | Event |
|---|---|
| 7 March | CVE-2017-5638 published, patch released the same day |
| 8 March | US-CERT notifies Equifax |
| 9 March | Equifax internal instruction to patch within 48 hours. ACIS not patched |
| 15 March | Vulnerability scan run, fails to detect the unpatched host |
| 13 May | Attackers exploit CVE-2017-5638 and gain access |
| May to July | Plaintext credentials found, used to reach 48 unrelated databases. Roughly 9,000 queries run. Data copied out in small encrypted chunks |
| 29 July | Expired certificate on the traffic inspection device renewed. Exfiltration becomes visible immediately |
| 30 July | ACIS taken offline. Intrusion had run 76 days |
| 7 September | Public disclosure. Approximately 147 million people affected |

## The five failures

The breach was not one clever attack. It was five ordinary failures stacked.

**1. An unpatched known vulnerability.** The fix existed for 65 days before the
intrusion. It was never applied to the ACIS host.

**2. No accurate asset inventory.** Equifax could not reliably answer which of
its servers ran Struts. You cannot patch what you do not know you have. The 15
March scan missed the host partly for this reason.

**3. Plaintext credentials.** Database usernames and passwords were stored
unencrypted on a file share. One foothold became access to 48 databases.

**4. No network segmentation.** A public-facing web server could reach internal
databases unrelated to its function.

**5. Blind monitoring.** The device that should have detected the theft had an
expired certificate and could not inspect encrypted traffic. It had been blind
for months. Renewing the certificate revealed the breach within hours.

## Aftermath

The chief executive resigned. Equifax settled with the Federal Trade Commission
and other US regulators for up to $700 million. No criminal charges were brought
against the company.

## Why this pairs with Trivy

Each failure maps onto a Trivy capability:

| Failure | Trivy capability |
|---|---|
| 1. Unpatched Struts | `rootfs --scanners vuln` finds CVE-2017-5638 |
| 2. No asset inventory | `--format cyclonedx` produces an SBOM |
| 3. Plaintext credentials | `--scanners secret` with custom rules |
| 4, 5. Weak hardening | `--scanners misconfig` |

The examination in this repository asks whether the breach was detectable in
advance. It was. A scan of the evidence set completes in under four seconds and
reports CVE-2017-5638 as its highest-severity finding.

## Sources

- US Government Accountability Office, GAO-18-559
- US House Committee on Oversight and Government Reform, December 2018
- NVD entry for CVE-2017-5638
- Apache Struts advisory S2-045
