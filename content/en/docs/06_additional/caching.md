---
title: "6.1 Caching"
weight: 61
sectionnumber: 6.1
---


## {{% param sectionnumber %}}.1: Workspaces

As we have already seen in the previous labs, Tekton offers the possibility to use *Workspaces* for transferring data between different Tasks.

At its base the Workspace is just another Kubernetes resource being shared and mounted to your Pods running the pipeline / tasks. In the definition of the Pipeline we can state all the Workspace resources used and in the definition of each Task we will define to which Workspace the pods have access to.

You can use *Workspaces* for different use cases:

* Pass arbritary data between Tasks
* Use Workspaces as cache between Tasks
* Promote build artifacts between Tasks

Here is an example how you can pass data between *Tasks* with *Claims*, *Secrets* and *ConfigMaps*

Let's start with the Kubernetes basic ressources.
First, we can define a PVC for our workspace. PVCs are the first choice if you need to persist data between Tasks.

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-pvc
spec:
  resources:
    requests:
      storage: 1Gi
  volumeMode: Filesystem
  accessModes:
    - ReadWriteOnce
```

The next workspace is created with a ConfigMap. This method is most suitable if you want to mount simple strings or configuration into your pipelines. But keep in mind that a workspace defined with a ConfigMap is read only!

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: my-configmap
data:
  message: hello world
```

Finally the last workspace definition is done by a Secret. This method is most suitable if you want to mount confident data into your pipelines. But keep in mind that a workspace defined with a *Secret* is read only!


```yaml
apiVersion: v1
kind: Secret
metadata:
  name: my-secret
type: Opaque
stringData:
  username: user
data:
  message: aGVsbG8gc2VjcmV0
```

Now we are going to use the defined workspace within a *TaskRun*.
In the example below you can see different methods how to use and mount a *Workspace* :

* The *PersistentVolumeClaim* `my-pvc` is referenced two times in the *TaskRun* (With and without a SubPath)
* There is an inline definition for a *PersistenVolumeClaim* `custom3`. It is of the type emptyDir, which is nothing more than an ephermal Workspace.
* The *Secret* `my-secret`is mounted two times.

```yaml
apiVersion: tekton.dev/v1beta1
kind: TaskRun
metadata:
  generateName: custom-volume-
spec:
  workspaces:
    - name: custom
      persistentVolumeClaim:
        claimName: my-pvc
      subPath: my-subdir
    - name: custom2
      persistentVolumeClaim:
        claimName: my-pvc
    - name: custom3
      emptyDir: {}
      subPath: testing
    - name: custom4
      configMap:
        name: my-configmap
        items:
          - key: message
            path: my-message.txt
    - name: custom5
      secret:
        secretName: my-secret
  taskSpec:
    steps:
    - name: write
      image: registry.access.redhat.com/ubi7/ubi-minimal:7.8-366
      script: echo $(workspaces.custom.volume) > $(workspaces.custom.path)/foo
    - name: read
      image: registry.access.redhat.com/ubi7/ubi-minimal:7.8-366
      script: cat $(workspaces.custom.path)/foo | grep $(workspaces.custom.volume)
    - name: write2
      image: registry.access.redhat.com/ubi7/ubi-minimal:7.8-366
      script: echo $(workspaces.custom2.path) > $(workspaces.custom2.path)/foo
    - name: read2
      image: registry.access.redhat.com/ubi7/ubi-minimal:7.8-366
      script: cat $(workspaces.custom2.path)/foo | grep $(workspaces.custom2.path)
    - name: write3
      image: registry.access.redhat.com/ubi7/ubi-minimal:7.8-366
      script: echo $(workspaces.custom3.path) > $(workspaces.custom3.path)/foo
    - name: read3
      image: registry.access.redhat.com/ubi7/ubi-minimal:7.8-366
      script: cat $(workspaces.custom3.path)/foo | grep $(workspaces.custom3.path)
    - name: readconfigmap
      image: registry.access.redhat.com/ubi7/ubi-minimal:7.8-366
      script: cat $(workspaces.custom4.path)/my-message.txt | grep "hello world"
    - name: readsecret
      image: registry.access.redhat.com/ubi7/ubi-minimal:7.8-366
      script: |
        #!/usr/bin/env bash
        set -xe
        cat $(workspaces.custom5.path)/username | grep "user"
        cat $(workspaces.custom5.path)/message | grep "hello secret"
    workspaces:
    - name: custom
    - name: custom2
      mountPath: /foo/bar/baz
    - name: custom3
    - name: custom4
      mountPath: /baz/bar/quux
    - name: custom5
      mountPath: /my/secret/volume
```


## Task {{% param sectionnumber %}}.2 Artifcat publishing

A common question is `How can I store my artifacts like test reports in Tekton?`
Unfortunately Tekton doesn't offer artifact managment. If you want to store your artefacts (e.g. Test or security scan reports, build artifacts) you have to do this by yourself. For example store your reports on a S3 compatible storage.

Following example shows how to use a generic Task to store artifacts on our Gitea instance.

First we are going to reuse the go build task from the previous lab. Create a new file called `lab061/build-task.yaml`

{{< readfile file="src/caching/task.yaml"  code="true" lang="yaml"  >}}

Use following command to create a new *TaskRun*

```bash
{{% param cliToolName %}} apply -f lab061/build-task.yaml --namespace $USER
```

Next create a new Task file named `lab061/upload-task.yaml` with following content:

{{< readfile file="src/caching/publish-task.yaml"  code="true" lang="yaml"  >}}

And apply the newly created file to the cluster with following command

```bash
{{% param cliToolName %}} apply -f lab061/upload-task.yaml --namespace $USER
```

Finally we can create our Pipeline called `lab061/pipeline.yaml` ressource which executes the following tasks:

* `git-clone` checkout our awesome app Repository
* `build-task` build the go binary
* `upload` upload the binary to our Gitea server

All tasks are executed in sequence and share the same workspace

{{< readfile file="src/caching/pipeline.yaml"  code="true" lang="yaml"  >}}

And apply the pipeline to the cluster

```bash
{{% param cliToolName %}} apply -f lab061/pipeline.yaml --namespace $USER
```

Create a new PipelineRun `lab061/pipelinerun.yaml` with following content:
{{< readfile file="src/caching/publish-run.yaml"  code="true" lang="yaml"  >}}

And apply the newly created file to the cluster with following command

```bash
{{% param cliToolName %}} apply -f lab061/pipelinerun.yaml --namespace $USER
```

Finally you can navigate in Gitea to the release page and check if the release was uploaded successfully.
You can check with following URL `https://gitea.training.openshift.ch/<username>/-/packages`. Just replace the `<username>` with your user.


## Task {{% param sectionnumber %}}.3: Cleanup

Clean up all resources created in this chapter:

```bash
{{% param cliToolName %}} delete -f lab061/pipeline.yaml --namespace $USER 
{{% param cliToolName %}} delete -f lab061/pipeline.yaml --namespace $USER 
{{% param cliToolName %}} delete -f lab061/pipelinerun.yaml --namespace $USER 
```
