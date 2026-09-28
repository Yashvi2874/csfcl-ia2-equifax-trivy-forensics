#!/usr/bin/env python3
"""Prints Trivy's vulnerability findings in a form that fits a normal terminal.

Trivy's own table is over 200 characters wide and wraps into noise in a
screenshot. This reads the same JSON Trivy wrote and prints it compactly.

    python scripts/show-cve.py                  every finding, oldest first
    python scripts/show-cve.py CVE-2017-5638    one finding in full
"""

import json
import os
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
REPORT = os.path.join(REPO, "output", "latest", "01-rootfs-vulnerabilities.json")
INTRUSION = "2017-05-13"      # the day the attackers first got in


def load():
    if not os.path.exists(REPORT):
        sys.exit("No scan found. Run: bash scripts/run-investigation.sh")
    with open(REPORT, encoding="utf-8") as fh:
        data = json.load(fh)
    return [v for r in data.get("Results") or [] for v in r.get("Vulnerabilities") or []]


def show_all(vulns):
    vulns = sorted(vulns, key=lambda v: v.get("PublishedDate") or "")
    print("%-11s %-16s %-9s %-24s %s" % ("PUBLISHED", "CVE", "SEVERITY", "FIXED IN", "PUBLIC BEFORE BREACH?"))
    print("-" * 87)
    for v in vulns:
        published = (v.get("PublishedDate") or "")[:10]
        before = "yes" if published and published <= INTRUSION else ""
        print("%-11s %-16s %-9s %-24s %s" % (published, v["VulnerabilityID"], v["Severity"],
                                             (v.get("FixedVersion") or ""), before))
    known = [v for v in vulns if (v.get("PublishedDate") or "9")[:10] <= INTRUSION]
    print("-" * 87)
    print("%d findings in total. %d were public before the intrusion on %s." % (
        len(vulns), len(known), INTRUSION))


def show_one(vulns, cve):
    match = [v for v in vulns if v["VulnerabilityID"] == cve]
    if not match:
        sys.exit("%s is not in the scan results." % cve)
    v = match[0]
    nvd = (v.get("CVSS") or {}).get("nvd", {})
    rows = [
        ("Vulnerability", v["VulnerabilityID"]),
        ("Severity", v["Severity"]),
        ("CVSS 3.1 (NVD)", "%s  %s" % (nvd.get("V3Score", "n/a"), nvd.get("V3Vector", ""))),
        ("Package", v["PkgName"]),
        ("Installed", v["InstalledVersion"]),
        ("Fixed in", v.get("FixedVersion", "")),
        ("Published", (v.get("PublishedDate") or "")[:10]),
        ("Found in", v.get("PkgPath", "")),
        ("Title", v.get("Title", "")),
        ("Reference", v.get("PrimaryURL", "")),
    ]
    for label, value in rows:
        print("  %-15s %s" % (label, value))


if __name__ == "__main__":
    findings = load()
    if len(sys.argv) > 1:
        show_one(findings, sys.argv[1].upper())
    else:
        show_all(findings)
