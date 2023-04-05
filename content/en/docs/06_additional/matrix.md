---
title: "6.9 Matrix"
weight: 69
sectionnumber: 6.9
---

{{% alert title="Note" color="info" %}}This is a non functional demo lab. The matrix feature is an alpha state feature which is currently not activated in our cluster.{{% /alert %}}


## {{% param sectionnumber %}}.1: Matrix

Matrix is used to fan out Tasks in a Pipeline. The Matrix will take Parameters of type "array" only, which will be supplied to the PipelineTask by substituting Parameters of type "string" in the underlying Task. The names of the Parameters in the Matrix must match the names of the Parameters in the underlying Task that they will be substituting.

In the example below, the test Task takes browser and platform Parameters of type "string". A Pipeline used to fan out the Task using Matrix would have two Parameters of type "array", and it would execute nine TaskRuns:

```yaml
apiVersion: tekton.dev/v1beta1
kind: Pipeline
metadata:
  name: platform-browser-tests
spec:
  params:
    - name: platforms
      type: array
      default:
        - linux
        - mac
        - windows
    - name: browsers
      type: array
      default:
        - chrome
        - safari
        - firefox    
  tasks:
  - name: fetch-repository
    taskRef:
      name: git-clone
    ...
  - name: test
    matrix:
      params:
        - name: platform
          value: $(params.platforms)
        - name: browser
          value: $(params.browsers)
    taskRef:
      name: browser-test
  ...
```
A Parameter can be passed to either the matrix or params field, not both.


## Task {{% param sectionnumber %}}.2: Use matrix for go build task

In this section we are going to show you how to implement a matrix build Task to build a go app for different architectures and operating systems.
Start with a new directory lab069 in your workspace directory.

```bash
mkdir lab069
```

First we need to create the go build task. The Task has following properties:

* A parameter `GOOS` to set the go target operating system, passed as env var to the build step (default: `amd64`)
* A parameter `GOARCH` to set the go target architecture, passed as env var to the build step (default: `linux`)
* A workspace named `source`
* A script for building the go binary `go build main.go -o awesome-go`


{{< readfile file="src/matrix/task.yaml"  code="true" lang="yaml"  >}}

Use following command to create a new *TaskRun*

```bash
{{% param cliToolName %}} apply -f lab069/task.yaml --namespace $USER 
```


Next create the file for the pipeline run `lab069/pipeline.yaml`.
{{< readfile file="src/matrix/pipeline.yaml" code="true" lang="yaml"  >}}


```bash
{{% param cliToolName %}} apply -f lab069/pipeline.yaml --namespace $USER 
```


## Task {{% param sectionnumber %}}.5: Cleanp

```bash
{{% param cliToolName %}} delete -f lab069/task.yaml --namespace $USER 
{{% param cliToolName %}} delete -f lab069/pipeline.yaml --namespace $USER 
```
