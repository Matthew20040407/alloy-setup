#!/bin/bash

read -p "Deploy Alloy? [y/N] " answer
case "$answer" in
  [yY][eE][sS]|[yY])
    docker compose -f alloy/docker-compose.yaml up -d
    ;;
  *)
    echo "Aborted."
    ;;
esac
