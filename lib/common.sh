#!/usr/bin/env bash
# cli-butler shared library: channel detection, provenance, journal, output.
# POSIX-ish bash; zero third-party deps. See docs/provenance.md for the model.

set -u

BUTLER_VERSION="0.0.1"
JOURNAL_DIR="${BUTLER_JOURNAL_DIR:-$HOME/.config/cli-butler}"
JOURNAL="$JOURNAL_DIR/journal.tsv"

die() { printf 'cli-butler: %s\n' "$*" >&2; exit 1; }

usage() {
  cat <<EOF
cli-butler v$BUTLER_VERSION — local CLI toolkit manager (agent skill)
usage: <script>.sh [options] [args]
docs: docs/REQUIREMENTS.md  status: skeleton, see docs/design.md
EOF
}

have() { command -v "$1" >/dev/null 2>&1; }

# Run a probe command with a timeout so one slow channel can't block listing.
probe() { # probe <timeout_s> <cmd...>
  local t="$1"; shift
  if have timeout; then timeout "$t" "$@" 2>/dev/null
  else "$@" 2>/dev/null; fi
}

# Channels in probe order; each entry "id|probe-cmd".
CHANNELS="brew:brew npm:npm pnpm:pnpm pipx:pipx uv:uv cargo:cargo gem:gem apt:apt"

# journal.tsv lines: name<TAB>channel<TAB>installed_at_epoch<TAB>source<TAB>note
journal_get() { [ -f "$JOURNAL" ] && awk -F'\t' -v n="$1" '$1==n' "$JOURNAL" || true; }
journal_del() { [ -f "$JOURNAL" ] || return 0; local tmp; tmp=$(mktemp); awk -F'\t' -v n="$1" '$1!=n' "$JOURNAL" >"$tmp" && mv "$tmp" "$JOURNAL"; }
journal_add() { # name channel epoch source note
  mkdir -p "$JOURNAL_DIR"
  printf '%s\t%s\t%s\t%s\t%s\n' "$1" "$2" "$3" "$4" "${5:-}" >>"$JOURNAL"
}
