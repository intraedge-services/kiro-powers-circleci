# kiro-powers-circleci

A Kiro power for CircleCI CI/CD pipeline management, built on the [official CircleCI MCP Server](https://github.com/CircleCI-Public/mcp-server-circleci).

## Prerequisites

Before installing, ensure you have:

| Requirement | Version | Check Command |
|-------------|---------|---------------|
| Node.js | >= 18.x | `node --version` |
| npm / npx | >= 9.x | `npx --version` |
| Kiro IDE | Latest | — |
| CircleCI Account | — | https://app.circleci.com |

## Installation & Setup

### Step 1: Generate a CircleCI API Token

1. Go to https://app.circleci.com/settings/user/tokens
2. Click **Create New Token**
3. Give it a name (e.g., `kiro-mcp`)
4. Copy the token (you won't see it again)

### Step 2: Set the Environment Variable

Add to your shell profile (`~/.zshrc` or `~/.bashrc`):

```bash
export CIRCLECI_TOKEN="your-circleci-personal-api-token"
```

Then reload:
```bash
source ~/.zshrc
```

### Step 3: Install the Power

**Option A — Automated (recommended):**

```bash
# Clone the power repo
git clone https://github.com/intraedge-services/kiro-powers-circleci.git

# Run the install script pointing to your target workspace
./kiro-powers-circleci/install.sh /path/to/your-project
```

This will:
- Copy power files to `.kiro/powers/kiro-powers-circleci/`
- Create `.kiro/settings/mcp.json` with the CircleCI server config
- Verify your `CIRCLECI_TOKEN` is set

**Option B — Manual:**

1. Copy the power into your workspace:
```bash
cp -r kiro-powers-circleci/ /path/to/your-project/.kiro/powers/kiro-powers-circleci/
```

2. Create `.kiro/settings/mcp.json` in your workspace:
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
      "autoApprove": [
        "list_followed_projects",
        "get_latest_pipeline_status",
        "config_helper",
        "get_job_test_results"
      ]
    }
  }
}
```

> **Note**: If `.kiro/settings/mcp.json` already exists, merge the `circleci` entry into the existing `mcpServers` object.

> **Note**: `autoApprove` lists read-only tools that won't prompt for confirmation. Remove tools from this list if you prefer manual approval for all actions.

### Step 4: Verify the MCP Server is Running

1. Open Kiro IDE (or reload window)
2. Open the Command Palette and search for **MCP**
3. Check that the `circleci` server shows as **Connected**
4. Alternatively, ask Kiro: *"List my followed CircleCI projects"*

## Quick Test Commands

Once installed, try these in Kiro chat to verify everything works:

| Test | What to Ask Kiro |
|------|-----------------|
| List projects | *"List my followed CircleCI projects"* |
| Validate config | *"Validate my .circleci/config.yml"* |
| Check pipeline | *"What's the status of my latest pipeline on main?"* |
| Get failure logs | *"Get the build failure logs for my last failed pipeline"* |
| Find flaky tests | *"Find flaky tests in my project"* |

## Available MCP Tools

| Tool | Description | Risk Level |
|------|-------------|------------|
| `list_followed_projects` | List all projects you follow | Read-only |
| `config_helper` | Validate and fix CircleCI config YAML | Read-only |
| `get_latest_pipeline_status` | Check pipeline status for a branch | Read-only |
| `get_build_failure_logs` | Retrieve detailed failure logs | Read-only |
| `get_job_test_results` | Get test metadata and results | Read-only |
| `find_flaky_tests` | Identify flaky tests from history | Read-only |
| `find_underused_resource_classes` | Find jobs with underused compute | Read-only |
| `list_artifacts` | List artifacts produced by a job | Read-only |
| `analyze_diff` | Analyze git diffs against rules | Read-only |
| `run_pipeline` | Trigger a pipeline to run | **Write** |
| `rerun_workflow` | Rerun a workflow from start or failed | **Write** |
| `run_rollback_pipeline` | Trigger a rollback | **Write** |

## Included Steering Files

| File | Auto-triggers On | Purpose |
|------|-----------------|---------|
| `circleci-best-practices.md` | `.circleci/**` | Caching, parallelism, orbs, security |
| `python-pipeline-patterns.md` | `.circleci/**, tests/**, src/**/*.py` | pytest, PySpark, coverage, linting |
| `oidc-aws-patterns.md` | `.circleci/**, infrastructure/**` | OIDC federation, CDK deploy, multi-env |

## Included Templates

| Template | Use Case |
|----------|----------|
| `templates/python-data-eng.yml` | Full pipeline: lint, test, vuln scan, CDK deploy, Glue upload, teardown |
| `templates/cdk-deploy.yml` | CDK-only: synth, diff, deploy with approval gates |
| `templates/glue-workflow.yml` | Lightweight Glue script + libs upload to S3 |

## Hooks

| Hook | Trigger | Action |
|------|---------|--------|
| `validate-config-on-edit` | `.circleci/config.yml` saved | Validates config via MCP `config_helper` |
| `check-pipeline-on-push` | Agent session ends | Checks pipeline status if code was pushed |

## Troubleshooting

### MCP server not connecting

1. Verify Node.js is installed: `node --version` (need 18+)
2. Verify token is set: `echo $CIRCLECI_TOKEN` (should not be empty)
3. Test manually: `npx -y @circleci/mcp-server-circleci` (should start without errors)
4. Check Kiro MCP panel for error messages

### "Unauthorized" errors

- Your token may have expired — regenerate at https://app.circleci.com/settings/user/tokens
- Ensure the token has access to the projects you're querying

### "No projects found"

- You need to be following projects on CircleCI
- Go to https://app.circleci.com and follow the projects you want to manage

### Tools timing out

- The MCP server needs network access to `circleci.com`
- Check if you're behind a proxy/VPN that blocks outbound HTTPS

## Project Structure

```
kiro-powers-circleci/
├── .gitignore
├── package.json              # Power metadata + MCP server declaration
├── POWER.md                  # Detailed power documentation
├── README.md                 # This file
├── install.sh                # Automated install script
├── config/
│   └── mcp.json              # MCP config to copy into target workspace
├── hooks/
│   ├── validate-config-on-edit.json
│   └── check-pipeline-on-push.json
├── steering/
│   ├── circleci-best-practices.md
│   ├── python-pipeline-patterns.md
│   └── oidc-aws-patterns.md
└── templates/
    ├── python-data-eng.yml
    ├── cdk-deploy.yml
    └── glue-workflow.yml
```

## License

MIT
