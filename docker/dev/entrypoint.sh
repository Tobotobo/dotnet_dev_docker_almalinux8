#!/bin/sh

set -e

for f in $(/usr/bin/find /entrypoint.d/ -type f -name "*.sh"); do
    echo "Executing $f ..."  # ファイル名を出力
    "$f"
done

exec "$@"