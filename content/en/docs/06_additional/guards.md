---
title: "6.2 Task Guards"
weight: 62
sectionnumber: 6.2
---


## {{% param sectionnumber %}}.1: Task Guards

To run a Task only when certain conditions are met, it is possible to guard task execution using the `when` field. The when field allows you to list a series of references to when expressions.

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

The second example shows how to check if an array not containing the given elememt `blue`

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

Remeber the simple example from our first pipeline in lab 3?

{{< readfile file="../03_first_pipeline/src/test-task.yaml"  code="true" lang="yaml" >}}

{{< readfile file="../03_first_pipeline/src/test-pipeline.yaml"  code="true" lang="yaml" >}}

One of the most commun use cases is to controll which *Task* should run on which branches. For example in a real world scenario you don't want to execute all End-to-End test when you commit to a develop branch.

Lets add a Task Guards to the Tasks to controll their execution based on an input parameter.

* Rename the *Task* to `test-guard`
* Rename the *Pipeline* to `test-guard`
* Add a `when` condition to the first task with following condition: Only run this task if the paramater `name` **is not equal** with one of `Captain Awesome` or  `Captain Obvious`
* Add a `when` condition to the second task with following condition: Only run this task if the paramater `name` is equal `Chuck Norris`

{{< readfile file="src/guards/task.yaml"  code="true" lang="yaml" >}}

{{< readfile file="src/guards/pipeline.yaml"  code="true" lang="yaml" >}}


Enter follwing commands to create the *Task* and the *Pipeline*

```bash
{{% param cliToolName %}} -f task.yaml -n $USER
{{% param cliToolName %}} -f pipeline.yaml -n $USER
```

Now er are going to start the pipeline direct from the cli. For this you can use following command:
After that the Tekton CLI ask you to provide the parameters

```bash
tkn p start test-when --showlog
```

As you can see, with the paramater value `Chuck Norris`, both tasks are executed.

```bash
tkn p start test-when --showlog

? Value for param `name` of type `string`? (Default is `Chuck Norris`) Chuck Norris
PipelineRun started: test-when-run-g59fv
Waiting for logs to be available...
[task-2 : echo] Hello, world

[inline : task-1] Hello, Chuck Norris
```

Now try with another parmater value, for example `Nelson Mandela`. In this case only the first task `task-1` is executed.

```bash
tkn p start test-when --showlog

? Value for param `name` of type `string`? (Default is `Chuck Norris`) Nelson Mandela
PipelineRun started: test-when-run-2r4d8
Waiting for logs to be available...
[inline : task-1] Hello, Chuck Norris
```


## Task {{% param sectionnumber %}}.4: Cleanp

```bash
{{% param cliToolName %}} delete -f task.yaml -n $USER
{{% param cliToolName %}} delete -f pipeline.yaml -n $USER
```
