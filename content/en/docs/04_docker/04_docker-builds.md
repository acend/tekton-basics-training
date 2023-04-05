---
title: "4. Building Docker images"
weight: 4
sectionnumber: 4
---

In the last chapter we made a short dive into building first tasks and wrap them in pipelines. One of the most common tasks in modern continuous integration and delivery pipelines is building applications and containers. We will take a look at how we can implement a basic application and docker build in a Tekton pipeline.

The pipeline will consist of two basic tasks:

1. clone a git repository with the source code
1. build the container image

Starting from scratch, we need an application code first. We will checkout the [repository](https://github.com/acend/awesome-apps) and build the go application located in the `go/` subfolder.


## Task {{% param sectionnumber %}}.1: Create your pipeline

First create a new directory `lab04`.

```bash
mkdir lab04
```

Now create a new file `lab04/build-go-pipeline.yaml` containing a **Pipeline**. The pipeline should contain at first one step, which will checkout the repository from [Github](https://github.com/acend/awesome-apps). At the moment, keep the tasks section empty and read on.

Add the following content:

```yaml
apiVersion: tekton.dev/v1beta1
kind: Pipeline
metadata:
  name: build-go
spec:
  params:
  tasks:
```


## {{% param sectionnumber %}}.2: Tasks and ClusterTasks


For tasks which are often reused on a cluster wide scale, Tekton introduces another construct called **ClusterTask**. A **ClusterTask** is built the same way as a normal **Task** but will be available cluster-wide.

Another new feature we are going to take a look at is the [**Tekton Hub**](https://hub.tekton.dev/). The hub contains a collection of widely used definitions which can be installed and reused, similar to a Helm or Docker repository.

Read the definition of the *git-clone* task already defined in the [hub](https://hub.tekton.dev/tekton/task/git-clone).


## Task {{% param sectionnumber %}}.3: Add the task

Your task as the new CI officer is to implement the first step of your pipeline with the pre-defined task **git-clone**.

Let's check if the task is already defined and available in either the cluster or your namespace:

```bash
{{% param cliToolName %}} get clustertask git-clone 
```

The git-clone task is available as clustertask.

To stay as generic as possible, we define the repository to checkout as pipeline parameter `repository`. This parameter we'll be using to configure our referenced `git-clone` ClusterTask.

Add the params and task to your pipeline:

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
  tasks:
    - name: git-clone
      params:
      - name: url
        value: $(params.repository)
      taskRef:
        name: git-clone
        kind: ClusterTask
```

Create the pipeline

```bash
{{% param cliToolName %}} apply -f lab04/build-go-pipeline.yaml --namespace $USER 
```

and run it

```bash
tkn pipeline start build-go --namespace $USER 
```

The pipeline will fail, with the following error:

```bash
task git-clone has failed: declared workspace "output" is required but has not been bound
```

Our predefined task seems to have some dependencies. Let's move on.


## {{% param sectionnumber %}}.4: Workspaces

So far, we have worked with pipelines and tasks without stages. In reality, CI pipelines are - obviously - state driven. To add state and volumes to your piplines and tasks we will take a short look at the concept of workspaces in Tekton. **Workspaces** can be Storage, ConfigMaps, Secrets and can be restricted to be read-only.

At its base the **Workspace** is just another Kubernetes resource being shared and mounted to your **Pods** running the pipeline / tasks. In the definition of the **Pipeline** we can state all the **Workspace** resources used and in the definition of each **Task** we will define to which **Workspace** the pods have access to. Take a look at the following example:

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

In the previous section we learned how **Workspaces** can be added to Pipelines and Tasks. We now add a workspace to your pipeline created in the chapter before. This way, the *git-clone* Task can clone the repository into the required workspace (referenced by `output`) and therefore be shared between tasks.


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

Again apply your changes

```bash
{{% param cliToolName %}} apply -f lab04/build-go-pipeline.yaml --namespace $USER 
```

and run it, with the following configuration

```bash
tkn pipeline start build-go \
    --workspace name=ws-1,emptyDir= \
    --use-param-defaults \
    --namespace $USER
```

{{% alert title="Note" color="info" %}}We configure the workspace as an emptyDir for test purposes and to show how to configure pipelineruns via CLI. You will learn about pipelineruns soon.{{% /alert %}}


## Task {{% param sectionnumber %}}.6: Create the docker image

We have now a pipeline with a task that clones a git repository to our workspace. It is your job now to alter the pipeline to build a docker container with the predefined **Task**/**ClusterTask** called *buildah*. You can read the documentation again on the [Tekton Hub](https://hub.tekton.dev/tekton/task/buildah).

The buildah task is available as Cluster Task:

```bash
{{% param cliToolName %}} get clustertask buildah
```

Use the predefined *buildah* ClusterTask to enhance your pipeline to build and push a docker image. Add the task to your already defined pipeline *build-go*.

Make sure to replace `<uuid>` with a corresponding uuid, when editing the file `<lab04/build-go-pipeline.yaml>`.

{{% alert title="Note" color="info" %}}
You can create a uuid by running (on your Linux system)
```bash
cat /proc/sys/kernel/random/uuid
```
{{% /alert %}}

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
    - name: image
      description: The image including the registry and tag
      default: ttl.sh/<uuid>:1h # TODO: Replace me
      type: string
    - name: context
      description: Docker context to build
      default: "./go/"
      type: string
    - name: dockerfile
      description: Location of the dockerfile
      default: ./Dockerfile
      type: string
  workspaces:
  - name: ws-1
  tasks:
  - name: git-clone
    params:
    - name: url
      value: $(params.repository)
    - name: subdirectory
      value: ""
    - name: deleteExisting
      value: "true"
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
    runAfter:
    - git-clone
    workspaces:
    - name: source
      workspace: ws-1
```

Again apply your changes

```bash
{{% param cliToolName %}} apply -f lab04/build-go-pipeline.yaml --namespace $USER 
```

We can trigger the pipeline by creating a **PipelineRun** resource, referencing our created pipeline *build-go*.


## Task {{% param sectionnumber %}}.7: Trigger Pipelines with PipelineRuns

So far we have triggered the pipelines with the `tkn` cli. This time we are going to create a **PipelineRun** resource to define how this pipeline will be instantiated.

We need to define the **PipelineRun** to have:

* A `metadata.generateName: build-go-pr-` which defines how generated *PipelineRuns* will be called (similar to the *StatefulSet*)
* `spec.params` a map of all the parameters, overriding the defaults in the *Pipeline*
* `pipelineRef` referencing the already defined *Pipeline*
* `workspaces` defining all the workspaces needed in this *Pipeline* (in this case one `ws-1`)
  * To also specify a PVC which will give us persistence

Create a new file `lab04/build-docker-pipelinerun.yaml` with the following content:

Again, make sure to replace `<uuid>` with a corresponding uuid.

```yaml
apiVersion: tekton.dev/v1beta1
kind: PipelineRun
metadata:
  generateName: build-go-pr-
spec:
  params:
  - name: image
    value: ttl.sh/<uuid>:1h # TODO: Replace me
  - name: context
    value: ./go/
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

Let's create the `PipelineRun` which will instantly start our pipeline:

```bash
{{% param cliToolName %}} create -f lab04/build-docker-pipelinerun.yaml --namespace $USER 
```

Check the logs and verify if your image was built correctly!
```bash
tkn pipelinerun logs --namespace $USER 
```
and choose the last run.


## Task {{% param sectionnumber %}}.8: Cleanup

Delete all the resources created during this chapter in your namespace.

```bash
{{% param cliToolName %}} delete pipeline build-go --namespace $USER 
```
