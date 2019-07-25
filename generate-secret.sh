#!/bin/bash -e

ARGS_IN=/dev/stdin
ARGS_OUT=
ARGS_KEYWORD=GENERATE_SECRET
ARGS_SECRET_LENGTH=48

function usage {
    echo "usage: generate-secret.sh -i .env.in [-o .env] [-k keyword] [-s strength]"
    echo "  -i .env.in     Input template file, default to stdin"
    echo "  -o .env        Output file, default to stdout"
    echo "  -k keyword     Keyword for secret, default to GENERATE_SECRET"
    echo "  -s strength    Secret strength, default 48 bytes before base64, might be less due to removing special characters."
}
function parse_arguments {
    while getopts "hi:o:k:s:" opt; do
        case ${opt} in
        h)
            usage
            exit 0
            ;;
        i)
            ARGS_IN=$OPTARG
            ;;
        k)
            ARGS_KEYWORD=$OPTARG
            ;;
        s)
            ARGS_SECRET_LENGTH=$OPTARG
            ;;
        o)
            ARGS_OUT=$OPTARG
            ;;
        esac
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
    done < ${INFILE}
    # Substitute secrets
    for i in $(seq 1 $(grep -c -e "${KEYWORD}\[.*\]" "${TMPFILE}")); do \
        NAME=$(grep -o -m1 -e "${KEYWORD}\[.*\]" "${TMPFILE}"  | sed -n "s/${KEYWORD}\[\(.*\)\]/\1/p"); \
        sed -i.bak "s/${KEYWORD}\[${NAME}\]/$(openssl rand -base64 ${STRENGTH} | sed -e 's/[\/|=|+]//g')/g" "$TMPFILE"; \
    done;
    for i in $(seq 1 $(grep -c ${KEYWORD} "$TMPFILE")); do \
        sed -i.bak "0,/${KEYWORD}/s/${KEYWORD}/$(openssl rand -base64 ${STRENGTH} | sed -e 's/[\/|=|+]//g')/" "$TMPFILE"; \
    done;
    rm -f "$TMPFILE.bak"
    # backup
    if [ -f "${OUTFILE}" ]; then
        cp -f "${OUTFILE}" "${OUTFILE}.bak"
        mv "${TMPFILE}" "${OUTFILE}"
    else
        cat "${TMPFILE}" && rm -f "${TMPFILE}"
    fi
}
function main {
    echo "== Secret Generator =="
    parse_arguments $@
    if [ -z ${ARGS_IN} ] || [ -z ${ARGS_KEYWORD} ] || [ -z ${ARGS_SECRET_LENGTH} ]; then
        usage
        exit 0
    fi
    generate_secret "${ARGS_IN}" "${ARGS_OUT}" "${ARGS_KEYWORD}" "${ARGS_SECRET_LENGTH}"
}

main $@
