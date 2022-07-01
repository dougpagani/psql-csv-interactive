#!/usr/bin/env bash
########################################
cat >>~/.psqlrc <<'PSQLRC'
\ir '.psql-csv-interactive'
PSQLRC

thisdir=$(dirname "$0")

ln -s "$thisdir"/psql-csv-interactive.sql ~/.psql-csv-interactive

