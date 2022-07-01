#!/usr/bin/env bash
########################################
cat >>~/.psqlrc <<'PSQLRC'
\ir './.psql-csv-interactive'
PSQLRC

thisdir=$(dirname "$0")

install=(
ln -s 
    .psqlrc-csv-interactive
    "$thisdir"/psql-csv-interactive.sql
)

"${install[@]}"

