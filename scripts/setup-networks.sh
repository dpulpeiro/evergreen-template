#!/bin/bash

EXISTING_NETWORKS=$(docker network ls --format "{{.Name}}")
# Find all docker-compose.yml files and extract networks
while IFS= read -r file; do
    # Extracting network names assuming they are under "networks:" and marked as external
    networks=$(yq e '.networks | with_entries(select(.value.external == true)) | keys | .[]' "$file")
       for network in $networks; do
           # Check if the network already exists in the list of existing networks
           if ! grep -q "$network" <<< "$EXISTING_NETWORKS"; then
               echo "Creating network: $network"
               docker network create --driver overlay --scope swarm --attachable "$network" || echo "Error creating network: $network"
               # Update the existing networks list
               EXISTING_NETWORKS=$(docker network ls --format "{{.Name}}")
           else
               echo "Network $network already exists, skipping..."
           fi
       done
done < <(find "$1" -name 'docker-compose.yml')
