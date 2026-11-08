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
probe() { # probe <timeout_s> <cmd...>; BUTLER_PROBE_TIMEOUT overrides (tests)
  # portable watchdog (macOS lacks coreutils timeout). Capture goes through a
  # temp FILE, not a pipe: a killed command can leave orphaned children holding
  # the capture pipe open, and command substitutions would block on their EOF.
  local t="$1" pid w; shift
  [ -n "${BUTLER_PROBE_TIMEOUT:-}" ] && t="$BUTLER_PROBE_TIMEOUT"
  [ -n "${PROBE_TMP:-}" ] || PROBE_TMP="${TMPDIR:-/tmp}/butler-probe.$$"
  : >"$PROBE_TMP"
  "$@" >"$PROBE_TMP" 2>/dev/null &
  pid=$!
  { sleep "$t" && kill "$pid" 2>/dev/null; } >/dev/null 2>&1 &
  w=$!
  wait "$pid" 2>/dev/null
  kill "$w" 2>/dev/null
  wait "$w" 2>/dev/null
  cat "$PROBE_TMP"
  return 0
}

whatis_desc() { # <name> -> one-line man description via local whatis db (no network)
  probe 5 whatis "$1" 2>/dev/null \
    | LC_ALL=C awk -F' - ' 'NF >= 2 { print $2; exit }'
}

# Channels in probe order; each entry "id|probe-cmd".
CHANNELS="brew:brew npm:npm pnpm:pnpm pipx:pipx uv:uv cargo:cargo gem:gem apt:apt"

# --- platform & path primitives (F1 foundation) ---

is_darwin() {
  local os="${BUTLER_OS_OVERRIDE:-$(uname -s 2>/dev/null)}"
  [ "$os" = "Darwin" ]
}

realpath_safe() { # <path> -> absolute resolved path; falls back to input
  local p="$1" out cur="$1" n=0 target dir
  if out=$(readlink -f -- "$p" 2>/dev/null) && [ -n "$out" ]; then printf '%s\n' "$out"; return 0; fi
  # BSD readlink lacks -f: resolve leaf symlinks iteratively
  while [ -L "$cur" ] && [ "$n" -lt 40 ]; do
    target=$(readlink -- "$cur") || break
    case "$target" in /*) cur="$target" ;; *) cur="$(dirname -- "$cur")/$target" ;; esac
    n=$((n + 1))
  done
  dir=$(cd -- "$(dirname -- "$cur")" 2>/dev/null && pwd -P) || { printf '%s\n' "$p"; return 0; }
  printf '%s/%s\n' "$dir" "$(basename -- "$cur")"
}

is_system_path() { # <abs-path>; darwin-only SIP prefixes (see provenance.md)
  is_darwin || return 1
  local p pre prefixes="${BUTLER_SYSTEM_PREFIXES:-/usr/bin /bin /sbin /usr/sbin}"
  prefixes=$(printf '%s' "$prefixes" | tr ':' ' ')
  p=$(realpath_safe "$1")
  for pre in $prefixes; do
    case "$p" in "$pre"|"$pre"/*) return 0 ;; esac
  done
  return 1
}

kv_field() { # <k> <v> -> sanitized "k=v" + trailing TAB (values must never break TSV parsing)
  local v
  v=$(printf '%s' "${2-}" | tr '\t\r\n' '   ')
  printf '%s=%s\t' "$1" "$v"
}

du_size() { # <path> -> bytes (follows symlinks); dirs via du -sk; missing -> "-"
  local p="$1" s="-"
  if [ -f "$p" ]; then
    s=$(wc -c < "$p" 2>/dev/null) && s=${s//[[:space:]]/} || s="-"
  elif [ -d "$p" ]; then
    s=$(du -sk "$p" 2>/dev/null) && s=$(( ${s%%[[:space:]]*} * 1024 )) || s="-"
  fi
  [ -n "$s" ] || s="-"
  printf '%s' "$s"
}

hist_last_used() { # <name> -> max epoch from zsh-style history, or empty
  local f="${BUTLER_HIST_FILE:-${HISTFILE:-$HOME/.zsh_history}}" e
  [ -f "$f" ] || return 0
  # zsh extended format: ": <epoch>:0;cmd" (epoch 0 = no timestamp, skipped)
  e=$(awk -F':|;' -v n="$1" '{
    e=$2 + 0
    if (e > 0) { line=$0; sub(/^[^;]*;/, "", line)
      if (line ~ "(^|[ /])" n "( |$)" && e > m) m=e }
  } END { if (m) print m }' "$f")
  printf '%s' "${e:-}"
}

# journal.tsv lines: name<TAB>channel<TAB>installed_at_epoch<TAB>source<TAB>note
journal_get() { [ -f "$JOURNAL" ] && awk -F'\t' -v n="$1" '$1==n' "$JOURNAL" || true; }
journal_del() { [ -f "$JOURNAL" ] || return 0; local tmp; tmp=$(mktemp); awk -F'\t' -v n="$1" '$1!=n' "$JOURNAL" >"$tmp" && mv "$tmp" "$JOURNAL"; }
journal_add() { # name channel epoch source note
  mkdir -p "$JOURNAL_DIR"
  printf '%s\t%s\t%s\t%s\t%s\n' "$1" "$2" "$3" "$4" "${5:-}" >>"$JOURNAL"
}
