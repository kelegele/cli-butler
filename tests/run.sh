#!/usr/bin/env bash
# Smoke tests: run every entrypoint, expect exit 69 (not implemented) or 0 (-h).
set -u
cd "$(dirname "$0")/.."
fail=0
for s in bin/*.sh; do
  "$s" -h >/dev/null 2>&1 || { echo "FAIL $s -h"; fail=1; }
done
# library loads and journal helpers behave under a sandboxed journal dir
BUTLER_JOURNAL_DIR="$(mktemp -d)" bash -c '
  . lib/common.sh
  journal_add testcli manual 1700000000 "example-src" "note"
  [ -n "$(journal_get testcli)" ] || { echo "FAIL journal_add/get"; exit 1; }
  journal_del testcli
  [ -z "$(journal_get testcli)" ] || { echo "FAIL journal_del"; exit 1; }
' || fail=1
[ "$fail" = 0 ] && echo "tests: OK"
exit "$fail"
