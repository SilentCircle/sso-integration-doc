#!/bin/bash

die() {
    echo $* >&2
    exit 1
}

usage() {
    cat <<'END_USAGE'
    usage: localize.sh|generalize.sh markdown-doc

    localize.sh   - converts all "(images/" paths to "($PWD/images/"
                    to facilitate local editing.
    generalize.sh - converts all "($PWD/images/" paths to "(images/"
                    to work on websites.
END_USAGE
    exit 1
}

(( $# == 1 )) || usage

PROG=$(basename $0 .sh)
MD_FILE="$1"; shift

[[ -f $MD_FILE ]] || die "No file $MD_FILE - giving up."
[[ -d images ]] || die "Expected an images subdirectory - giving up."

CURDIR=$(pwd)

case "$PROG" in
    localize)
        sed -i.orig -e "s,(images/,(${CURDIR}/images/,g" $MD_FILE
        ;;
    generalize)
        sed -i.orig.local -e "s,(${CURDIR}/images/,(images/,g" $MD_FILE
        ;;
    *)
        die "Unknown operation $PROG"
        ;;
esac

