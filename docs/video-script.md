# Video Script

Ten minutes maximum. All three members must speak. Timings below add up to 9:30,
leaving buffer.

Record in three takes, one per person, and join them. That is far easier than
getting one continuous ten-minute run right.

**Before recording:** increase your terminal font size, close other windows,
have the screenshots open in order, and do one dry run of your own part.

---

## Part 1 — Yashasvi Gupta (0:00 to 3:00)

*The case, the evidence, and proving we did not tamper with it.*

### 0:00 — Introduction (30s)

> This is our IA2 forensic investigation for CSFCL. I am Yashasvi Gupta, with
> Shubhpreet Kaur and Shweta Karandikar. Our case study is the 2017 Equifax
> breach, and our tool is Trivy from Aqua Security.
>
> We chose Trivy because the IA2 brief asks for tools not covered in the lab.
> Our lab sessions used FTK Imager, Autopsy, Volatility and Wireshark, so all of
> those were excluded. Trivy was not used in any lab session.

### 0:30 — The case (60s)

> In 2017 Equifax lost personal data belonging to about 147 million people.
> Equifax is a credit bureau, so the people affected were never its customers.
> They never signed up and could not opt out.
>
> The way in was a single unpatched server running Apache Struts, vulnerable to
> CVE-2017-5638. That flaw lets an attacker put a command inside an HTTP header
> and have the server run it. The patch was published on the 7th of March 2017.
> The attackers got in on the 13th of May. The fix had been available for
> sixty-five days.
>
> Our investigation asks one question: was this breach detectable before it
> happened?

### 1:30 — The evidence (45s)

*Show Screenshot 02*

> Our evidence set is a reconstruction of that server, based on the component
> versions documented in the US Government Accountability Office report. It has
> seven files: the vulnerable Struts library, the dependency manifest, four
> configuration files and the build definition.
>
> Before examining anything we recorded a SHA-256 hash of every file. A hash is
> a fingerprint. Change one bit and the hash changes completely.

### 2:15 — Integrity proof (45s)

*Show Screenshot 03*

> After the examination we hashed everything again and compared. The two sets
> are identical, so we can prove the examination did not modify the evidence.
> That is the fundamental rule of digital forensics: you work on evidence
> without changing it.
>
> Shubhpreet will now take you through what the examination found.

---

## Part 2 — Shubhpreet Kaur (3:00 to 6:15)

*The live demonstration.*

### 3:00 — Running the scan (45s)

*Run `bash scripts/run-investigation.sh` live, or show Screenshot 01*

> This one command runs the whole examination. It scans for vulnerabilities,
> searches for exposed credentials, checks the server configuration, generates a
> software inventory, and hashes everything it produces.
>
> The whole examination takes under a minute.

### 3:45 — The primary finding (60s)

*Show Screenshot 05*

> Here is the answer to our question. CVE-2017-5638, rated CRITICAL, CVSS 9.8
> out of 10. Package `struts2-core` version 2.5.10, fixed in 2.5.10.1.
>
> This is the exact vulnerability that caused the Equifax breach, and Trivy
> found it in about four seconds. Equifax had two months and did not find it.
>
> We also found six further critical remote code execution flaws in the same
> component, and 86 vulnerabilities across the declared dependencies.

### 4:45 — Credentials (60s)

*Show Screenshot 07, then 08*

> Next, the credential search. Ten secrets across four files. The important ones
> are these three in `database.properties`: plaintext database passwords,
> including credentials for the consumer and audit databases.
>
> That matters because the ACIS server had no business holding them. At Equifax
> this is exactly what turned one compromised web server into a breach of 48
> separate databases.
>
> Trivy's default rules did not catch these, because they are an
> application-specific format. So we wrote our own detection rules. This file is
> ours. That is what found the three passwords.

### 5:45 — Configuration and inventory (30s)

*Show Screenshot 09, then 10*

> The configuration scan found five problems, including the application running
> as root, so code execution means total system control, and two secrets baked
> into environment variables.
>
> Finally the software bill of materials. This is the asset inventory Equifax
> did not have. They could not answer which of their servers ran Struts.
>
> Shweta will now put this in order and explain the legal position.

---

## Part 3 — Shweta Karandikar (6:15 to 9:30)

*Timeline, correlation, Indian law, conclusion.*

### 6:15 — Timeline (60s)

*Show the timeline table from the report*

> Putting the artifacts in order. The Struts library carries an internal build
> timestamp of the 27th of January 2017, so it was already deployed when the
> vulnerability was published on the 7th of March.
>
> That distinction matters. This was not a zero-day. The fix existed before the
> attack. Equifax was warned on the 8th of March, issued an internal instruction
> to patch on the 9th, and ran a scan on the 15th that missed the server.
> Attackers got in on the 13th of May and were not detected for 76 days.

### 7:15 — Correlation (45s)

> No single artifact proves an attack. Three together do.
>
> The vulnerability gives remote code execution. The root setting means that
> execution has full privileges. The plaintext credentials mean the attacker
> immediately reaches other databases. Each is serious. Together they describe a
> complete attack path, and the timestamps are consistent with it.
>
> That is corroboration, and it is what separates a finding from a guess.

### 8:00 — Indian law (60s)

> Our topic requires Indian compliance analysis. This is relevant because
> Equifax operates in India, registered with the Reserve Bank under the Credit
> Information Companies Regulation Act of 2005.
>
> Under Indian law these findings engage section 43A of the IT Act, which
> requires reasonable security practices for sensitive personal data. Passwords
> are classified as sensitive personal data under the 2011 SPDI Rules, so
> storing them in plaintext is a direct failure.
>
> The sharpest point is the CERT-In Directions of 2022. They require reporting a
> data breach within six hours. Equifax took 76 days to detect it and another 40
> to disclose.
>
> Under the DPDP Act 2023 the penalty for failing to take reasonable security
> safeguards reaches 250 crore rupees, and 200 crore for failing to notify.

### 9:00 — Conclusion (30s)

> Our conclusion is that the Equifax breach was preventable and detectable. A
> four-second scan of this evidence reports the root cause as its highest
> finding. Every control that should have caught it, patching, scanning,
> credential management, segmentation and traffic inspection, failed
> independently.
>
> This was a failure of process, not a sophisticated attack. Our full report,
> evidence set and scripts are in the repository. Thank you.

---

## Recording notes

- **Do not read this word for word.** Learn the shape of your part and speak
  naturally. Reading aloud is obvious on camera.
- Say numbers out loud properly: "CVSS nine point eight", "two hundred and fifty
  crore".
- If you fluff a line, pause for two seconds and say it again. Cut the pause in
  editing.
- Free editors: Clipchamp (built into Windows 11), iMovie (Mac), DaVinci
  Resolve.
- Keep it under ten minutes. Going over can cost marks.
- Export at 1080p so the terminal text stays readable.
