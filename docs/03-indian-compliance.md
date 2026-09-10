# Indian Compliance Analysis

**Case CSFCL-IA2-2026-005** — assessing the Equifax 2017 findings against Indian
law.

> Academic analysis for coursework, not legal advice. Statutory provisions are
> summarised. Verify current text and commencement status before relying on any
> of it.

---

## 1. Why Indian law applies

The 2017 breach was an American incident, so the obvious question is why Indian
law is relevant at all. Two reasons.

**Equifax operates in India.** Equifax Credit Information Services Private
Limited is registered with the Reserve Bank of India as a credit information
company under the Credit Information Companies (Regulation) Act, 2005. It holds
credit data on Indian citizens. The same failures on Indian infrastructure would
engage Indian law directly.

**Section 1(2) read with Section 75 of the IT Act 2000** gives the Act
extra-territorial reach. It applies to an offence involving a computer resource
located in India, whatever the offender's nationality or location. A breach of
an overseas system holding Indian residents' data can therefore fall within its
scope.

## 2. Statutory framework

| Instrument | Year | Relevance here |
|---|---|---|
| Information Technology Act | 2000, amended 2008 | Core offences, corporate liability for weak security |
| SPDI Rules under s.43A | 2011 | Defines "reasonable security practices" |
| CERT-In Directions under s.70B(6) | 2022 | Six-hour incident reporting, 180-day log retention |
| Digital Personal Data Protection Act | 2023 | Data fiduciary duties, breach notification, penalties |
| Credit Information Companies (Regulation) Act | 2005 | Sector rules for credit bureaus |
| RBI Master Direction on IT Governance, Risk, Controls and Assurance Practices | 2023 | Binding IT controls for RBI-regulated entities |

## 3. Findings mapped to provisions

Each row ties a specific artifact from the examination to the provision it would
engage.

| Finding (evidence ID) | Provision | Analysis |
|---|---|---|
| CVE-2017-5638 unpatched for 67 days (Evidence-01) | **IT Act s.43A** + **SPDI Rule 8** | Rule 8 requires a documented security programme and controls proportionate to the information held. Leaving a CVSS 9.8 remote-code-execution flaw unpatched, when the fix was published and the vendor advisory issued, is difficult to reconcile with "reasonable security practices". Liability under s.43A is compensation without a statutory ceiling since the 2008 amendment. |
| Three plaintext database passwords (Evidence-02) | **SPDI Rule 3** + **Rule 8** | Rule 3 classifies passwords as sensitive personal data. Storing them unencrypted on an internet-facing host contradicts the security programme Rule 8 requires. |
| Application running as `root` (Evidence-03) | **SPDI Rule 8**, **RBI Master Direction 2023** | Least-privilege is a baseline control in IS/ISO/IEC 27001, the standard Rule 8 names as deemed compliance. The RBI direction requires access control commensurate with risk for regulated entities. |
| Cloud keys and private key exposed (Evidence-04, 05) | **IT Act s.43A**, **s.72A** | Exposure enabling onward unauthorised disclosure engages s.72A, punishable with up to three years' imprisonment or a fine up to ₹5 lakh, or both. |
| Credentials for unrelated databases on one host (Evidence-02) | **CICRA s.19, s.20** | A credit information company must adopt privacy principles governing collection, use and disclosure of credit information. Holding unrelated database credentials on a public-facing host defeats containment and undermines those principles. |
| Attacker access and data copying | **IT Act s.43(a), (b), (g)**; **s.66** | Section 43 covers unauthorised access and downloading copies of data. Where the act is dishonest or fraudulent, s.66 makes it an offence carrying up to three years' imprisonment or a fine up to ₹5 lakh, or both. |
| Misuse of stolen identity data | **IT Act s.66C** | Identity theft, up to three years' imprisonment and a fine up to ₹1 lakh. |
| 76-day detection, 40 further days to disclosure | **CERT-In Directions 2022** | Discussed below. |
| No reliable asset inventory | **RBI Master Direction 2023**, **SPDI Rule 8** | An accurate inventory of IT assets is a stated control expectation. Equifax could not determine which hosts ran Struts. |

## 4. The CERT-In timeline problem

This is where the Equifax timeline looks worst under Indian law.

The CERT-In Directions of 28 April 2022, issued under section 70B(6) of the IT
Act, require that specified cyber incidents, including data breaches and data
leaks, be **reported to CERT-In within six hours** of being noticed. The
directions also require ICT system logs to be enabled and retained securely for
**180 days within Indian jurisdiction**, and system clocks synchronised to NTP
servers of NIC or NPL.

Compare with what happened:

