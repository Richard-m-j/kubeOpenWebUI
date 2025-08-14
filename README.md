# kubeOpenWebUI

kubeOpenWebUI is a project that provides a web user interface for managing Kubernetes infrastructure and deployments with integrated support for Terraform and Docker Compose configurations. It supports automated workflows and scalable infrastructure management, making it easy to deploy, monitor, and manage Kubernetes clusters and related resources.

## Repository Structure

- `.github/` — GitHub Actions workflows for CI/CD automation
- `kubernetes/` — Kubernetes manifests and deployment configurations
- `terraform/` — Infrastructure as Code using Terraform scripts
- `docker-compose.yaml` — Docker Compose file for local or containerized service orchestration
- `setup.md` — Setup instructions and documentation
- `Notes.txt` — General project notes and insights

## Features

- Web UI for Kubernetes cluster and resource management
- Infrastructure provisioning with Terraform
- Deployment automation with Kubernetes manifests and Docker Compose
- CI/CD pipelines with GitHub Actions automation workflows
- Scalable, modular architecture suitable for cloud-native environments

## Getting Started

### Prerequisites

- Kubernetes cluster (local or cloud) and `kubectl` configured
- Terraform installed for infrastructure provisioning
- Docker and Docker Compose for container management
- GitHub account to use CI/CD workflows if applicable

### Setup and Installation

1.  **Clone the repository:**
    ```bash
    git clone [https://github.com/Richard-m-j/kubeOpenWebUI.git](https://github.com/Richard-m-j/kubeOpenWebUI.git)
    cd kubeOpenWebUI
    ```

2.  Follow the instructions in `setup.md` for detailed setup and configuration guidance.

3.  **To deploy Kubernetes resources,** apply manifests inside the `kubernetes/` directory:
    ```bash
    kubectl apply -f kubernetes/
    ```

4.  **To provision infrastructure with Terraform,** navigate to the `terraform/` directory and run:
    ```bash
    terraform init
    terraform apply
    ```

5.  **For local service orchestration,** start with Docker Compose:
    ```bash
    docker-compose up -d
    ```
