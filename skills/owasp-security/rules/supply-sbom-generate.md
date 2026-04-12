## Generate and maintain a Software Bill of Materials

An SBOM is a complete inventory of all components, libraries, and dependencies.
When a new CVE is disclosed, an SBOM lets you instantly determine if you are
affected.

**Incorrect (no inventory of dependencies):**

```text
# No SBOM — when a CVE drops, manually grep through hundreds of repos
```

**Correct (automated SBOM generation in CI):**

```yaml
steps:
  - run: npm ci
  - run: npx @cyclonedx/cyclonedx-npm --output-file sbom.json
  - run: npm run build
  - uses: actions/upload-artifact@v4
    with:
      name: sbom
      path: sbom.json
```

**Azure/Cloud:**

Azure Container Registry can store SBOMs alongside container images. Microsoft
Defender for Cloud integrates with SBOMs for vulnerability correlation.

**References:**
- https://owasp.org/Top10/2025/A03_2025-Software_Supply_Chain_Failures/
