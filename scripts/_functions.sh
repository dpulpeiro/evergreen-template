#!/bin/bash
set -eufo pipefail
IFS=$'\t\n'

BASE_ENV_FILE="$(realpath "$(dirname "$0")"/../.env)"
ENV_FILE="$(realpath "$(dirname "$0")"/../.env.production)"

get_stack_name () {
  config_path=$1
  stack_name=$(yq ".stack" "$config_path" | sed 's/"//g')
  echo "$stack_name"
}

find_nearest_file() {
  file_name=$1
  start_path=$2
  dir=""

  if [ -f "$start_path" ]; then
      dir=$(dirname "$start_path")
  else
      dir=$start_path
  fi

  while [ "$dir" != "/" ]; do
      file_path="$dir/$file_name"
      if [ -f "$file_path" ]; then
          echo "$file_path"
          return
      fi
      dir=$(dirname "$dir")
  done
  echo ""
}

if [ ! -f "$ENV_FILE" ]; then
  cp "$BASE_ENV_FILE" "$ENV_FILE"
fi

# Load environment file
while IFS= read -r environment_var || [[ -n "$environment_var" ]]; do
  if [[ ! $environment_var =~ ^# && ! $environment_var =~ ^$ ]]; then
    export "${environment_var?}"
  fi
done < "$ENV_FILE"

