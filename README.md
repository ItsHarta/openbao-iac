# GitOps Secret Promotion

This repository manages the promotion of secrets from Staging to Production in OpenBao using a GitOps workflow.

## Workflow

1.  **Develop/Test**: A developer adds or updates a secret in the **Staging** namespace of OpenBao (mount: `stag-keys/`).
2.  **Request Promotion**:
    *   Create a new branch.
    *   Create a new YAML file in `promotions/` describing the promotion (source and destination).
    *   See `promotions/sample.yaml` for the format.
    *   Commit and push the branch.
3.  **Review**: Open a Pull Request. The team reviews the request.
4.  **Promote**:
    *   Once the PR is merged to `main`, the GitHub Action triggers.
    *   An Ansible playbook runs, authenticates to OpenBao, reading the secret from Staging and writing it to Production (namespace: `prod`, mount: `secrets/`).

## Setup

### Prerequisites

*   OpenBao/Vault instance reachable from GitHub Actions.
*   GitHub Repository Secrets configured.
*   Existing Namespaces: `staging` and `prod`.
*   Existing KV Mounts: `staging/stag-keys` and `prod/secrets`.

### OpenBao Configuration

Use the provided script to set up the AppRole and Policies:

```bash
./scripts/setup_openbao.sh
```

### GitHub Secrets

Set the following secrets in your repository:

*   `VAULT_ADDR`: The URL of your OpenBao instance (e.g., `https://openbao.example.com`).
*   `VAULT_ROLE_ID`: The AppRole Role ID (output from setup script).
*   `VAULT_SECRET_ID`: The AppRole Secret ID (output from setup script).

## Directory Structure

*   `promotions/`: Contains the history of secret promotion requests.
*   `ansible/`: Contains the automation logic.
*   `.github/workflows/`: CI/CD definition.
