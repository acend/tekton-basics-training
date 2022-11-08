---
title: "4. Building Docker images"
weight: 4
sectionnumber: 4
---

In the last chapter we made a short dive into building first tasks and wrap them in pipelines. One of the most common tasks in modern continuous integration and delivery pipelines is building applications and containers. We will take a look at how we can implement a basic application and docker build in a Tekton pipeline.

Starting from scratch, we need an application code first. We will checkout the [repository](https://github.com/acend/awesome-apps) and build the go application located in the `go/` subfolder.


## Task {{% param sectionnumber %}}.1: Create your pipeline

Create a new file `build-go-pipeline.yaml` containing a **Pipeline**. The pipeline should contain at first one step, which will checkout the repository from [Github](https://github.com/acend/awesome-apps). At the moment, keep the tasks section empty and read on.


## {{% param sectionnumber %}}.2: Tasks and ClusterTasks


For tasks which are often reused on a cluster's scale, Tekton introduces another construct called **ClusterTask**. A **ClusterTask** is built the same way as a normal **Task** but will be available cluster-wide.

Another new feature we are going to take a look at is the [**Tekton Hub**](https://hub.tekton.dev/). The hub contains a collection of widely used definitions which can be installed and reused, similar to a Helm or Docker repository.

Read the definition of the *git-clone* task already defined in the [hub](https://hub.tekton.dev/tekton/task/git-clone).


## Task {{% param sectionnumber %}}.3: Add the task

Your task as the new CI officer is to implement the first step of your pipeline with the pre-defined task **git-clone**.

{{% details title="Hint 1" %}}

Check if the task is already defined and available in either the cluster or your namespace:

{{% onlyWhen openshift %}}

```bash
oc -n $USER get task git-clone
oc -n $USER get clustertask git-clone
```

{{% /onlyWhen %}}
{{% onlyWhenNot openshift %}}

```bash
kubectl -n $USER get task git-clone
kubectl -n $USER get clustertask git-clone
```

{{% /onlyWhenNot %}}

{{% /details %}}

Add the task reference to your pipeline and parameterize the pipeline to checkout your repository!

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


## {{% param sectionnumber %}}.4: Workspaces

So far we have worked with pipelines and tasks without stages. In reality CI pipelines are - obviously - state driven. To add state and volumes to your piplines and tasks we will take a short look at the concept of workspaces in Tekton. **Workspaces** can be Storage, ConfigMaps, Secrets and can be restricted to be read-only.

At it's base the **Workspace** is just another Kubernetes resource being shared and mounted to your **Pods** running the pipeline / tasks. In the definition of the **Pipeline** we can state all the **Workspace** resources used and in the definition of each **Task** we will define to which **Workspace** the pods have access to. Take a look at the following example:

```yaml
spec:
  workspaces:
    - name: pipeline-ws1 # Name of the workspace in the Pipeline
  tasks:
    - name: use-ws-from-pipeline
      taskRef:
        name: gen-code # gen-code expects a workspace named "output"
      workspaces:
        - name: output
          workspace: pipeline-ws1
    - name: use-ws-again
      taskRef:
        name: commit # commit expects a workspace named "src"
      workspaces:
        - name: src
          workspace: pipeline-ws1
      runAfter:
        - use-ws-from-pipeline # important: use-ws-from-pipeline writes to the workspace first
```


## Task {{% param sectionnumber %}}.5: Add workspaces

In the previous section we learned how **Workspaces** can be added to Pipelines and Tasks. Add a workspace to your pipeline created in the chapter before. This way, the *git-clone* Task can clone the repository into your workspace.

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
  workspaces:
  - name: ws-1
  tasks:
    - name: git-clone
      workspaces:
      - name: output
        workspace: ws-1
      params:
      - name: url
        value: $(params.repository)
      taskRef:
        name: git-clone
        kind: ClusterTask
```

{{% /details %}}


## Task {{% param sectionnumber %}}.6: Create the docker image

We have now a pipeline with a task that clones a git repository to our workspace. It is your job now to alter the pipeline to build a docker container with the predefined **Task**/**ClusterTask** called *buildah*. You can read the documentation again on the [Tekton Hub](https://hub.tekton.dev/tekton/task/buildah). Verify if the task is already defined on the cluster, then update your pipeline definition and build your container!

{{% details title="Hint" %}}

```bash

{{% onlyWhen openshift %}}oc{{% /onlyWhen %}}{{% onlyWhenNot openshift %}}kubectl{{% /onlyWhenNot %}} get task buildah
{{% onlyWhen openshift %}}oc{{% /onlyWhen %}}{{% onlyWhenNot openshift %}}kubectl{{% /onlyWhenNot %}} get clustertask buildah

```

{{% /details %}}

Use the predefined *buildah* Task / ClusterTask to enhance your pipeline to build and push a docker image. Add the task to your already defined pipeline *build-go*.

{{% details title="Solution Pipeline" %}}

```yaml
apiVersion: tekton.dev/v1beta1
kind: Pipeline
metadata:
  name: build-go
spec:
  params:
  - default: https://github.com/acend/awesome-apps
    description: Repository to checkout
    name: repository
    type: string
  - default: go
    description: Application subpath in repository
    name: application
    type: string
  - default: ttl.sh/<uuid>:1h # TODO: Replace me
    description: The image including the registry and tag
    name: image
    type: string
  - default: "."
    name: context
    description: Docker context to build
    type: string
  - default: Dockerfile
    name: dockerfile
    description: Location of the dockerfile
    type: string
  tasks:
  - name: git-clone
    params:
    - name: url
      value: $(params.repository)
    taskRef:
      kind: ClusterTask
      name: git-clone
    workspaces:
    - name: output
      workspace: ws-1
  - name: buildah
    params:
    - name: CONTEXT
      value: $(params.context)
    - name: DOCKERFILE
      value: $(params.dockerfile)
    - name: IMAGE
      value: $(params.image)
    taskRef:
      kind: ClusterTask
      name: buildah
    workspaces:
    - name: source
      workspace: ws-1
  workspaces:
  - name: ws-1

```

{{% /details %}}

We can trigger the pipeline by creating a **PipelineRun** resource, referencing our created pipeline *build-go*.


## Task {{% param sectionnumber %}}.7: Trigger Pipelines with PipelineRuns

So far we have triggered the pipelines with the `tkn` cli. This time we are going to create a **PipelineRun** resource to define how this pipeline will be instantiated.

Create a new file `build-docker-pr.yaml` and define the **PipelineRun** to have:

* A `metadata.generateName: build-go-pr-` which defines how generated *PipelineRuns* will be called (similar to the *StatefulSet*)
* `spec.params` a map of all the parameters, overriding the defaults in the *Pipeline*
* `pipelineRef` referencing the already defined *Pipeline*
* `workspaces` defining all the workspaces needed in this *Pipeline* (in this case one `ws-1`)

{{% details title="Hint name" %}}

Start your file like the following:

```yaml
apiVersion: tekton.dev/v1beta1
kind: PipelineRun
metadata:
  generateName: build-go-pr-
```

{{% /details %}}

{{% details title="Hint params" %}}

Specify the parameters like the following:

```yaml
spec:
  params:
  - name: param1
    value: value1
  - name: param2
    value: value2
```

{{% /details %}}

{{% details title="Hint `pipelineRef`" %}}

Reference the pipeline:

```yaml
spec:
  pipelineRef:
    name: build-go
```

{{% /details %}}

If you want to verify your approach, or simply need some additional hints, check the example solution:

{{% details title="Solution Pipeline" %}}

```yaml
apiVersion: tekton.dev/v1beta1
kind: PipelineRun
metadata:
  generateName: build-go-pr-
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
    name: build-go
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

When you have created your **PipelineRun** resource and created it in your namespace, you will instantly see that a pipeline will be running. Check the logs and verify if your image was built correctly!


## Task {{% param sectionnumber %}}.8: Cleanup

Delete all the resources created during this capter in your namespace.

```bash

{{% onlyWhen openshift %}}oc{{% /onlyWhen %}}{{% onlyWhenNot openshift %}}kubectl{{% /onlyWhenNot %}} delete pipeline build-go

```
