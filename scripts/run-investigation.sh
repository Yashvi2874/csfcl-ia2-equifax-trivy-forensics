#!/usr/bin/env bash
#
# Examines the seized ACIS filesystem with Trivy and hashes everything it
# touches. Case CSFCL-IA2-2026-005, Equifax 2017.
#
# Usage: bash scripts/run-investigation.sh [--offline]
#
# --offline stops Trivy trying to refresh its databases, for a room with no
# internet. It needs the databases to have been downloaded once already.
#
set -euo pipefail

if [ "${1:-}" = "--offline" ]; then
  export TRIVY_SKIP_DB_UPDATE=true TRIVY_SKIP_JAVA_DB_UPDATE=true TRIVY_SKIP_CHECK_UPDATE=true
fi

CASE_ID="CSFCL-IA2-2026-005"
CASE_TITLE="Forensic examination of the ACIS dispute portal (Equifax 2017)"
EXAMINERS="Yashasvi Gupta (16010123341); Shubhpreet Kaur (16010123328); Shweta Karandikar (16010123329)"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
EVIDENCE_DIR="$REPO_ROOT/evidence/acis-portal"
SECRET_RULES="$REPO_ROOT/scripts/trivy-secret-rules.yaml"
STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
OUT_DIR="$REPO_ROOT/output/$STAMP"

# Windows Trivy is a native exe and can't read Git Bash's /c/... paths.
winpath() {
  if command -v cygpath >/dev/null 2>&1; then
    cygpath -w "$1"
  else
    printf '%s' "$1"
  fi
}

# macOS has shasum, everything else has sha256sum.
sha256() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$1" | awk '{print $1}'
  else
    printf 'NO_HASH_TOOL_AVAILABLE'
  fi
}

find_trivy() {
  local candidate
  for candidate in "$HOME/bin/trivy.exe" "$HOME/bin/trivy"; do
    if [ -x "$candidate" ]; then
      printf '%s' "$candidate"
      return 0
    fi
  done
  if command -v trivy >/dev/null 2>&1; then
    command -v trivy
    return 0
  fi
  return 1
}

log()  { printf '\n==> %s\n' "$*"; }
warn() { printf '[!] %s\n' "$*"; }

if ! TRIVY="$(find_trivy)"; then
  warn "Trivy not found. Run: bash scripts/install-trivy.sh"
  exit 1
fi

if [ ! -d "$EVIDENCE_DIR" ]; then
  warn "Evidence directory missing: $EVIDENCE_DIR"
  exit 1
fi

mkdir -p "$OUT_DIR"

EV_WIN="$(winpath "$EVIDENCE_DIR")"
RULES_WIN="$(winpath "$SECRET_RULES")"

log "Case $CASE_ID"
printf '    Title     : %s\n' "$CASE_TITLE"
printf '    Examiners : %s\n' "$EXAMINERS"
printf '    Trivy     : %s\n' "$("$TRIVY" --version 2>/dev/null | head -1)"
printf '    Evidence  : %s\n' "$EVIDENCE_DIR"
printf '    Output    : %s\n' "$OUT_DIR"

# Activity 2. Baseline hashes first, so we can prove afterwards that the
# examination didn't change anything.
log "Activity 2, recording evidence hashes"
# Plain sha256sum format with no header, so "diff before after" and
# "sha256sum -c" both work on these files directly.
BASELINE="$OUT_DIR/evidence-hashes-before.txt"
find "$EVIDENCE_DIR" -type f | sort | while read -r f; do
  printf '%s  %s\n' "$(sha256 "$f")" "${f#$REPO_ROOT/}"
done > "$BASELINE"
printf '    %s files hashed\n' "$(grep -c '^[0-9a-f]' "$BASELINE" || echo 0)"

# Activity 4. rootfs, not fs. trivy fs only reads dependency manifests and
# returns nothing for a bare .jar.
log "Activity 4, vulnerability scan of seized filesystem"
"$TRIVY" rootfs --scanners vuln --no-progress \
  --format json  -o "$(winpath "$OUT_DIR/01-rootfs-vulnerabilities.json")" "$EV_WIN"
"$TRIVY" rootfs --scanners vuln --no-progress \
  --format table -o "$(winpath "$OUT_DIR/01-rootfs-vulnerabilities.txt")" "$EV_WIN"

