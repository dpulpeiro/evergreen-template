# Evergreen Framework Template

This repository serves as a template for setting up services using the Evergreen framework. It is designed to streamline the deployment and management of services with a focus on maintaining an evergreen, continuously updated state.

## Features

- **Service Deployment Scripts**: Scripts are included to facilitate the deployment of services.
- **GitHub Action for Docker Swarm**: A GitHub Action is included to sync the state of a remote Docker Swarm with the state of the services.
- **Service Configuration**: Each service within the `services` folder has a `config.yaml` detailing the stack where the service will be deployed.
- **Ansible Playbook**: For easy remote server setup, an Ansible playbook is included.

## Getting Started

### Prerequisites

- Docker and Docker Swarm environment.
- Ansible for running the playbook.
- Understanding of YAML for configuration.

## Configuration

### Service Configuration
Navigate to the `services` folder and configure each service by editing its respective `config.yaml` file. Ensure the stack name and any other necessary parameters are set.

### Ansible Setup
Use the provided Ansible playbook to prepare and configure your remote server environments. Ensure you have the necessary credentials and targets defined.

### GitHub Actions
Review the `.github/workflows` directory to understand the Docker Swarm synchronization action. Customize it as needed for your deployment strategy.

## Usage

After configuring your services and setting up the environment, you can deploy your services using the scripts provided in the `scripts` folder. Ensure you follow any specific instructions or order of operations detailed within each script.