| Requirement | Equifax actual |
|---|---|
| Report within 6 hours of noticing | Detected 29 July, disclosed publicly 7 September, 40 days later |
| Retain 180 days of logs | Traffic inspection was blind for months due to an expired certificate |
| Detect and act promptly | Intrusion on 13 May, detection on 29 July, 76 days |

Non-compliance with a section 70B(6) direction is punishable under section
70B(7) with imprisonment up to one year or a fine up to ₹1 lakh, or both.

The expired-certificate failure is the sharpest point. A retention obligation is
not met by keeping logs that record nothing useful. Equifax's inspection device
could not read encrypted traffic, so the exfiltration passed unrecorded for the
entire intrusion window.

## 5. Position under the DPDP Act 2023

The Digital Personal Data Protection Act, 2023 is the framework that would apply
to the same facts today. Under it Equifax would be a **Data Fiduciary** and the
affected individuals **Data Principals**.

| Duty | Section | Equifax position |
|---|---|---|
| Take reasonable security safeguards to prevent a personal data breach | s.8(5) | Unpatched CVSS 9.8 flaw, plaintext credentials, root execution |
| Notify the Data Protection Board and each affected Data Principal of a breach | s.8(6) | 40 days from detection to public disclosure |
| Retain only as long as necessary, then erase | s.8(7) | Credentials for unrelated systems retained on the ACIS host |

**Penalty exposure under the Schedule to the Act**

| Breach of duty | Maximum penalty |
|---|---|
| Failure to take reasonable security safeguards (s.8(5)) | up to **₹250 crore** |
| Failure to notify a personal data breach (s.8(6)) | up to **₹200 crore** |

These are civil penalties determined by the Data Protection Board, applied per
instance of breach of duty rather than per affected individual.

## 6. Sectoral position under CICRA

Because a credit bureau is the subject, CICRA 2005 applies on top of the general
law. Its features relevant here:

- Registration with the RBI is mandatory for a credit information company.
- Section 19 requires the adoption of privacy principles and the maintenance of
  accuracy and security of credit information.
- Section 22 addresses unauthorised access to credit information.
- Section 23 provides for offences by companies, which can reach directors and
  officers responsible for the conduct of business.

The RBI Master Direction on IT Governance, Risk, Controls and Assurance
Practices (2023) adds binding expectations on board-level IT governance, change
management, vulnerability management and incident response for regulated
entities.

The practical consequence is that an Indian Equifax would face a regulator with
direct supervisory powers, in addition to statutory penalties. That is a
materially stronger position than the American outcome, which was a negotiated
settlement of up to $700 million with no criminal liability.

## 7. What compliance would have required

Working backwards from the findings, an equivalent Indian entity would have
needed:

1. **Vulnerability management with evidence.** A recurring scan of production
   assets with recorded results. The Trivy scan in this repository takes under
   four seconds and reports CVE-2017-5638 as its top finding. Running it in
   March 2017 would have identified the host.
2. **An accurate asset inventory.** The SBOM produced in Activity 1 is exactly
   this: a machine-readable list of every component and version.
3. **Credentials outside the filesystem.** A secrets manager rather than
   `database.properties`, so a web-server compromise does not yield database
   access.
4. **Segmentation.** No reason for consumer and audit database credentials to
   exist on the dispute portal host.
5. **Working traffic inspection**, with certificate expiry monitored, so the
   180-day log obligation produces usable records.
6. **A six-hour reporting path**, with a named responsible person and a tested
   procedure. This is an organisational control, not a technical one, and it is
   the one most often missing.

## 8. Conclusion

Assessed against Indian law, the Equifax findings engage section 43A of the IT
Act and the SPDI Rules on reasonable security practices, sections 43, 66, 66C
and 72A for the intrusion and disclosure, the CERT-In Directions on reporting
and logging, and, for a credit bureau, CICRA together with the RBI Master
Direction. Under the DPDP Act 2023 the same facts would expose a data fiduciary
to penalties of up to ₹250 crore for the security failure and up to ₹200 crore
for the notification failure.

The recurring theme is that every provision engaged concerns process rather than
technology. The law does not require perfect security. It requires reasonable
practices, timely reporting and honest records. The examination in this case
found failures in all three.

## 9. References

- Information Technology Act, 2000 (as amended by Act 10 of 2009)
- Information Technology (Reasonable Security Practices and Procedures and
  Sensitive Personal Data or Information) Rules, 2011
- CERT-In Directions under section 70B(6), 28 April 2022
- Digital Personal Data Protection Act, 2023
- Credit Information Companies (Regulation) Act, 2005
- RBI Master Direction on IT Governance, Risk, Controls and Assurance
  Practices, November 2023
- GAO-18-559; US House Oversight Committee report, December 2018
