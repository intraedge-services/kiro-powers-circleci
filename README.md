# kiro-powers-circleci

A Kiro power for CircleCI CI/CD pipeline management, built on the [official CircleCI MCP Server](https://github.com/CircleCI-Public/mcp-server-circleci).

## Quick Start

### 1. Get a CircleCI API Token

Generate a personal API token at: https://app.circleci.com/settings/user/tokens

### 2. Set Environment Variable

```bash
export CIRCLECI_TOKEN="your-token-here"
```

### 3. Install the Power

Copy this directory into your project or reference it in your Kiro workspace.

### 4. Configure MCP (if not auto-detected)

Add to `.kiro/settings/mcp.json`:

```json
{
  "mcpServers": {
    "circleci": {
      "command": "npx",
      "args": ["-y", "@circleci/mcp-server-circleci"],
      "env": {
        "CIRCLECI_TOKEN": "${CIRCLECI_TOKEN}",
        "CIRCLECI_BASE_URL": "https://circleci.com"
      }
    }
  }
}
```

## Features

| Feature | How |
|---------|-----|
| Validate configs | `config_helper` tool validates YAML |
| Debug failures | `get_build_failure_logs` retrieves logs |
| Run pipelines | `run_pipeline` triggers builds |
| Check status | `get_latest_pipeline_status` monitors |
| Find flaky tests | `find_flaky_tests` analyzes history |
| Rerun workflows | `rerun_workflow` retries from failure |

## Included Steering Files

- **circleci-best-practices.md** — Auto-included when editing `.circleci/` files
- **python-pipeline-patterns.md** — Python/PySpark CI patterns
- **oidc-aws-patterns.md** — OIDC + AWS deployment patterns

## Included Templates

- `templates/python-data-eng.yml` — Full Python data engineering pipeline
- `templates/cdk-deploy.yml` — CDK infrastructure deployment
- `templates/glue-workflow.yml` — Glue script upload workflow

## Hooks

- **validate-config-on-edit** — Auto-validates `.circleci/config.yml` on save
- **check-pipeline-on-push** — Checks pipeline status after agent pushes code

## License

MIT
