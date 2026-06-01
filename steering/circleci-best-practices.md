---
inclusion: fileMatch
fileMatchPattern: ".circleci/**"
---

# CircleCI Best Practices

Guidelines for generating and maintaining CircleCI configuration files.

## Configuration Structure

### Version & Orbs
- Always use `version: 2.1` for access to orbs, commands, executors, and parameters
- Use official CircleCI orbs where available (e.g., `circleci/node`, `circleci/aws-cli`, `circleci/python`)
- Pin orb versions to major.minor (e.g., `circleci/aws-cli@4.1`) for stability

### Executors
- Define reusable executors for consistent environments
- Use the smallest `resource_class` that meets job requirements:
  - `small` — Linting, simple scripts
  - `medium` — Standard builds, CDK synth
  - `large` — Spark/PySpark tests, heavy compilation
- Prefer `cimg/*` convenience images over raw Docker images

### Commands
- Extract repeated step sequences into reusable `commands:`
- Parameterize commands for flexibility (extras, cache keys, etc.)
- Include descriptions for all commands and parameters

## Caching Strategy

### Pip Dependencies
```yaml
- restore_cache:
    keys:
      - pip-v1-{{ .Environment.CACHE_KEY }}-{{ checksum "pyproject.toml" }}
      - pip-v1-{{ .Environment.CACHE_KEY }}-
- save_cache:
    key: pip-v1-{{ .Environment.CACHE_KEY }}-{{ checksum "pyproject.toml" }}
    paths:
      - ~/.cache/pip
      - ~/.local/lib
```

### NPM/CDK
```yaml
- restore_cache:
    keys:
      - npm-cdk-v1-{{ checksum "package-lock.json" }}
      - npm-cdk-v1-
```

### Cache Key Rules
- Always include a checksum of the lockfile/manifest
- Use versioned prefixes (`pip-v1-`) to allow cache busting
- Separate caches by job purpose (dev, spark, cdk)

## Parallelism & Test Splitting

- Use `parallelism: N` for test jobs with many test files
- Split by timing for optimal distribution:
```yaml
TESTS=$(circleci tests glob "tests/**/*.py" | circleci tests split --split-by=timings)
pytest $TESTS
```
- Store test results with `store_test_results` for timing data

## Workflow Patterns

### Multi-Environment Promotion
```yaml
workflows:
  deploy-sandbox:
    when:
      equal: ["sandbox", << pipeline.parameters.env >>]
    jobs:
      - quality-gates
      - deploy:
          requires: [quality-gates]

  deploy-promoted:
    when:
      not:
        equal: ["sandbox", << pipeline.parameters.env >>]
    jobs:
      - quality-gates
      - approval:
          type: approval
          requires: [quality-gates]
      - deploy:
          requires: [approval]
```

### Quality Gates (run before any deploy)
1. Code quality (lint, format, type check)
2. Unit tests with coverage
3. Vulnerability scanning
4. Infrastructure validation (CDK synth)

### Job Dependencies
- Use `requires:` to create explicit dependency chains
- Gate deployments behind all quality checks
- Use `type: approval` for manual gates in non-sandbox environments

## Security Best Practices

### Secrets Management
- Never hardcode secrets in config — use CircleCI contexts
- Use OIDC federation instead of static AWS credentials
- Scope contexts to specific workflows/branches

### OIDC Authentication
- Prefer OIDC over stored access keys for AWS
- Use the `aws-cli` orb's built-in OIDC support
- Set `role_session_name` to include build number for traceability

### Vulnerability Scanning
- Run `pip-audit` or `safety` on every build
- Fail the build on critical vulnerabilities
- Scan before deployment, not after

## Artifacts & Test Results

- Always `store_test_results` for JUnit XML — enables test insights
- Use `store_artifacts` for coverage reports, build outputs
- Use `persist_to_workspace` / `attach_workspace` to pass data between jobs

## Pipeline Parameters

- Use `parameters:` for environment selection, feature flags
- Default to safe values (e.g., `default: "sandbox"`)
- Use `when:` conditions to select workflows based on parameters

## Resource Optimization

- Match resource_class to actual job needs
- Use Docker layer caching for custom images
- Avoid redundant checkouts — use workspaces to share code
- Set appropriate timeouts with `no_output_timeout`
