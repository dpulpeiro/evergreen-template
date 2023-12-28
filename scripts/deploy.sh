#!/bin/bash
SCRIPTS_DIR=$(dirname "$0")
source "$SCRIPTS_DIR"/_functions.sh
COMPOSE_FILE="docker-compose.yml"
CONFIG_FILE="config.yml"
SERVICES_DIR=$(dirname "$SCRIPTS_DIR")


# Helpers
_cluster_state() {
  docker service ls --format '{{ .Name }} {{ .Replicas }}' | \
   awk '{split($2,a,"/"); print "{\"name\":\""$1"\"}"}' | \
   jq -s -c '[.[]]' | jq
}

_desired_state() {
  COMPOSE_FILES=$(find "$1" -name "$COMPOSE_FILE")
  json_outputs=()
  for compose_file in $COMPOSE_FILES
  do
    config_file=$(find_nearest_file "$CONFIG_FILE" "$compose_file")
    stack_name=$(get_stack_name "$config_file")
    output=$( yq e ".services | to_entries | map({\"name\": (\"$stack_name\" + \"_\" + .key)})" -o=json "$compose_file")
    json_outputs+=("$(echo "$output" | jq '.[]')")
  done
  printf '%s\n' "${json_outputs[@]}" | jq -s
}

# Given a path to a docker-compose.yml deploys the stack
compose () {
  compose_file=$1
  stack_path=$(find_nearest_file "$CONFIG_FILE" "$compose_file")
  stack_name=$(get_stack_name "$stack_path")

  setup_file="$(dirname "$compose_file")"/setup.sh
  if test -f "$setup_file"; then
    echo Executing "$setup_file"
    chmod +x "$setup_file"
    (cd "$(dirname "$setup_file")" && sh "$(basename $setup_file)")
  fi
  docker stack deploy \
    --with-registry-auth \
    -c "$compose_file" \
    "$stack_name"
}

# Given a path to a folder deploys all docker-compose.yml in that folder
folder () {
  for dir in "$@"; do
    find "$dir" -name "$COMPOSE_FILE" -print0 | while IFS= read -r -d $'\0' compose_file; do
      compose "$compose_file" || exit 1
    done
  done
}

sync() {
  dir_path=$(dirname "$1")
  if [ -z "$(find "$dir_path" -name "$COMPOSE_FILE")" ]; then
    dir_path=$(dirname "$(find_nearest_file "$COMPOSE_FILE" "$dir_path" )")
  fi
  folder "$dir_path"
}

# Deploys all docker-compose.yml of the given stacks
stack () {
  for s in "$@"; do
    config_files=$(grep -rlnw . -e "$s" 2>&- | grep "$CONFIG_FILE")
    for config_file in $config_files; do
      folder "$(dirname "$config_file")"
    done
  done
}

# Clean
clean(){
  echo "Cleaning services"
  state_current=$(_cluster_state)
  state_desired=$(_desired_state "$SERVICES_DIR")
  services_to_remove=$(jq --argjson current "$state_current" --argjson desired "$state_desired" -n '$current - $desired')
  # Iterate over the JSON array, extract the 'name' field, and remove each service
  echo "$services_to_remove" | jq -r '.[].name' | while read -r service_name; do
    docker service rm "$service_name"
  done
}


related_composes() {
  for path in "$@"; do
    dir_path=$path
    [ -f "$dir_path" ] && dir_path=$(dirname "$dir_path")
    files=$(find "$dir_path" -name "$COMPOSE_FILE")
    if [ -z "$files" ]; then
        find_nearest_file "$COMPOSE_FILE" "$dir_path"
    else
        echo "$files"
    fi
  done | sort | uniq
}

"$@"