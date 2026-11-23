#!/bin/bash

set -e

log () {
  echo "$(date "+%Y-%m-%d %H:%M:%S") [${2:-INFO}]: $1"
}

check_stale_file_handles() {
  local deploy=$1

  log "Looking for stale file handles in deploy/$1"
  kubectl exec -n karakeep "deploy/$1" '--' find /media/movies/wd-zarya -type f | sort
  return_code_movies_wd_zarya=$(echo -n $?)
  kubectl exec -n karakeep "deploy/$1" '--' find /media/movies/wd-lucio -type f | sort
  return_code_movies_wd_lucio=$(echo -n $?)
  kubectl exec -n karakeep "deploy/$1" '--' find /media/movies/wd-sombra -type f | sort
  return_code_movies_wd_sombra=$(echo -n $?)

  kubectl exec -n karakeep "deploy/$1" '--' find /media/tvshows/wd-zarya -type f | sort
  return_code_tvshows_wd_zarya=$(echo -n $?)
  kubectl exec -n karakeep "deploy/$1" '--' find /media/tvshows/wd-lucio -type f | sort
  return_code_tvshows_wd_lucio=$(echo -n $?)
  kubectl exec -n karakeep "deploy/$1" '--' find /media/tvshows/wd-sombra -type f | sort
  return_code_tvshows_wd_sombra=$(echo -n $?)

  if [[ '1' == $return_code_movies_wd_zarya || '1' == $return_code_movies_wd_lucio || '1' == $return_code_movies_wd_sombra \
     || '1' == $return_code_tvshows_wd_zarya || '1' == $return_code_tvshows_wd_lucio || '1' == $return_code_tvshows_wd_sombra ]]; then
    log "Restarting deploy/$1" "WARNING"
    kubectl rollout restart -n karakeep "deploy/$1"
  fi
}

check_stale_file_handles "karakeep"
check_stale_file_handles "karakeep-node"

exit 0
