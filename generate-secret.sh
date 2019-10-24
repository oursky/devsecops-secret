#!/bin/bash -e

ARGS_INOUT=()
SECRET_POOL=()
ARGS_STDOUT=false
ARGS_KEYWORD=GENERATE_SECRET
ARGS_SECRET_LENGTH=48


function usage {
    echo "usage: generate-secret.sh [-k keyword] [-s strength] [file1.in [file1.out]] [file2.in [file2.out]]"
    echo "  -k keyword   Keyword for secret, default to GENERATE_SECRET"
    echo "  -s strength  Secret strength, default 48 bytes before base64."
    echo "               Note: might be less due to removing special characters."
    echo "  file.in      Input template file, if no input specified, default to stdin"
    echo "  file.out     Output file, default to stdout"
}
function parse_arguments {
    local ARGS_IN=""
    local ARGS_OUT=""
    while getopts "hi:o:k:s:" opt; do
        case ${opt} in
        h)
            usage
            exit 0
            ;;
        k)
            ARGS_KEYWORD=$OPTARG
            ;;
        s)
            ARGS_SECRET_LENGTH=$OPTARG
            ;;
        esac
    done
    shift $(expr $OPTIND - 1 )
    while test $# -gt 0; do
        ARGS_INOUT+=("$1::$2")
        if [ -z $2 ]; then
            ARGS_STDOUT=true
            shift
        else
            shift 2
        fi
    done
    if [ ${#ARGS_INOUT[@]} -eq 0 ]; then
        ARGS_INOUT["/dev/stdin"]=""
    fi
    for key in "${ARGS_INOUT[@]}"; do
        local infile="${key%%::*}"
        local outfile="${key##*::}"    
        echo "[I] Input: ${infile} -> ${outfile}";
    done
}
function generate_secret {
    local INFILE=$1
    local OUTFILE=$2
    local KEYWORD=$3
    local STRENGTH=$4
    local TMPFILE="${OUTFILE}.tmp"

    touch "${TMPFILE}"
    # Mix template with current values
    while IFS='' read -r LINE || [[ -n "$LINE" ]]; do
        if [[ "${LINE}" =~ ^[[:space:]]*# ]]; then
            echo "${LINE}" >> "${TMPFILE}"
        elif [[ ${LINE} = *"="* ]]; then
            KEY=${LINE%%=*}
            VALUE=${LINE#*=}
            if [[ ${VALUE} = *"${KEYWORD}"* ]]; then
                echo "${LINE}" >> "${TMPFILE}"
            else
                if [ -f "${OUTFILE}" ]; then
                    OLD=$(grep -o "${KEY}=[^,]*" "${OUTFILE}" | sed 's/\(.*\)=\(.*\)/\2/' | tr -s "[:blank:]")
                else
                    OLD=
                fi
                if [ "${OLD}" = "" ]; then
                    echo "${KEY}=${VALUE}" >> "${TMPFILE}"
                else
                    echo "${KEY}=${OLD}" >> "${TMPFILE}"
                fi
            fi
        else
            echo "${LINE}" >> "${TMPFILE}"
        fi
    done < "${INFILE}"
    # Substitute secrets
    for i in $(seq 1 $(grep -c -e "${KEYWORD}\[.*\]" "${TMPFILE}")); do \
        NAME=$(grep -o -m1 -e "${KEYWORD}\[.*\]" "${TMPFILE}"  | sed -n "s/${KEYWORD}\[\(.*\)\]/\1/p"); \
        if [ -z ${SECRET_POOL[NAME]} ]; then
            SECRET_POOL[NAME]="$(openssl rand -base64 ${STRENGTH} | sed -e 's/[\/|=|+]//g')"
        fi
        sed -i.bak "s/${KEYWORD}\[${NAME}\]/${SECRET_POOL[NAME]}/g" "${TMPFILE}"; \
    done;
    for i in $(seq 1 $(grep -c ${KEYWORD} "$TMPFILE")); do \
        sed -i.bak -e "/${KEYWORD}/{s//$(openssl rand -base64 ${STRENGTH} | sed -e 's/[\/|=|+]//g')/;:a" -e '$!N;$!ba' -e '}' "${TMPFILE}"; \
    done;
    rm -f "$TMPFILE.bak"
    if [ -z ${OUTFILE} ]; then
        cat "${TMPFILE}" && rm -f "${TMPFILE}"
    else
        # backup
        if [ -f "${OUTFILE}" ]; then
            cp -f "${OUTFILE}" "${OUTFILE}.bak"
        fi
        mv "${TMPFILE}" "${OUTFILE}"
    fi
}
function main {
    parse_arguments $@
    if [ -z ${ARGS_KEYWORD} ] || [ -z ${ARGS_SECRET_LENGTH} ]; then
        usage
        exit 0
    fi
    if [ "${ARGS_STDOUT}" != "true" ]; then
        echo "== Secret Generator =="
    fi
    for key in "${ARGS_INOUT[@]}"; do
        local infile="${key%%::*}"
        local outfile="${key##*::}"
        generate_secret "${infile}" "${outfile}" "${ARGS_KEYWORD}" "${ARGS_SECRET_LENGTH}"
    done
    if [ "${ARGS_STDOUT}" != "true" ]; then
        echo "Generated secret of strength ${ARGS_SECRET_LENGTH}."
    fi
}

main $@
