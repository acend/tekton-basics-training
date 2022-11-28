---
title: "6.4 Secrets"
weight: 64
sectionnumber: 6.4
---


## {{% param sectionnumber %}}.1: A Task with a Secret

In lab 3 we learned how to build a parametrized *Task*. In this first section of this lab we are going to show you how to use Kubernetes native secrets for your tasks. Below we see the task from lab 3.

{{< readfile file="../03_first_pipeline/src/test-parameterized-task.yaml"  code="true" lang="yaml"   >}}

Start with a new directory lab064 in your workspace directory.

```bash
mkdir lab064
```

Create a new file `lab064/task.yaml` with the content of the example above, and reference the secret as `name` parameter.

{{< readfile file="src/secrets/task.yaml"  code="true" lang="yaml"  >}}

Use following command to create the task in our cluster.

```bash
{{% param cliToolName %}} apply -f lab064/task.yaml -n $USER
```

Next create the file `lab064/secret.yaml` which contains our secret.

{{< readfile file="src/secrets/secret.yaml"  code="true" lang="yaml"   >}}

And again, apply the file against our cluster.

```bash
{{% param cliToolName %}} apply -f lab064/secret.yaml -n $USER
```

Because we didn't specify any parameters for the task, we don't need to create a pipeline. We can easily trigger the task with the Tekton CLI.
Just run the following command in your console.

```bash
tkn task start secret-test --showlog -n $USER
```

After a while you should see the following output

```console
TaskRun started: secret-test-run-wdd6b
Waiting for logs to be available...
[echo] My secret is foobar
```


## Task {{% param sectionnumber %}}.2: CleanUp

```bash
{{% param cliToolName %}} delete -f lab064/task.yaml -n $USER
{{% param cliToolName %}} delete -f lab064/secret.yaml -n $USER
```
