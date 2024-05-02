#!/usr/bin/env bash
# GPLv3
# athanasios@akostopoulos.com
set -e
# checks if $1 is in path
function do_we_have() {
    if ! hash $1 &> /dev/null
    then
        echo "[-] $1 not in PATH - whoopsie"
        exit 1
    fi
}

# death before root - Fred Dryer ruled!
function we_root() {
if [ $EUID -eq 0 ]; then
    echo [-] "Must NOT be root - exiting!"
    exit 1
fi
}

dirname="XXX-YOU-SHOULD-NOT-EVER-SEE-ME"
function safe_mkdir() {
    dir_prefix=eml_analysis
    n=1
    while [[ -d "$dir_prefix.${n}" ]] ; do
        n=$(($n+1))
    done
    dirname="$dir_prefix.${n}"
    if [ ! -d "$dirname" ] && [ -e "$dirname" ]; then
        echo "[-] $dirname already exists and not a directory- exiting"
        exit 1
    fi
    # we should be good to go
    mkdir "$dirname"
}

function analyze_eml() {
    if [ $# -ne 1 ]; then
        echo "[-] I need the name of the .eml to analyze"
        exit 1
    fi
    safe_mkdir
    echo "[+] Using $dirname"
    echo "[+] Dumping Structure"
    emlAnalyzer --structure --input "$1" |tee $dirname/eml.structure
    echo "[+] Dumping email headers"
    emlAnalyzer --header --input \"$1\" |tee $dirname/eml.headers
    echo "[+] Dumping tracking elements"
    emlAnalyzer --tracking --input "$1" |tee $dirname/eml.tracking
    echo "[+] Dumping embedded URLs"
    emlAnalyzer --url --input "$1" |tee $dirname/eml.urls
    echo "[+] Listing (NOT extracting) any attachments"
    emlAnalyzer --attachments --input "$1" |tee $dirname/eml.attachment_list
    echo "[+] Extracting text portion of email"
    emlAnalyzer --text --input "$1" |tee $dirname/eml.text
    echo "[+] Extracting HTML portion of email"
    emlAnalyzer --html --input "$1" |tee $dirname/eml.html
    echo "[+] Extracting attachments from email"
    mkdir $dirname/attachments
    emlAnalyzer --extract-all --input "$1" --output $dirname
    echo "[+] Done - Check $dirname"
}

# ready for business!
we_root
do_we_have emlAnalyzer
# summon the goat
goat=$(mktemp)
cp "$@" $goat
analyze_eml $goat
rm $goat
