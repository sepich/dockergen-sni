#!/bin/bash
set -e

# Warn if the /var/run/docker.sock does not exist
if ! [ -S /var/run/docker.sock ]; then
  cat >&2 <<-EOT
    ERROR: you need to share your Docker host socket with a volume at /var/run/docker.sock
    Typically you should run with: \`-v /var/run/docker.sock:/var/run/docker.sock:ro\`
    See the documentation at http://git.io/vZaGJ
EOT
  [ "$1" = 'docker-gen' -a "$2" = "-watch" ] && exit 1
fi

exec "$@"
