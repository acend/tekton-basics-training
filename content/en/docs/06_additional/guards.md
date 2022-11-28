---
title: "6.2 Task Guards"
weight: 62
sectionnumber: 6.2
---


## {{% param sectionnumber %}}.1: Task Guards

By running a Task only when certain conditions are met, it is possible to guard task execution using the `when` field. The `when` field allows you to list a series of references to when expressions.

The components of when expressions are input, operator and values:

* input is the input for the when expression which can be static inputs or variables (Parameters or Results). If the input is not provided, it defaults to an empty string.
* operator represents an input’s relationship to a set of values. A valid operator must be provided, which can be either **in** or **notin**.
* values is an array of string values. The values array must be provided and be non-empty. It can contain static values or variables (Parameters, Results or a Workspaces’s bound state).

Here are tow simple examples for when expressions.

The first examples check if the parameter `path` contains the value `Readme.md` . If so the task is going to be executed.

```yaml
tasks:
  - name: first-create-file
    when:
      - input: "$(params.path)"
        operator: in
        values: ["README.md"]
    taskRef:
      name: first-create-file
```

The second example shows how to check if an array does not contain the given element `blue`

```yaml
tasks:
  - name: deploy-in-blue
    when:
      - input: "blue"
        operator: notin
        values: ["$(params.deployments[*])"]
    taskRef:
      name: deployment
```


## Task {{% param sectionnumber %}}.2: Task Guards

Create a new directory lab062 for this in your workspace directory.

```bash
mkdir lab062
```

Remember the simple example from our first pipeline in lab 3?

{{< readfile file="../03_first_pipeline/src/test-task.yaml"  code="true" lang="yaml" >}}

{{< readfile file="../03_first_pipeline/src/test-pipeline.yaml"  code="true" lang="yaml" >}}

One of the most common use cases is to control which *Task* should run on which branch. For example in a real world scenario you wouldn't want to execute all End-to-End tests when you commit to a development branch.

Let's add *TaskGuards* to the *Tasks* to control their execution based on an input parameter.

* Rename the *Task* to `test-guard`
* Rename the *Pipeline* to `test-guard`
* Add a `when` condition to the first task with following condition: Only run this task if the parameter `name` **is not equal** with either `Captain Awesome` or  `Captain Obvious`
* Add a `when` condition to the second task with the following condition: Only run this task if the parameter `name` is equal `Chuck Norris`

Create a new file with the name `lab062/task.yaml` with the following content:

{{< readfile file="src/guards/task.yaml"  code="true" lang="yaml" >}}

Create a new file with the name `lab062/pipeline.yaml` with the following content:

{{< readfile file="src/guards/pipeline.yaml"  code="true" lang="yaml" >}}


Enter the following commands in the CLI to create the *Task* and the *Pipeline*

```bash
{{% param cliToolName %}} apply -f lab062/task.yaml --namespace $USER 
{{% param cliToolName %}} apply -f lab062/pipeline.yaml --namespace $USER 
```

Now we are going to start the pipeline directly from the CLI. For this you can use the following command:
After that the Tekton CLI will ask you to provide the parameters.

```bash
tkn p start test-when --showlog --namespace $USER 
```

As you can see, with the parameter value `Chuck Norris`, both tasks were executed.

```bash
tkn p start test-when --showlog --namespace $USER 

? Value for param `name` of type `string`? (Default is `Chuck Norris`) Chuck Norris
PipelineRun started: test-when-run-g59fv
Waiting for logs to be available...
[task-2 : echo] Hello, world

[inline : task-1] Hello, Chuck Norris
```

Now you can try to execute the run with another parameter value, for example `Nelson Mandela`. In this case only the first task `task-1` will be executed.

```bash
tkn p start test-when --showlog --namespace $USER 

? Value for param `name` of type `string`? (Default is `Chuck Norris`) Nelson Mandela
PipelineRun started: test-when-run-2r4d8
Waiting for logs to be available...
[inline : task-1] Hello, Chuck Norris
```


## Task {{% param sectionnumber %}}.4: Cleanp

Don't forget to clean up your workspace after you finished by executing the following commands in the CLI.

```bash
{{% param cliToolName %}} delete -f lab062/task.yaml --namespace $USER 
{{% param cliToolName %}} delete -f lab062/pipeline.yaml --namespace $USER 
```
