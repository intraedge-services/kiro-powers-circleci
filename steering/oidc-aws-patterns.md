---
inclusion: fileMatch
fileMatchPattern: ".circleci/**, infrastructure/**"
---

# OIDC + AWS Deployment Patterns

Patterns for CircleCI OIDC federation with AWS, CDK deployments, and multi-environment promotion.

## OIDC Authentication

### Why OIDC Over Static Keys
- No long-lived credentials stored in CircleCI
- Automatic credential rotation (short-lived tokens)
- Fine-grained trust policies per project/branch
- Audit trail via CloudTrail with session names

### OIDC Setup with aws-cli Orb
```yaml
orbs:
  aws-cli: circleci/aws-cli@4.1

commands:
  aws-oidc-auth:
    description: "Authenticate to AWS using CircleCI OIDC"
    steps:
      - aws-cli/setup:
          role_arn: "${CIRCLECI_ROLE_ARN}"
          role_session_name: "circleci-${CIRCLE_BUILD_NUM}"
          region: "${AWS_REGION:-us-east-1}"
```

### AWS Trust Policy for CircleCI OIDC
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::ACCOUNT_ID:oidc-provider/oidc.circleci.com/org/ORG_ID"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "oidc.circleci.com/org/ORG_ID:aud": "ORG_ID"
        },
        "StringLike": {
          "oidc.circleci.com/org/ORG_ID:sub": "org/ORG_ID/project/PROJECT_ID/user/*"
        }
      }
    }
  ]
}
```

### Context Configuration
- Create a CircleCI context per environment (e.g., `cos-pipeline-sandbox`, `cos-pipeline-dev`, `cos-pipeline-prod`)
- Store `CIRCLECI_ROLE_ARN` and `AWS_REGION` in each context
- Each context points to a different IAM role with environment-scoped permissions

## CDK Deployment Patterns

### CDK Synth Job
```yaml
jobs:
  cdk-synth:
    executor: python-cdk
    steps:
      - checkout
      - install-cdk-cli
      - install-python-deps:
          extras: "cdk,aws"
      - aws-oidc-auth
      - run:
          name: CDK synthesize
          working_directory: infrastructure/cdk
          command: cdk synth -c env=<< pipeline.parameters.cos-env >>
      - persist_to_workspace:
          root: infrastructure/cdk
          paths:
            - cdk.out
```

### CDK Deploy Job
```yaml
jobs:
  cdk-deploy:
    executor: python-cdk
    steps:
      - checkout
      - install-cdk-cli
      - install-python-deps:
          extras: "cdk,aws"
      - attach_workspace:
          at: infrastructure/cdk
      - aws-oidc-auth
      - run:
          name: CDK deploy
          working_directory: infrastructure/cdk
          command: cdk deploy -c env=<< pipeline.parameters.cos-env >> --require-approval never --app cdk.out
```

### CDK Diff (for PRs)
```yaml
- run:
    name: CDK diff
    working_directory: infrastructure/cdk
    command: |
      cdk diff -c env=<< pipeline.parameters.cos-env >> 2>&1 | tee cdk-diff.txt
      echo "CDK_DIFF<<EOF" >> $BASH_ENV
      cat cdk-diff.txt >> $BASH_ENV
      echo "EOF" >> $BASH_ENV
```

## Multi-Environment Promotion

### Environment Strategy
```
sandbox → dev → prod
   │        │      │
   │        │      └── Manual approval + restricted branch
   │        └── Manual approval
   └── Auto-deploy on merge
```

### Pipeline Parameters
```yaml
parameters:
  cos-env:
    type: string
    default: "sandbox"
  destroy:
    type: boolean
    default: false
```

### Workflow Selection Pattern
```yaml
workflows:
  # Sandbox: auto-deploy
  deploy-sandbox:
    when:
      and:
        - equal: ["sandbox", << pipeline.parameters.cos-env >>]
        - not: << pipeline.parameters.destroy >>
    jobs:
      - quality-gates
      - deploy:
          requires: [quality-gates]

  # Dev/Prod: manual approval
  deploy-promoted:
    when:
      and:
        - not:
            equal: ["sandbox", << pipeline.parameters.cos-env >>]
        - not: << pipeline.parameters.destroy >>
    jobs:
      - quality-gates
      - hold:
          type: approval
          requires: [quality-gates]
      - deploy:
          requires: [hold]

  # Teardown: always requires approval
  teardown:
    when: << pipeline.parameters.destroy >>
    jobs:
      - hold:
          type: approval
      - destroy:
          requires: [hold]
```

## IAM Role Scoping

### Per-Environment Roles
| Environment | Role | Permissions |
|-------------|------|-------------|
| sandbox | `cos-circleci-sandbox-role` | Full deploy + destroy |
| dev | `cos-circleci-dev-role` | Deploy only, no destroy |
| prod | `cos-circleci-prod-role` | Deploy only, restricted resources |

### Least Privilege Pattern
- CDK deploy role: CloudFormation, S3, Glue, Step Functions, IAM (scoped)
- Glue upload role: S3 PutObject only to specific bucket prefixes
- Read-only role: For synth/diff in PR checks

## Rollback Strategy

### CDK Rollback
```yaml
- run:
    name: CDK deploy with rollback
    command: |
      cdk deploy --require-approval never --app cdk.out \
        --rollback true \
        -c env=<< pipeline.parameters.cos-env >>
```

### Manual Rollback Workflow
Use the `run_rollback_pipeline` MCP tool or:
```yaml
workflows:
  rollback:
    when: << pipeline.parameters.rollback >>
    jobs:
      - hold-rollback:
          type: approval
      - cdk-deploy:
          context: cos-pipeline-<< pipeline.parameters.cos-env >>
          requires: [hold-rollback]
          # Uses previous known-good cdk.out from artifacts
```
