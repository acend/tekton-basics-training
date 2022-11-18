---
title: "6.8 Security Scan"
weight: 68
sectionnumber: 6.8
---

## {{% param sectionnumber %}}.1: Security Scan Task

In this short section we will show you how tom implement a security scan for your built image. For this we are going to use the Aquasecurity Trivy scanner. Trivy is a simple and comprehensive scanner for vulnerabilities in container images.


```yaml
apiVersion: tekton.dev/v1beta1
kind: Task
metadata:
  name: trivy-scanner
spec:
  description: >-
    Trivy image scanner
  workspaces:
    - name: manifest-dir
  params:
    - name: ARGS
      description: The Arguments to be passed to Trivy command.
      type: array
    - name: TRIVY_IMAGE
      default: docker.io/aquasec/trivy:latest
      description: Trivy scanner image to be used
    - name: IMAGE_PATH
      description: Image or Path to be scanned by trivy.
      type: string
  steps:
    - name: trivy-scan
      image: $(params.TRIVY_IMAGE)
      workingDir: $(workspaces.manifest-dir.path)
      script: |
        #!/usr/bin/env sh
          cmd="trivy $* $(params.IMAGE_PATH)"
          echo "Running trivy task with command below"
          echo "$cmd"
          eval "$cmd"
      args:
        - "$(params.ARGS)"
```

## {{% param sectionnumber %}}.2: Security Scan Pipeline

```yaml
apiVersion: tekton.dev/v1beta1
kind: Pipeline
metadata:
  name: trivy-scanner-pipeline
spec:
  params:
    - name: image
      description: image to scan
      default: java-quarkus
  tasks:
    - name: trivy-scanner
      params:
      - name: ARGS
        value: ["image"]
      - name: IMAGE_PATH
        value:  $(params.image)
      taskRef:
        name: trivy-scanner
        kind: Task
```

## Task {{% param sectionnumber %}}.2: Trigger pipeline with PipelineRun resource

Create a new file `security-scan-pr.yaml` and define the **PipelineRun** to have:

* A `metadata.name: trivy-scanner-run`
* `spec.params.image` parameter for the image wich is going to be scanned (in this case  `alpine`)
* `pipelineRef` referencing the already defined *Pipeline*

{{% details title="Solution" %}}

```yaml
apiVersion: tekton.dev/v1beta1
kind: PipelineRun
metadata:
  name: trivy-scanner-run
spec:
  pipelineRef:
    name: trivy-scanner-pipeline
  params:
  - name: image
    value: "alpine"
```

Check the PipelineRun log output with following command:

`tkn pipelinerun logs trivy-scanner-run`

You should see following output

{{< highlight console >}}
Running trivy task with command below
trivy image alpine
2022-11-18T10:53:33.387Z	INFO	Need to update DB
2022-11-18T10:53:33.387Z	INFO	DB Repository: ghcr.io/aquasecurity/trivy-db
2022-11-18T10:53:33.387Z	INFO	Downloading DB...
2022-11-18T10:53:35.932Z	INFO	Vulnerability scanning is enabled
2022-11-18T10:53:35.932Z	INFO	Secret scanning is enabled
2022-11-18T10:53:35.932Z	INFO	If your scanning is slow, please try '--security-checks vuln' to disable secret scanning
2022-11-18T10:53:35.932Z	INFO	Please see also https://aquasecurity.github.io/trivy/v0.34/docs/secret/scanning/#recommendation for faster secret detection
2022-11-18T10:53:37.577Z	INFO	Detected OS: alpine
2022-11-18T10:53:37.577Z	INFO	Detecting Alpine vulnerabilities...
2022-11-18T10:53:37.578Z	INFO	Number of language-specific files: 0

alpine (alpine 3.16.3)
======================
Total: 0 (UNKNOWN: 0, LOW: 0, MEDIUM: 0, HIGH: 0, CRITICAL: 0)
{{< / highlight >}}

{{% /details %}}