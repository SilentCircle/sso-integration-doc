#!/bin/bash

set -e -E

die() {
    echo $* >&2
    exit 1
}

usage() {
    cat <<END_USAGE
* Adds table of contents to markdown document using Pandoc.
* Replaces existing table of contents if it is demarcated by
<!-- START TOC -->
... toc stuff
<!-- END TOC -->

usage: $(basename $0) markdown-doc-name

END_USAGE
    die ""
}

check_prereqs() {
    [[ -n $(which pandoc) ]] || die "pandoc not found on PATH"
}

# strip_toc_and_tags "filename"
#
# Strip TOC and <a name=""> tags out of existing markdown file.
# The <a> tags tend to mess up the TOC.
# Echo the name of the temp file containing the result.
strip_toc_and_tags() {
    local src_file=$1; shift

    local dest_file=$(mktemp)

    sed -r \
        -e '/<!-- START TOC -->/,/<!-- END TOC -->/d' \
        -e 's!<a name="[^"]+"></a>!!' "$src_file" > "$dest_file"

    echo "$dest_file"
}

# strip_toc "filename"
#
# Strip only TOC out of existing markdown file, leaving in <a> tags.
# Echo the name of the temp file containing the result.
strip_toc() {
    local src_file=$1; shift

    local dest_file=$(mktemp)

    sed -re '/<!-- START TOC -->/,/<!-- END TOC -->/d' \
        "$src_file" > "$dest_file"

    echo "$dest_file"
}

# create_toc "filename"
#
# Create a TOC file from a markdown file, using Pandoc.
# Echo the name of the temp file containing the result.
create_toc() {
    local md_file=$1; shift

    local src_file=$(strip_toc_and_tags "$md_file")
    local dest_file=$(mktemp)
    local template_file=$(mktemp)

    echo -e '<!-- START TOC -->\n$toc$\n<!-- END TOC -->' > "${template_file}"

    pandoc \
        --toc \
        --no-wrap \
        --template="$template_file" \
        -f markdown \
        -t markdown "$src_file" > "$dest_file"

    echo "$dest_file"
}

# add_toc_to_md "filename"
#
# Add TOC to a markdown file, replacing previous TOC.
# Make backup of markdown file in filename.YYMMDDHHmmss.
add_toc_to_md() {
    local orig_md_file=$1; shift
    local toc_file=$(create_toc "$orig_md_file")
    local src_md_file=$(strip_toc "$orig_md_file")
    local dest_md_file=$(mktemp)

    cat "$toc_file" "$src_md_file" > "$dest_md_file"
    mv "$orig_md_file" "${orig_md_file}.$(date +'%Y%m%d%H%M%S')"
    mv "$dest_md_file" "$orig_md_file"
}

#
# main
#

(( $# == 1 )) || usage
check_prereqs
MD_FILE=$1; shift

[[ -r "$MD_FILE" ]] || die "File does not exist: $MD_FILE"

export TMPDIR=$(mktemp -d) # Use this dir for all temp files so that trap can clean up

trap 'trap 2 ; kill -2 $$' 1 2 3 13 15
trap 'rm -rf "${TMPDIR}"' EXIT

add_toc_to_md "$MD_FILE"
