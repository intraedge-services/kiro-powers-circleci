# CircleCI CI/CD Pipeline Management Power

A Kiro power that integrates the official [CircleCI MCP Server](https://github.com/CircleCI-Public/mcp-server-circleci) for managing CI/CD pipelines directly from your IDE. Includes best-practice steering files for Python data engineering projects.

## What This Power Does

- **Validate & Fix Configs** — Validate `.circleci/config.yml` against CircleCI schema and get fix suggestions
- **Debug Build Failures** — Retrieve failure logs and diagnose issues without leaving the IDE
- **Run Pipelines** — Trigger pipelines, rerun workflows, or rollback deployments
- **Monitor Status** — Check latest pipeline status for any branch
- **Find Flaky Tests** — Identify unreliable tests from execution history
- **Optimize Resources** — Find jobs with underused compute resource classes
- **Best Practices** — Steering files with CircleCI patterns for Python, OIDC, CDK, and Glue

## Prerequisites

1. **CircleCI API Token** — Generate a personal API token at https://app.circleci.com/settings/user/tokens
2. **Node.js** — Required to run the MCP server via `npx`
3. **Environment Variable** — Set `CIRCLECI_TOKEN` in your environment or `.env` file

## Setup

### 1. Set your CircleCI token

Add to your shell profile or `.env`:
```bash
export CIRCLECI_TOKEN="your-circleci-personal-api-token"
```

### 2. Install the power

Copy this directory to your Kiro powers location, or reference it in your workspace MCP config.

### 3. MCP Configuration

The power registers the official CircleCI MCP server. If you need to configure it manually, add to `.kiro/settings/mcp.json`:

```json
{
  "mcpServers": {
    "circleci": {
      "command": "npx",
      "args": ["-y", "@circleci/mcp-server-circleci"],
      "env": {
        "CIRCLECI_TOKEN": "${CIRCLECI_TOKEN}",
        "CIRCLECI_BASE_URL": "https://circleci.com"
      },
      "disabled": false,
      "autoApprove": ["list_followed_projects", "get_latest_pipeline_status", "config_helper"]
    }
  }
}
```

## Available Tools (from Official MCP Server)

| Tool | Description |
|------|-------------|
| `config_helper` | Validate and fix CircleCI configuration YAML |
| `get_build_failure_logs` | Retrieve detailed failure logs from builds |
| `get_job_test_results` | Get test metadata and results for jobs |
| `get_latest_pipeline_status` | Check pipeline status for a branch |
| `find_flaky_tests` | Identify flaky tests from execution history |
| `find_underused_resource_classes` | Find jobs with underused compute |
| `list_followed_projects` | List all projects you follow |
| `run_pipeline` | Trigger a pipeline to run |
| `rerun_workflow` | Rerun a workflow from start or from failed job |
| `run_rollback_pipeline` | Trigger a rollback for a project |
| `list_artifacts` | List artifacts produced by a job |
| `analyze_diff` | Analyze git diffs against rules for violations |

## What's Included

```
kiro-powers-circleci/
├── POWER.md                          # This file
├── package.json                      # Power metadata + MCP server config
├── steering/
│   ├── circleci-best-practices.md    # General CircleCI best practices
│   ├── python-pipeline-patterns.md   # Python/PySpark CI patterns
│   └── oidc-aws-patterns.md          # OIDC + AWS deployment patterns
├── hooks/
│   ├── validate-config-on-edit.json  # Auto-validate config on save
│   └── check-pipeline-on-push.json  # Check pipeline status after push
└── templates/
    ├── python-data-eng.yml           # Template: Python data engineering pipeline
    ├── cdk-deploy.yml                # Template: CDK synth + deploy pipeline
    └── glue-workflow.yml             # Template: Glue job upload workflow
```

## Usage Examples

### Validate your config
> "Validate my CircleCI config and fix any issues"

### Debug a failure
> "Get the build failure logs for my latest pipeline on the main branch"

### Check status
> "What's the status of my latest pipeline?"

### Run a pipeline
> "Trigger a pipeline run on my feature branch"

### Find flaky tests
> "Find flaky tests in my project"

## Integration with AIDLC

When used alongside `kiro-powers-aidlc`, this power is activated during:
- **Build and Test stage** — Validates generated CircleCI configs
- **Code Generation** — Provides pipeline templates for new services
- **Post-deployment** — Monitors pipeline status after code changes

## Steering Files

The steering files provide context-aware guidance:

- **circleci-best-practices.md** — Caching, parallelism, orbs, resource classes, security
- **python-pipeline-patterns.md** — pytest, coverage, linting, PySpark testing patterns
- **oidc-aws-patterns.md** — OIDC federation, CDK deploy, multi-environment promotion

These are automatically included when working on `.circleci/` files or CI/CD tasks.
