#!/usr/bin/env bash
set -euo pipefail

docker run -d --rm --name gdav-radicale \
	-p 5232:5232 \
	tomsquest/docker-radicale

until curl -sf http://localhost:5232 >/dev/null; do
	sleep 1
done

bash "$(dirname "$0")/create-radicale-collections.sh"
