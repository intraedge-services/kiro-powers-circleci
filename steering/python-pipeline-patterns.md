---
inclusion: fileMatch
fileMatchPattern: ".circleci/**, tests/**, src/**/*.py, pyproject.toml"
---

# Python Data Engineering Pipeline Patterns

CI/CD patterns for Python projects using PySpark, AWS Glue, and pytest.

## Standard Python Quality Gates

### Code Formatting (Black)
```yaml
- run:
    name: Check code formatting
    command: black --check src/ tests/
```

### Linting (Flake8)
```yaml
- run:
    name: Run linter
    command: flake8 src/ tests/
```

### Type Checking (Mypy)
```yaml
- run:
    name: Run type checker
    command: mypy src/
```

### All Three Together
Run formatting → linting → type checking in sequence. Fail fast on the first issue.

## Unit Testing Patterns

### Basic pytest with Coverage
```yaml
- run:
    name: Run unit tests
    command: |
      pytest tests/ -v \
        --cov=src \
        --cov-report=term-missing \
        --cov-report=xml:test-results/coverage.xml \
        --junitxml=test-results/junit.xml
- store_test_results:
    path: test-results
```

### PySpark Test Setup
PySpark tests require Java. Install Temurin JDK before running:
```yaml
- run:
    name: Install JDK 17
    command: |
      curl -fsSL "https://github.com/adoptium/temurin17-binaries/releases/download/jdk-17.0.13%2B11/OpenJDK17U-jdk_x64_linux_hotspot_17.0.13_11.tar.gz" \
        | sudo tar -xz -C /opt
      sudo mv /opt/jdk-17.0.13+11 /opt/java
      echo 'export JAVA_HOME=/opt/java' >> "$BASH_ENV"
      echo 'export PATH=/opt/java/bin:$PATH' >> "$BASH_ENV"
```

### Test Parallelism
```yaml
parallelism: 2
steps:
  - run:
      name: Run tests (split by timing)
      command: |
        TESTS=$(circleci tests glob "tests/**/*.py" | circleci tests split --split-by=timings)
        pytest $TESTS -v --junitxml=test-results/junit.xml
```

## Dependency Management

### pyproject.toml with Extras
Structure dependencies as extras for targeted installs:
- `[dev]` — pytest, black, flake8, mypy
- `[spark]` — pyspark, delta-spark
- `[aws]` — boto3, moto
- `[cdk]` — aws-cdk-lib, constructs

### Install Pattern
```yaml
commands:
  install-python-deps:
    parameters:
      extras:
        type: string
    steps:
      - restore_cache:
          keys:
            - pip-v1-{{ checksum "pyproject.toml" }}
      - run:
          command: pip install -e ".[<< parameters.extras >>]"
      - save_cache:
          key: pip-v1-{{ checksum "pyproject.toml" }}
          paths:
            - ~/.cache/pip
```

## Security Scanning

### Dependency Vulnerability Scan
```yaml
- run:
    name: Vulnerability scan
    command: |
      pip install pip-audit
      pip-audit --desc --progress-spinner=off
```

### Bandit Security Scan
```yaml
- run:
    name: Security scan
    command: |
      pip install bandit
      bandit -r src/ -f json -o test-results/bandit.json || true
      bandit -r src/ --severity-level high
```

## Coverage Enforcement

### Minimum Coverage Gate
```yaml
- run:
    name: Check coverage threshold
    command: |
      COVERAGE=$(python -c "import json; print(json.load(open('test-results/coverage.json'))['totals']['percent_covered_display'])")
      echo "Coverage: ${COVERAGE}%"
      python -c "
      import json, sys
      cov = json.load(open('test-results/coverage.json'))['totals']['percent_covered']
      if cov < 80:
          print(f'Coverage {cov}% is below 80% threshold')
          sys.exit(1)
      "
```

## Glue Job Patterns

### Upload Scripts to S3
```yaml
- run:
    name: Upload Glue scripts
    command: |
      aws s3 sync src/ "s3://${BUCKET}/scripts/src/" --delete --exclude "__pycache__/*"
      aws s3 sync config/ "s3://${BUCKET}/config/" --delete
```

### Glue Job Integration Tests
```yaml
- run:
    name: Run Glue integration tests
    command: |
      pytest tests/integration/ -v \
        --junitxml=test-results/integration-junit.xml \
        -m "glue"
    no_output_timeout: 15m
```

## Executor Recommendations

| Job Type | Image | Resource Class |
|----------|-------|---------------|
| Lint/Format/Type check | `cimg/python:3.11` | `medium` |
| Unit tests (no Spark) | `cimg/python:3.11` | `medium` |
| PySpark tests | `cimg/python:3.11` | `large` |
| CDK synth/deploy | `cimg/python:3.11-node` | `medium` |
| Vulnerability scan | `cimg/python:3.11` | `medium` |