# --offline-scan everywhere below. Without it Trivy calls Maven Central, which
# rate-limits and kills the scan with a FATAL 429 partway through.
log "Activity 4, declared dependency scan"
"$TRIVY" fs --scanners vuln --offline-scan --no-progress \
  --format json  -o "$(winpath "$OUT_DIR/02-manifest-vulnerabilities.json")" "$EV_WIN"
"$TRIVY" fs --scanners vuln --offline-scan --no-progress \
  --format table -o "$(winpath "$OUT_DIR/02-manifest-vulnerabilities.txt")" "$EV_WIN"

# Activity 9. The custom rules catch the ACIS database passwords, which Trivy's
# defaults miss because they're an application-specific format.
log "Activity 9, secret and credential search"
"$TRIVY" fs --scanners secret --offline-scan --no-progress \
  --secret-config "$RULES_WIN" \
  --format json  -o "$(winpath "$OUT_DIR/03-secrets.json")" "$EV_WIN"
"$TRIVY" fs --scanners secret --offline-scan --no-progress \
  --secret-config "$RULES_WIN" \
  --format table -o "$(winpath "$OUT_DIR/03-secrets.txt")" "$EV_WIN"

log "Activity 10, misconfiguration scan"
"$TRIVY" fs --scanners misconfig --offline-scan --no-progress \
  --format json  -o "$(winpath "$OUT_DIR/04-misconfigurations.json")" "$EV_WIN"
"$TRIVY" fs --scanners misconfig --offline-scan --no-progress \
  --format table -o "$(winpath "$OUT_DIR/04-misconfigurations.txt")" "$EV_WIN"

# Activity 1. The asset inventory Equifax didn't have.
log "Activity 1, software bill of materials"
"$TRIVY" rootfs --format cyclonedx --no-progress \
  -o "$(winpath "$OUT_DIR/05-sbom-cyclonedx.json")" "$EV_WIN"

log "Activity 2, verifying evidence integrity"
AFTER="$OUT_DIR/evidence-hashes-after.txt"
find "$EVIDENCE_DIR" -type f | sort | while read -r f; do
  printf '%s  %s\n' "$(sha256 "$f")" "${f#$REPO_ROOT/}"
done > "$AFTER"

if diff "$BASELINE" "$AFTER" >/dev/null 2>&1; then
  INTEGRITY="PASS - all evidence hashes identical before and after examination"
else
  INTEGRITY="FAIL - evidence changed during examination"
fi
printf '    %s\n' "$INTEGRITY"

log "Activity 13, hashing produced artefacts"
MANIFEST="$OUT_DIR/artefact-hashes.txt"
{
  printf '# Artefacts produced by this examination\n'
  printf '# Case: %s   Generated (UTC): %s\n' "$CASE_ID" "$STAMP"
  printf '# Algorithm: SHA-256\n'
  printf '\n'
  find "$OUT_DIR" -type f ! -name 'artefact-hashes.txt' | sort | while read -r f; do
    printf '%s  %s\n' "$(sha256 "$f")" "$(basename "$f")"
  done
} > "$MANIFEST"

log "Summary"

# Windows ships a fake python3 on PATH that only prints an advert, so check the
# interpreter actually runs something.
PYTHON_BIN=""
for p in python python3 py; do
  if command -v "$p" >/dev/null 2>&1 && [ "$("$p" -c "print(42)" 2>/dev/null)" = "42" ]; then
    PYTHON_BIN="$p"
    break
  fi
done

if [ -n "$PYTHON_BIN" ]; then
  "$PYTHON_BIN" "$REPO_ROOT/scripts/summarise.py" "$(winpath "$OUT_DIR")" "$INTEGRITY"
else
  printf '    No Python found, raw JSON is in %s\n' "$OUT_DIR"
fi

# Every run keeps its own timestamped folder, but a second run would make
# commands like "cat output/*/..." match two folders and break. output/latest
# always mirrors the newest run, so the demo commands have one fixed path.
rm -rf "$REPO_ROOT/output/latest"
cp -r "$OUT_DIR" "$REPO_ROOT/output/latest"

printf '\n    Written to output/%s (also copied to output/latest)\n' "$STAMP"
printf '    Next: screenshot the .txt reports for the report.\n\n'
