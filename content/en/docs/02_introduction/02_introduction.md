---
title: "2. Tekton Introduction"
weight: 2
sectionnumber: 2
---

Tekton brings the CI/CD world closer to the cloud native ecosystem. It is a powerful continuous integration and continuous delivery engine integrated in your well-known Kubernetes stack! In this chapter, we will get to know the building blocks on which Tekton is built upon.


## {{% param sectionnumber %}}.1: Basic Concepts

Tekton is based on already familiar concepts. All the elements needed for building efficient pipelines are available as custom resource definitions [CRD](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/)) in your Kubernetes cluster. Let's take a look at them and familiarize ourselves with their terminologies:

* [Task](https://github.com/tektoncd/pipeline/blob/master/docs/tasks.md): A collection of steps that perform a specific task.
* [Pipeline](https://github.com/tektoncd/pipeline/blob/master/docs/pipelines.md): A series of tasks, combined to work together in a defined (structured) way
* [TaskRun](https://github.com/tektoncd/pipeline/blob/master/docs/taskruns.md): The execution and result of running an instance of a task
* [PipelineRun](https://github.com/tektoncd/pipeline/blob/master/docs/pipelineruns.md): The actual execution of a whole Pipeline, containing the results of the pipeline (success, failed...)

Pipelines and tasks should be generic and must never define possible variables - such as 'input git repository' - directly in their definition. The concrete PipelineRun will get the parameters, that are being used inside the pipeline.

[Workspaces](https://redhat-scholars.github.io/tekton-tutorial/tekton-tutorial/workspaces.html) are used to share the data between Tasks and Steps.

![Static Pipeline Definition](../concept-tasks-pipelines.png.png)
*Static definition of a Pipeline*

For each task, a pod will be allocated and for each step inside this task, a container will be used.

![Pipeline Runtime View](../concept-runs.png)
*Runtime view of a Pipeline showing mapping to pods and containers*


## {{% param sectionnumber %}}.1: Tasks

The lowest building block that Tekton relies upon is a **Task**. A Task can contain one or many Steps that you define and will be run in a specific order of execution. Each Task will be executed as a Pod on your Kubernetes cluster. Tasks are in general specific to a namespace, while a ClusterTask is available across the entire cluster.

A declaration of a Task includes the follwing elements:

* Parameters: Specifying parameters, such as compilation flags or artifact names, to supply the Task at execution time
* Resources: **DEPRECATED** Collection of input and output resources of the Task
* Steps: A reference to a container image that executes a specific tool on specific input and produces a specific output
* Workspaces: Allow you to specify one or more volumes that your Task requires during execution
* Results: A string result emitted by each run of the task which can be referenced later

Here is an example for a Task:

```yaml
apiVersion: tekton.dev/v1beta1
kind: Task
metadata:
  name: test
spec:
  params:
    - default: Raffael
      name: name
      type: string
  results:
    - description: Greeting message
      name: greet
  steps:
    - image: bash:latest
      name: greet
      resources: {}
      script: |
        #!/usr/bin/env bash
        printf "Hello, %s" "$(params.name)" > "$(results.greet.path)"
```

For more details check the official [documentation](https://tekton.dev/docs/pipelines/tasks/).


## {{% param sectionnumber %}}.2: Pipeline

A Pipeline is a collection of Tasks that you define and arrange in a specific order of execution as part of your continuous integration flow. Each Task in a Pipeline executes as a Pod on your Kubernetes cluster. You can configure various execution conditions to fit your business needs.

The Pipeline definition must consist of:

* Tasks: The `spec.task` field must include one task which runs

The Pipeline definition can also consist of:

* Resources: Deprecated Specifies PipelineResources needed or created by the Tasks comprising the Pipeline
* Params: Parameters that the Pipeline requires
* Workspaces: A set of Workspaces that the Pipeline require
* Results: Specifies the location to which the Pipeline emits its execution results
* Description: Holds an informative description of the Pipeline object
* Finally: One or more Tasks to be executed in parallel after all other tasks have completed

An example of a configured Pipeline might look like this:

```yaml
apiVersion: tekton.dev/v1beta1
kind: Pipeline
metadata:
  name: svc-deploy
spec:
  params:
    - name: contextDir
      description: the context directory from where to build the application
    - name: destinationImage
      description: the fully qualified image name
    - name: storageDriver
      description: Use storage driver type vfs if you are running on OpenShift.
      type: string
      default: overlay
  workspaces:
    - name: workspace
  tasks:
    - name: build-java-app
      taskRef:
        name: build-app
      workspaces:
        - name: source
          workspace: workspace
      params:
        - name: contextDir
          value: $(params.contextDir)
        - name: destinationImage
          value: $(params.destinationImage)
        - name: storageDriver
          value: $(params.storageDriver)
    - name: deploy-kubernetes-service
      taskRef:
        name: openshift-client
      runAfter:
        - build-java-app
      params:
        - name: SCRIPT
          value: |
            kubectl create deployment greeter --port=8080 --image=$(params.destinationImage)
            kubectl expose deployment/greeter --port=8080 --target-port=8080 --type=NodePort
```

For more details check the official [documentation](https://tekton.dev/docs/pipelines/pipelines/).


## {{% param sectionnumber %}}.3: TaskRun

The TaskRun is the single run representation of a Task - see it as an instantiation of your Task definition. It specifies one or more Step that will execute conatiner images and perform a defined piece of build work. They are executed in the order of definition until all Steps have executed successfully or one failure occured.

For more details check the official [documentation](https://tekton.dev/docs/pipelines/taskruns/).


## {{% param sectionnumber %}}.4: PipelineRun

A PipelineRun allows you to instantiate and execute a Pipeline on-cluster. A Pipeline specifies one or more Tasks in the desired order of execution. A PipelineRun executes the Tasks in the Pipeline in the order they are specified until all Tasks have executed successfully or a failure occurs.

Note: A PipelineRun automatically creates corresponding TaskRuns for every Task in your Pipeline.

The Status field tracks the current state of a PipelineRun, and can be used to monitor progress. This field contains the status of every TaskRun, as well as the full PipelineSpec used to instantiate this PipelineRun, for full auditability.

Every PipelineRun must consist of:

* PipelineRef or PipelineSpec: Either reference a Pipeline to run or specify a new one

And can be further configured with:

* Resources: The PipelineResources to provision for executing the target Pipeline.
* Params: The desired execution parameters for the Pipeline.
* ServiceAccountName: ServiceAccount object that supplies specific execution credentials for the Pipeline.
* Status: Specifies options for cancelling a PipelineRun.
* TaskRunSpecs: A list of PipelineRunTaskSpec which allows for setting ServiceAccountName, Pod template, and Metadata for each task. This overrides the Pod template set for the entire Pipeline.
* Timeouts: Specifies the timeout before the PipelineRun fails. timeouts allows more granular timeout configuration, at the pipeline, tasks, and finally levels
* PodTemplate: A Pod template to use as the basis for the configuration of the Pod that executes each Task.
* Workspaces: The set of workspace bindings which must match the names of workspaces declared in the pipeline being used.

For more details check the official [documentation](https://tekton.dev/docs/pipelines/pipelineruns/).
