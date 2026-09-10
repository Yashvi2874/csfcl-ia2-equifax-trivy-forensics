# Run and Screenshot Guide

Everything you need to do on the day, in order. Budget about 3 hours for the
whole thing including the video.

Trivy is already installed on Yashasvi's laptop. Shubhpreet and Shweta need to
run the installer once on their own machines.

---

## Step 0 — Setup (15 minutes, each person once)

```bash
git clone git@github.com:Yashvi2874/csfcl-ia2-equifax-trivy-forensics.git
cd csfcl-ia2-equifax-trivy-forensics
bash scripts/install-trivy.sh
```

On a Mac you may see *"trivy cannot be opened because the developer cannot be
verified"*. That is Gatekeeper blocking an unsigned download, not a virus. Clear
it with:

```bash
xattr -d com.apple.quarantine ~/bin/trivy
```

Check it worked:

```bash
~/bin/trivy --version        # macOS and Linux
~/bin/trivy.exe --version    # Windows Git Bash
```

You should see `Version: 0.74.0`.

---

## Step 1 — Run the investigation (15 minutes)

```bash
bash scripts/run-investigation.sh
```

The first run on a new machine downloads Trivy's vulnerability database, around
1 GB, so it takes a few minutes. Later runs take under a minute.

**Screenshot 01** — the summary block at the end. This is the single most
important screenshot in the report. It should show:

```
*** PRIMARY FINDING - the Equifax root cause ***
  CVE-2017-5638   CRITICAL   CVSS v3 9.8
  org.apache.struts:struts2-core 2.5.10  ->  fixed in 2.3.32, 2.5.10.1
Evidence integrity: PASS
```

If the run fails, see Troubleshooting at the bottom before doing anything else.

---

## Step 2 — Capture each activity (30 minutes)

Every command below prints something worth screenshotting. Run them one at a
time so each screenshot has a clean terminal.

Set a shortcut first so the commands are shorter:

```bash
T=~/bin/trivy.exe     # Windows
T=~/bin/trivy         # macOS or Linux
```

### Activity 2 — evidence integrity

```bash
cat output/*/evidence-hashes-before.txt
```

**Screenshot 02** — the seven SHA-256 hashes.

```bash
diff output/*/evidence-hashes-before.txt output/*/evidence-hashes-after.txt && echo "INTEGRITY VERIFIED - no evidence modified"
```

**Screenshot 03** — the `INTEGRITY VERIFIED` line. `diff` printing nothing means
the two files are identical, which is the proof.

### Activity 4 — vulnerabilities

```bash
cat output/*/01-rootfs-vulnerabilities.txt | head -40
```

**Screenshot 04** — the vulnerability table with `struts2-core 2.5.10`.

```bash
grep -A3 "CVE-2017-5638" output/*/01-rootfs-vulnerabilities.txt
```

**Screenshot 05** — CVE-2017-5638 isolated. Zoom in for the video.

### Activity 7 — artifact metadata

```bash
unzip -p evidence/acis-portal/lib/struts2-core-2.5.10.jar META-INF/maven/org.apache.struts/struts2-core/pom.properties
```

**Screenshot 06** — the embedded Maven metadata showing `version=2.5.10` and the
build date of 27 January 2017. This is the metadata equivalent of EXIF data.

### Activity 9 — secrets

```bash
cat output/*/03-secrets.txt
```

**Screenshot 07** — all 10 secrets. Make sure `database.properties` and the
three `acis-db-password` findings are visible, that is the Equifax parallel.

Show the custom rules that found them:

```bash
cat scripts/trivy-secret-rules.yaml
```

**Screenshot 08** — your custom detection rules. This is worth marks. It shows
you extended the tool rather than only running it.

### Activity 10 — misconfigurations

```bash
cat output/*/04-misconfigurations.txt
```

**Screenshot 09** — the five findings, with `USER root` and the two `ENV` secret
findings visible.

### Activity 1 — SBOM

```bash
cat output/*/05-sbom-cyclonedx.json | head -40
```

**Screenshot 10** — the CycloneDX SBOM. Explain that this is the asset inventory
Equifax did not have.

### Activity 13 — artifact hashes

```bash
cat output/*/artefact-hashes.txt
```

**Screenshot 11** — hashes of everything the examination produced.

---

## Step 3 — Save the screenshots

Put them in `screenshots/` using this naming, so they sort correctly and match
the report:

```
screenshots/
  01-summary.png
  02-evidence-hashes.png
  03-integrity-verified.png
  04-vulnerabilities.png
  05-cve-2017-5638.png
  06-jar-metadata.png
  07-secrets.png
  08-custom-rules.png
  09-misconfigurations.png
  10-sbom.png
  11-artefact-hashes.png
```

**Windows**: `Win + Shift + S` opens the snipping tool. **macOS**:
`Cmd + Shift + 4`.

Screenshot the terminal window only, not your whole desktop. Increase the font
size first (`Ctrl +` in most terminals) so the text is readable when the
examiner opens it.

---

## Step 4 — Finish the report (50 minutes)

Open `report/forensic-report.md`. The findings are already filled in from a real
run. What you need to add:

1. **Examination date and report date** at the top, marked `_fill in_`.
2. **Screenshot references.** After each activity, add a line like
   `![Screenshot 05](../screenshots/05-cve-2017-5638.png)`.
3. **Tick the last two checklist boxes** in section 6 once screenshots and video
   are done.
4. **Re-run the numbers if they changed.** Vulnerability counts shift as new
   CVEs are published against the same component versions, so if your run
   reports different totals, use yours and note the scan date. Different numbers
   are not an error, they are the database being newer.

---

## Step 5 — Record the video (45 minutes)

See `docs/video-script.md`. Ten minutes maximum, all three of you speaking.

---

## Step 6 — Push (10 minutes)

```bash
git add -A
git commit -m "added screenshots and finished the report"
git push
```

Then check the repo in a private browser window. You should get a 404, which
confirms it is private. Add your professor as a collaborator under
**Settings → Collaborators**, or they cannot mark it.

---

## Troubleshooting

**`trivy: command not found`**
The installer puts Trivy in `~/bin`, which may not be on your `PATH`. Use the
full path: `~/bin/trivy` or `~/bin/trivy.exe`.

**`429 Too Many Requests` from Maven Central**
The script already passes `--offline-scan` to avoid this. If you see it, you
have run a Trivy command manually without that flag. Add it.

**`bad interpreter: /usr/bin/env bash^M`**
Windows line endings got into a script. `.gitattributes` prevents this, but if
it happens: `sed -i 's/\r$//' scripts/*.sh`.

**Integrity check says FAIL**
An evidence file changed. Restore it with `git checkout -- evidence/` and run
again. Do not edit anything under `evidence/`.

**`Python was not found`** on Windows
The Microsoft Store stub is shadowing real Python. The script works around this
by testing that the interpreter actually runs. If it still appears, install
Python from python.org or ignore it, the JSON output is unaffected.

**Scan returns 0 findings**
Trivy's database did not download. Check your internet connection and run
`~/bin/trivy image --download-db-only`.
