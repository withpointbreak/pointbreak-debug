#!/bin/sh

set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
VERIFY_SCRIPT='scripts/verify-repository-identity.sh'
failures=0

fail() {
    printf 'FAIL: %s\n' "$1" >&2
    failures=$((failures + 1))
}

require_literal() {
    file=$1
    literal=$2
    description=$3

    if ! rg -Fq -- "$literal" "$ROOT/$file"; then
        fail "$description ($file)"
    fi
}

require_absent() {
    file=$1
    description=$2

    if [ -e "$ROOT/$file" ]; then
        fail "$description ($file)"
    fi
}

reject_living_pattern() {
    pattern=$1
    description=$2

    if rg --hidden -iq --pcre2 "$pattern" "$ROOT" \
        --glob '!.git/**' \
        --glob '!LICENSE' \
        --glob "!$VERIFY_SCRIPT"; then
        fail "$description"
    fi
}

require_literal README.md '# Pointbreak Debug' 'README must identify the historical product'
require_literal README.md 'Pointbreak Debug is retired.' 'README must state that Debug is retired'
require_literal README.md "The final release was \`0.2.5\`." 'README must identify the final release'
require_literal README.md \
    '(https://github.com/withpointbreak/pointbreak)' \
    'README must link to the canonical Pointbreak repository'
require_literal LICENSE 'Pointbreak Debug' 'license must identify the historical proprietary product'

for file in \
    scripts/install.sh \
    scripts/install.ps1 \
    CONTRIBUTING.md \
    .github/ISSUE_TEMPLATE/bug_report.yml \
    .github/ISSUE_TEMPLATE/feature_request.yml \
    .github/ISSUE_TEMPLATE/question.yml
do
    require_absent "$file" 'retired repository must not retain an acquisition or contribution path'
done

reject_living_pattern \
    'https?://withpointbreak\.com/install\.(sh|ps1)|scripts/install\.(sh|ps1)' \
    'living content must not contain installer paths or commands'
reject_living_pattern \
    'marketplace\.visualstudio\.com|open-vsx\.org|pointbreak\.pointbreak' \
    'living content must not contain extension acquisition paths'
reject_living_pattern \
    'download\.withpointbreak\.com|releases/download|pointbreak-debug/releases|/cli/' \
    'living content must not contain downloadable Debug artifact paths'
reject_living_pattern \
    'https?://[^[:space:])]+/demo|demo\.withpointbreak\.com' \
    'living content must not contain demo links'
reject_living_pattern \
    'issues/new|github\.com/withpointbreak/pointbreak-debug/(issues|discussions)|ask a question|report a .*bug|support and security|accepting code contributions|we.re here to help|suggesting a feature' \
    'living content must not invite current Debug support or contributions'

if [ "$failures" -ne 0 ]; then
    printf '%s repository retirement assertion(s) failed\n' "$failures" >&2
    exit 1
fi

printf 'Pointbreak Debug repository retirement assertions passed\n'
