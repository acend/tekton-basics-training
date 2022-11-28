---
title: "6.5 Workflow"
weight: 65
sectionnumber: 6.5
---

In a pipeline automation, workflow control is key. Certain steps can be run in parallel, others should run after each other. Tekton allows you to create relations between separated steps to control your workflow.

*Tasks* in Tekton can be connected in a *Pipeline* to build a **Directed Acyclic Graph** (DAG). Each *Task* in a *Pipeline* becomes a node on the graph that can be connected with an edge. This way, one *Task* needs to run to completion before another can start and the execution of the *Pipeline* progresses to completion without getting stuck in an infinite loop.

In this lab we are going to dive into the possibilities to control the flow of your *Pipelines*.


## {{% param sectionnumber %}}.1: Step sequence

The classic imperative approach for pipelines is a sequence of steps. We usually tend to think imperative anyways, so this is very convenient. In this section we are going to work with the following default Java **Pipeline**:

{{< readfile file="src/pipeline-1.yaml"  code="true" lang="yaml" >}}

We can trigger the pipeline with the **PipelineRun**:

{{< readfile file="src/pipelinerun-1.yaml" code="true" lang="yaml" >}}

The defined **Pipeline** will clone the repository and afterwards build the application after the *git-clone* step. This is guaranteed by this section:

```yaml
    ...
    - name: build
      runAfter:
      - git-clone
```

Apply the *Pipeline* Resource and start the *Pipeline* with the *PipelineRun* resource. You can reuse the *PipelineRun* resource for all the upcoming examples.

```bash
{{% param cliToolName %}} apply -f pipeline.yaml --namespace $USER
{{% param cliToolName %}} apply -f pipelinerun.yaml --namespace $USER
```


## {{% param sectionnumber %}}.2: Parallelism

In Tekton the default ordering or precedence of tasks is never given and they will be run in parallel.

If we would want to add another step to our **Pipeline** to execute the Maven Task *test* this could look like the following:

{{< readfile file="src/pipeline-2.yaml" code="true" lang="yaml" >}}

Both **Tasks**: *build* and *test* define the dependency to run after *git-clone*. They have the same precedence and will therefore run in parallel.

![Tasks with same precendence will run in parallel](../img/parallel.png)


## {{% param sectionnumber %}}.3: Conditional reaction

Another widely used control mechanism of the pipeline's workflow are conditionals. In Tekton conditionals can be used to control the execution of a Task:

{{< readfile file="src/pipeline-3.yaml" code="true" lang="yaml" >}}

The following block reacts upon the parameter language `$(params.language)`:

```yaml
    - name: react-java
      when:
      - input: $(params.language)
        operator: in
        values: [ "java" ]
```

The syntax of these conditionals is fairly simple. It consists of three main components:

* `input`: Input for the expression can be static or from *Parameters* or *Results*.
* `operator`: Can either be `in` or `notin`, therefore expecting the `values` to be contained in the `input` or not.
* `values`: An array of string values. It can contain non-static values or variables (*Parameters*, *Results* or a *Workspace's* bound state).


### {{% param sectionnumber %}}.3.1: Reacting upon results

One of the most obvious choices, to create conditionals upon, are *Results*. *Results* of previous run *Tasks* can be accessed via the `$(tasks.<taskname>.results.<resultname>)`.

For example the used *Task* `git-clone`, emits two results: `commit` containing the commit hash and `url` containing the URL of the repository. Take a look at the following example reacting upon the result:

{{< readfile file="src/pipeline-3-1.yaml" code="true" lang="yaml" >}}


## {{% param sectionnumber %}}.4: Finally

The last example we are going to look at is how we can guarantee a *Task's* execution (for example when a *Task* failed before). Tekton Pipelines are canceled after the first failure (return code > 0). Tekton adds a construct called `finally`, which defines a set of *Tasks*, which will run at the end of a *Pipeline*. The `finally` block is similar to the `tasks` block of a *Pipeline*:

{{< readfile file="src/pipeline-4.yaml" code="true" lang="yaml" >}}


## {{% param sectionnumber %}}.5: Cleanup

Remove all the resources from the lab:

```bash
{{% param cliToolName %}} delete pipeline,pipelinerun --selector=ch.acend/lab="tekton-basics" --namespace $USER
```
