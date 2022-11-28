---
title: "5. Trigger more complex pipelines"
weight: 5
sectionnumber: 5
---

In the previous chapter we have designed a pipeline composing two tasks to checkout and build a docker image from a go application repository. We want to go a bit further and show what Tekton really is capable of. This time we will switch the language and implement a CI/CD pipeline for a Java project. Additional to writing pipelines, tasks and the stuff we already know, we are going to take a look at Tekton **Triggers**.


## {{% param sectionnumber %}}.1: The Custom Resources

The following custom resources will be new in this chapter. Read the first three subsections to familiarize yourself with the Trigger API resources.


## {{% param sectionnumber %}}1.1: Triggers

We are already familiar with resources defining pipelines and their building blocks. But starting pipelines manually should not be the idea of any automation software.

Tekton Triggers give us additional concepts to bring more possibilities to react to certain events and run our pipelines. At its base there are three new concepts: EventListener, Trigger and Triggerbinding.


## {{% param sectionnumber %}}.1.1: EventListener

The Tekton **EventListener** is a sink which will listen to events at a specified port on the Kubernetes cluster. It automatically creates a service, your addressable sink, and specifies one or more *Triggers*. The defined *Triggers* can extract fields from the event payload via *TriggerBindings* and *TriggerTemplates*, giving you the possibility to create Tekton resources like *TaskRuns* or *PipelineRuns* with the data binded. If necessary the data binded can be intercepted and altered with one or more *Interceptors*.

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

The reaction on an event detected by an *EventListener* is defined in the **Trigger** resource. A *Trigger* specifies a TriggerTemplate, a TriggerBinding, and optionally an Interceptor.

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
  labels:
    ch.acend/lab: "tekton-basics"
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


## Task {{% param sectionnumber %}}.2: Create the pipeline

Create a *Pipeline* resource `java-pipeline` with a single step to checkout the [awesome-apps](https://github.com/acend/awesome-apps) repository. We can again reuse the already predefined *Task* **git-clone**. Try to parameterize as much as possible already, create parameters for the repository's URL and the corresponding subfolder (this time we will build the application in the `java-quarkus` subfolder).

Create a file named `lab05/pipeline.yaml` with the following content:

{{< readfile file="src/pipeline.yaml" code="true" lang="yaml" >}}

Apply the created *Pipeline* to the cluster in your namespace:

```bash
{{% param cliToolName %}} create -f lab05/pipeline.yaml -n $USER
```


## Task {{% param sectionnumber %}}.3: Create the EventListener

The entire functionality of CI/CD automation comes from reacting to certain events. As a day to day example let's imagine we created a webhook from Github or any alternative to trigger our pipeline.

Create a **EventListener** called *java-pipeline-listener* resource binding a **TriggerBinding** *java-pipeline-pipelinebinding* and defining the **TriggerTemplate** *java-pipeline-triggertemplate* you are going to create.

Create a file in `lab05/eventlistener.yaml` with the following content:

{{< readfile file="src/eventlistener.yaml" code="true" lang="yaml" >}}

```bash
{{% param cliToolName %}} create -f lab05/eventlistener.yaml -n $USER
```

After you have created the **EventListener** you should see that there was already a service created for you.

```yaml
$ {{% param cliToolName %}} get svc
NAME                        TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)             AGE
el-java-pipeline-listener   ClusterIP   172.30.174.45   <none>        8080/TCP,9000/TCP   5s
```

This should list the service `el-java-pipeline-listener` created for you in your namespace.


## Task {{% param sectionnumber %}}.4: Add ServiceAccount and Role

If you take a closer look at the object, you can see there is a **ServiceAccount** *tekton-trigger* defined in the EventListener above. Of course the cluster has to react to a certain event. To do that it needs to observe and even create some resources. For example the **PipelineRun** created from the event.

We have a minimialistic ServiceAccount with Role and RoleBinding to enable you to cover all the default use cases. Just create a file `lab05/sa.yaml` with the following content:

{{< readfile file="src/sa.yaml" code="true" lang="yaml" >}}

```bash
{{% param cliToolName %}} create -f lab05/sa.yaml -n $USER
```


## Task {{% param sectionnumber %}}.5: Bind the parameters with a TriggerBinding

After creating the needed ServiceAccounts with its Role and RoleBinding, we are going to take a look at the **TriggerBinding**. Create the **TriggerBinding** *java-pipeline-pipelinebinding* binding the REST body's fields `repository`, `application`, `context` and `dockerfile` to the trigger. An example incoming HTTP request to trigger your Pipeline could look like this:

```json
{
  "repository": "https://github.com/acend/awesome-apps",
  "application": "java-quarkus",
  "image": "ttl.sh/$(uuidgen):1h",
  "context": "/workspace/source/java-quarkus",
  "dockerfile": "./Dockerfile"
}
```

If you don't remember how the **TriggerBinding** should look like, take a look at section {{% param sectionnumber %}}.1.3.

{{< readfile file="src/triggerbinding.yaml" code="true" lang="yaml" >}}

```bash
{{% param cliToolName %}} create -f triggerbinding.yaml -n $USER
```


## Task {{% param sectionnumber %}}.6: TriggerTemplate

At last, create the **TriggerTemplate** bringing it all together to trigger the **PipelineRun** defined above!

{{< readfile file="src/triggertemplate.yaml" code="true" lang="yaml" >}}

```bash
{{% param cliToolName %}} create -f triggertemplate.yaml -n $USER
```


## Task {{% param sectionnumber %}}.7: Fire

Expose the service created by the **EventListener** and fire a HTTP request against the endpoint created!

```bash
{{% param cliToolName %}} -n $USER expose svc el-java-pipeline-listener --hostname='trigger-$USER.$APPDOMAIN'
```

```bash
curl -X POST -d '{ "repository": "https://github.com/acend/awesome-apps", "application": "java-quarkus", "image": "ttl.sh/$(uuidgen):1h", "context": "/workspace/source/java-quarkus", "dockerfile": "./Dockerfile" }' trigger-$USER.$APPDOMAIN
```


## Task {{% param sectionnumber %}}.5: Cleanup

Remove all the resources created in this lab again:

```bash
{{% param cliToolName %}} -n $USER delete pipeline,eventlistener,serviceaccount,role,rolebinding,clusterrole,clusterrolebinding,triggerbinding,triggertemplate --selector='ch.acend/lab=tekton-basics'

```
