## Sign and verify build artifacts in CI/CD pipelines

If build artifacts are not signed, an attacker with registry access can replace
them with compromised versions. CWE-494 (Download of Code Without Integrity Check).

**Incorrect (push and deploy without verification):**

```yaml
steps:
  - run: docker build -t myregistry.azurecr.io/app:latest .
  - run: docker push myregistry.azurecr.io/app:latest
  - run: kubectl set image deployment/app app=myregistry.azurecr.io/app:latest
```

**Correct (sign images, verify before deployment):**

```yaml
steps:
  - run: docker build -t myregistry.azurecr.io/app:${{ github.sha }} .
  - run: docker push myregistry.azurecr.io/app:${{ github.sha }}
  - run: cosign sign myregistry.azurecr.io/app:${{ github.sha }}
  - run: |
      DIGEST=$(docker inspect --format='{{index .RepoDigests 0}}' myregistry.azurecr.io/app:${{ github.sha }})
      kubectl set image deployment/app app=${DIGEST}
```

**Azure/Cloud:**

Enable Docker Content Trust in Azure Container Registry. Use Azure Policy for
AKS to enforce only signed images. Enable immutable tags on ACR repositories.

**References:**
- https://owasp.org/Top10/2025/A08_2025-Software_and_Data_Integrity_Failures/
- CWE-494: https://cwe.mitre.org/data/definitions/494.html
