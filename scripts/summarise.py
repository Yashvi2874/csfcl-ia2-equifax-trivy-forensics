#!/usr/bin/env python3
"""Summarise the Trivy output produced by run-investigation.sh.

Reads the JSON reports written into an output directory and prints a short
findings summary, highlighting CVE-2017-5638 - the vulnerability that caused
the Equifax breach.

Usage:  python summarise.py <output-dir> [integrity-status]
"""

import json
import os
import sys
from collections import Counter


def load(out_dir, name):
    """Load a Trivy JSON report, returning {} if it is absent or unreadable."""
    path = os.path.join(out_dir, name)
    if not os.path.exists(path):
        return {}
    try:
        with open(path, encoding="utf-8") as fh:
            return json.load(fh)
    except (json.JSONDecodeError, OSError):
        return {}


def collect(report, key):
    """Flatten a Trivy report's Results[].<key> lists into one list.

    Trivy stores the scanned file path on the parent result rather than on each
    finding, so copy it onto every item as _Target before flattening.
    """
    out = []
    for result in report.get("Results") or []:
        target = result.get("Target", "?")
        for item in result.get(key) or []:
            item["_Target"] = target
            out.append(item)
    return out


def counts(items):
    return dict(Counter(i.get("Severity", "UNKNOWN") for i in items))


def main():
    if len(sys.argv) < 2:
        print("usage: summarise.py <output-dir> [integrity-status]")
        return 1

    out_dir = sys.argv[1]
    integrity = sys.argv[2] if len(sys.argv) > 2 else "not checked"

    vulns = collect(load(out_dir, "01-rootfs-vulnerabilities.json"), "Vulnerabilities")
    manifest = collect(load(out_dir, "02-manifest-vulnerabilities.json"), "Vulnerabilities")
    secrets = collect(load(out_dir, "03-secrets.json"), "Secrets")
    misconf = [
        m for m in collect(load(out_dir, "04-misconfigurations.json"), "Misconfigurations")
        if m.get("Status") == "FAIL"
    ]

    print("  Vulnerabilities (filesystem) : %3d  %s" % (len(vulns), counts(vulns)))
    print("  Vulnerabilities (manifest)   : %3d  %s" % (len(manifest), counts(manifest)))
    print("  Secrets exposed              : %3d  %s" % (len(secrets), counts(secrets)))
    print("  Misconfigurations            : %3d  %s" % (len(misconf), counts(misconf)))

    # SBOM component count - the asset inventory Equifax lacked.
    sbom = load(out_dir, "05-sbom-cyclonedx.json")
    if sbom:
        print("  SBOM components              : %3d" % len(sbom.get("components") or []))

    print()
    target = [v for v in vulns + manifest if v.get("VulnerabilityID") == "CVE-2017-5638"]
    if target:
        v = target[0]
        cvss = (v.get("CVSS") or {}).get("nvd", {}).get("V3Score", "n/a")
        print("  *** PRIMARY FINDING - the Equifax root cause ***")
        print("    CVE-2017-5638   %s   CVSS v3 %s" % (v.get("Severity"), cvss))
        print("    %s %s  ->  fixed in %s"
              % (v.get("PkgName"), v.get("InstalledVersion"), v.get("FixedVersion")))
        print("    %s" % v.get("Title"))
    else:
        print("  NOTE: CVE-2017-5638 was not present in these results.")

    # The plaintext credentials that turned one foothold into 48 databases.
    acis = [s for s in secrets if str(s.get("RuleID", "")).startswith("acis-")]
    if acis:
        print()
        print("  Plaintext credential exposure (Equifax failure #3):")
        for s in acis:
            print("    %-9s %s:%s  %s"
                  % (s.get("Severity"), os.path.basename(s.get("_Target", "?")),
                     s.get("StartLine"), s.get("Title")))

    print()
    print("  Evidence integrity: %s" % integrity)
    return 0


if __name__ == "__main__":
    sys.exit(main())
