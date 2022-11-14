---
title: "5. Trigger more complex pipelines"
weight: 5
sectionnumber: 5
---

In the previous chapter we have designed a pipeline composing two tasks to checkout and build a docker image from a go application repository. We want to go a bit further and show what Tekton really is capable of. This time we will switch the language and implement a CI/CD pipeline for a Java project. Additional to writing pipelines, tasks and the stuff we already know, we are going to take a look at Tekton **Triggers**.


## {{% param sectionnumber %}}.1: Triggers

We are already familiar with resources defining pipelines and their building blocks. But starting pipelines manually should not be the idea of any automation software.

Tekton Triggers give us additional concepts to bring more possibilities to react to certain events and run our pipelines. At it's base there are three new concepts: EventListener, Trigger and Triggerbinding.


## {{% param sectionnumber %}}.1.1: EventListener

The Tekton **EventListener** is a sink which will listen to events at a specified port on the Kubernetes cluster. It automatically creates a service, your addressable sink, and specifies one or more *Triggers*. The defined *Triggers* can extract fields from the event payload via *TriggerBindings* and *TriggerTemplates* give you the possibility to create Tekton resources like *TaskRuns* or *PipelineRuns* with the data binded. If necessary the data binded can be intercepted and altered with one or more *Interceptors*.

```yaml
apiVersion: triggers.tekton.dev/v1beta1
kind: EventListener
metadata:
  name: eventlistener
spec:
  triggers:
    - name: trigger-1
      interceptors:
        - github:
            eventTypes: ["pull_request"]
      bindings:
        - ref: pipeline-binding # Reference to a TriggerBinding object
        - name: message # Embedded Binding
          value: Hello from the Triggers EventListener!
      template:
        ref: pipeline-template
```


## {{% param sectionnumber %}}.1.2: Trigger / TriggerTemplate

The reaction on an event detected by a *EventListener* is defined in the **Trigger** resource. A *Trigger* specifies a TriggerTemplate, a TriggerBinding, and optionally an Interceptor

The **TriggerTemplate** specifies what resources should be instantiated or executed when the *EventListener* detects an event.
A **TriggerTemplate** is a resource that specifies a blueprint for the resource, such as a TaskRun or *PipelineRun*, that you want to instantiate and/or execute when your *EventListener* detects an event. It exposes parameters that you can use anywhere within your resource’s template.

```yaml
apiVersion: triggers.tekton.dev/v1beta1
kind: TriggerTemplate
metadata:
  name: pipeline-template
spec:
  params:
  - name: gitrevision
    description: The git revision
    default: main
  - name: gitrepositoryurl
    description: The git repository url
  - name: message
    description: The message to print
    default: This is the default message
  - name: contenttype
    description: The Content-Type of the event
  resourcetemplates:
  - apiVersion: tekton.dev/v1beta1
    kind: PipelineRun
    metadata:
      generateName: simple-pipeline-run-
    spec:
      pipelineRef:
        name: simple-pipeline
      params:
      - name: message
        value: $(tt.params.message)
      - name: contenttype
        value: $(tt.params.contenttype)
      resources:
      - name: git-source
        resourceSpec:
          type: git
          params:
          - name: revision
            value: $(tt.params.gitrevision)
          - name: url
            value: $(tt.params.gitrepositoryurl)
```


## {{% param sectionnumber %}}.1.3: TriggerBinding

So far we have defined to which *Events* we are going to listen, what *Triggers* will be executed on the *Event*. The missing element is the binding of data between these two and this is where *TriggerBindings* come into play. They allow us to bind fields from event payloads to named parameters used in a *TriggerTemplate*.

*TriggerBindings* can be inline in the *Trigger* or can be separate resources.

Inline:
```yaml
apiVersion: triggers.tekton.dev/v1beta1
kind: Trigger
metadata:
  name: push-trigger
spec:
  bindings:
  - name: gitrevision
    value: $(body.head_commit.id)
  - name: gitrepositoryurl
    value: $(body.repository.url)
  template:
    ref: git-clone-template
```

Custom resource:
```yaml
apiVersion: triggers.tekton.dev/v1beta1
kind: TriggerBinding
metadata:
  name: pipeline-binding
spec:
  params:
  - name: gitrevision
    value: $(body.head_commit.id)
  - name: gitrepositoryurl
    value: $(body.repository.url)
  - name: contenttype
    value: $(header.Content-Type)
```


## Task {{% param sectionnumber %}}.X: Create the pipeline

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
  - name: repository
    value: https://github.com/acend/awesome-apps
  - name: application
    value: java-quarkus
  - name: image
    value: ttl.sh/$(uuidgen):1h
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

If you have your *Pipeline* and *PipelineRun* resources created on the cluster, check the logs of the *PipelineRun* to verify that the repository was cloned successfully!


## Task {{% param sectionnumber %}}.2: Classic Java

In this section you are going to adopt a classic java build pipeline in Tekton. It should consist of the following stages:

* Checkout
* Test
* Package
* Container build
* Deployment
  
We integrate now two parts of pipelines in our scenario: integration and delivery!


## Task {{% param sectionnumber %}}.3: Fire

```bash
curl -X POST -d '{ "repository": "https://github.com/acend/awesome-apps", "application": "java-quarkus", "image": "ttl.sh/$(uuidgen):1h", "context": "/workspace/source/java-quarkus", "dockerfile": "./Dockerfile" }' <trigger-host>
```
