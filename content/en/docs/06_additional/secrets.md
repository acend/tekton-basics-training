---
title: "6.3 Secrets"
weight: 63
sectionnumber: 6.3
---


## {{% param sectionnumber %}}.1: Task with Secrets

In lab 3 we learned how to build a parametrized *Task*. In this first section of this lab we are going to show you how to use Kubernetes native secrets for your tasks.


{{< highlight yaml >}}{{< readfile file="../03_first_pipeline/src/test-parameterized-task.yaml" >}}{{< /highlight >}}


{{< highlight yaml >}}{{< readfile file="src/secrets/task.yaml" >}}{{< /highlight >}}


```bash
{{% param cliToolName %}} apply -f task.yaml -n $USER
```


{{< highlight yaml >}}{{< readfile file="src/secrets/secret.yaml" >}}{{< /highlight >}}

```bash
{{% param cliToolName %}} apply -f secret.yaml -n $USER
```

Because we didn't specify any parameters for the task, we don't need to create a pipeline. We can easily trigger the task with the tekton cli.
Just run folloing command in your console.

```bash
tkn task start secret-test --showlog -n $USER
```

After a while you should see following ouput

```console
TaskRun started: secret-test-run-wdd6b
Waiting for logs to be available...
[echo] My secret is foobar
```

```bash
{{% param cliToolName %}} delete -f task.yaml -n $USER
{{% param cliToolName %}} delete -f secret.yaml -n $USER
```
