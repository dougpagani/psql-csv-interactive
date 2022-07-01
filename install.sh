#!/usr/bin/env bash
########################################
cat >>~/.psqlrc <<'PSQLRC'
\ir '.psql-csv-interactive'
PSQLRC

thisdir=$(dirname $(realpath "$0"))

install=(
ln -s 
    "$thisdir"/psql-csv-interactive.sql
    ~/.psql-csv-interactive
)

"${install[@]}"

