#!/bin/bash
#
# Ensure that the specified Docker image exists, building it if
# necessary.

set -ex

here=$(dirname "$0")
name="$1"
if [ -z "$name" ]; then
    echo >&2 Usage: $(basename "$0") IMAGE-NAME
    exit 64
fi
id=$(docker images -q ${name})
if [ -z "$id" ]; then
    docker build -t "$name" "$here"/"$name"
fi

