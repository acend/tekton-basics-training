---
title: "5. Complex pipelines"
weight: 5
sectionnumber: 5
---

In the previous chapter we have designed a pipeline composing two tasks to checkout and build a docker image from a go application repository. We want to go a bit further and show what Tekton really is capable of. This time we will switch the language and implement a CI/CD pipeline for a java project.


## Task {{% param sectionnumber %}}.1: Create the pipeline

Create a *Pipeline* resource `java-pipeline` with a single step to checkout the [awesome-apps](https://github.com/acend/awesome-apps) repository. We can again reuse the already predefined *Task* **git-clone**. Try to parameterize as much as possible already, create parameters for the repository's URL and the corresponding subfolder (this time we will build the application in the `java-quarkus` subfolder).

{{% details title="Solution Pipeline" %}}

```yaml
apiVersion: tekton.dev/v1beta1
kind: Pipeline
metadata:
  name: java-pipeline
spec:
  params:
    - name: repository
      description: Repository to checkout
      default: https://github.com/acend/awesome-apps
    - name: application
      description: Application subpath in repository
      default: java-quarkus
  tasks:
    - name: git-clone
      params:
      - name: url
        value: $(params.repository)
      taskRef:
        name: git-clone
        kind: ClusterTask
```

{{% /details %}}

After creating the pipeline, create a *PipelineRun* object similar to the one created in the previous chapter.

{{% details title="Solution PipelineRun" %}}

```yaml
apiVersion: tekton.dev/v1beta1
kind: PipelineRun
metadata:
  generateName: java-pr-
spec:
  params:
  - name: image
    value: ttl.sh/02a77e8d-d633-4686-a401-cc92129e2270:1h
  - name: application
    value: go
  - name: context
    value: /workspace/source/go/.
  - name: dockerfile
    value: ./Dockerfile
  pipelineRef:
    name: java-pipeline
  workspaces:
    - name: ws-1 # this workspace name must be declared in the Pipeline
      volumeClaimTemplate:
        spec:
          accessModes:
            - ReadWriteOnce # access mode may affect how you can use this volume in parallel tasks
          resources:
            requests:
              storage: 1Gi
```

{{% /details %}}



## Task {{% param sectionnumber %}}.3: Add the task

```bash
{{% onlyWhen openshift %}}oc{{% /onlyWhen %}}{{% onlyWhenNot openshift %}}kubectl{{% /onlyWhenNot %}} -n $USER get task git-clone
{{% onlyWhen openshift %}}oc{{% /onlyWhen %}}{{% onlyWhenNot openshift %}}kubectl{{% /onlyWhenNot %}} -n $USER get clustertask git-clone
```

{{% details title="Solution" %}}

```yaml
apiVersion: tekton.dev/v1beta1
kind: Pipeline
metadata:
  name: build-go
spec:
  params:
    - name: repository
      description: Repository to checkout
      default: https://github.com/acend/awesome-apps
    - name: application
      description: Application subpath in repository
      default: go
  tasks:
    - name: git-clone
      params:
      - name: url
        value: $(params.repository)
      taskRef:
        name: git-clone
        kind: ClusterTask
```

{{% /details %}}
