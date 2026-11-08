#!/usr/bin/env bash
# cli-butler F: uninstall — safe uninstall (dry-run default). Implementation pending, see docs/REQUIREMENTS.md.
set -u
. "$(dirname "$0")/../lib/common.sh"
[ "${1:-}" = "-h" ] && { usage; exit 0; }
echo "cli-butler: 'uninstall' not implemented yet — see docs/REQUIREMENTS.md" >&2
exit 69  # EX_UNAVAILABLE: planned capability, not yet built
