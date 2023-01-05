#!/bin/bash
set -euo pipefail
cd "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

host=$(hostname)

if [[ ! -f "./host_vars/$host.yml" ]]; then
  host="localhost"
fi

ansible-playbook -i "$host", -c local site.yml "$@"
