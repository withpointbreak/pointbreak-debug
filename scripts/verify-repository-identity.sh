#!/bin/sh

set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
NEW_REPO="withpointbreak/pointbreak-debug"
OLD_REPO="${NEW_REPO%-debug}"
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

reject_literal() {
    file=$1
    literal=$2
    description=$3

    if rg -Fq -- "$literal" "$ROOT/$file"; then
        fail "$description ($file)"
    fi
}

require_literal README.md '# Pointbreak Debug' 'README must use the Debug product name'
require_literal README.md 'legacy Pointbreak Debug product' 'README must state the legacy-product boundary'
require_literal README.md "$NEW_REPO" 'README must route support to the Debug repository'
require_literal LICENSE 'Pointbreak Debug' 'license must identify the historical proprietary product'

for file in README.md CONTRIBUTING.md SECURITY.md .github/ISSUE_TEMPLATE/question.yml; do
    require_literal "$file" "$NEW_REPO" 'living GitHub links must use the Debug repository'
done

for file in scripts/install.sh scripts/install.ps1; do
    require_literal "$file" "$NEW_REPO" 'installer source URL must use the Debug repository'
    require_literal "$file" 'https://download.withpointbreak.com' 'installer must use the release CDN'
    require_literal "$file" '/cli/' 'installer must use the CLI release contract'
    require_literal "$file" 'Pointbreak Debug Installer' 'installer must identify the Debug product'
    reject_literal "$file" 'api.github.com/repos' 'installer must not query the repository release API'
    reject_literal "$file" 'releases/download' 'installer must not target nonexistent public releases'
done

if rg -n --pcre2 "${OLD_REPO}(?!-debug)" \
    "$ROOT/README.md" \
    "$ROOT/CONTRIBUTING.md" \
    "$ROOT/SECURITY.md" \
    "$ROOT/.github" \
    "$ROOT/scripts/install.sh" \
    "$ROOT/scripts/install.ps1" >/dev/null; then
    fail 'living content still contains the ambiguous pre-rename repository slug'
fi

if [ "$failures" -ne 0 ]; then
    printf '%s repository identity assertion(s) failed\n' "$failures" >&2
    exit 1
fi

printf 'Pointbreak Debug repository identity assertions passed\n'
