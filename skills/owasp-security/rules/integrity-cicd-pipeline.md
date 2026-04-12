## Harden CI/CD pipelines against injection and tampering

Compromised pipelines can inject malicious code into every build. Pin
action versions by SHA, restrict permissions, and isolate secrets. CWE-829.

**Incorrect (mutable action tags, broad permissions, interpolated inputs):**

```yaml
name: Build
on: pull_request
permissions: write-all
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@main
      - run: echo "Building ${{ github.event.pull_request.title }}"
      - run: npm publish
        env:
          NPM_TOKEN: ${{ secrets.NPM_TOKEN }}
```

**Correct (pinned SHAs, minimal permissions, no input interpolation):**

```yaml
name: Build
on: pull_request
permissions:
  contents: read
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683 # v4.2.2
      - run: npm ci
      - run: npm test
      # Publish only on release, in a separate workflow with restricted secrets
```

Separate build and publish workflows. Use environment protection rules
for production deployments.

**Azure/Cloud:**

Azure DevOps supports pipeline permissions, approval gates, and
service connection restrictions per environment. Enable audit logging
for pipeline changes.

**References:**
- https://owasp.org/Top10/2025/A08_2025-Software_and_Data_Integrity_Failures/
- CWE-829: https://cwe.mitre.org/data/definitions/829.html
