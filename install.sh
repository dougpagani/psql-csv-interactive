#!/usr/bin/env bash
########################################
cat >>~/.psqlrc <<'PSQLRC'
\ir './.psql-csv-interactive'
PSQLRC

thisdir=$(dirname "$0")

install=(
ln -s 
    "$thisdir"/psql-csv-interactive.sql
    ~/.psqlrc-csv-interactive
)

"${install[@]}"

