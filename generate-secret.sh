#!/bin/bash -e

ARGS_IN=
ARGS_OUT=.env
ARGS_KEYWORD=GENERATE_SECRET

function usage {
    echo "usage: generate-secret.sh -i .env.in [-o .env] [-k keyword]"
    echo "  -i .env.in     Input template file"
    echo "  -o .env        Output file, default to .env"
    echo "  -k keyword     Keyword for secret, default to GENERATE_SECRET"
}
function parse_arguments {
    while getopts "hi:o:k:" opt; do
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
        sed -i "s/${KEYWORD}\[${NAME}\]/$(openssl rand -base64 48 | sed -e 's/[\/|=|+]//g')/g" "$TMPFILE"; \
    done;
    for i in $(seq 1 $(grep -c ${KEYWORD} "$TMPFILE")); do \
        sed -i "0,/${KEYWORD}/s/${KEYWORD}/$(openssl rand -base64 48 | sed -e 's/[\/|=|+]//g')/" "$TMPFILE"; \
    done;
    # backup
    if [ -f "${OUTFILE}" ]; then
        cp -f "${OUTFILE}" "${OUTFILE}.bak"
    fi
    mv "${TMPFILE}" "${OUTFILE}"
}
function main {
    echo "== Secret Generator =="
    parse_arguments $@
    if [[ "${ARGS_IN}" = "" || "${ARGS_OUT}" = "" || "${ARGS_KEYWORD}" = "" ]]; then
        usage
        exit 0
    fi
    generate_secret "${ARGS_IN}" "${ARGS_OUT}" "${ARGS_KEYWORD}"
}

main $@
