---
title: "6.6 Failures and Notifications"
weight: 66
sectionnumber: 6.6
---


## {{% param sectionnumber %}}.1: Failures

//TODO


## {{% param sectionnumber %}}.2: Notifications

A common usecase is to notify your team about successfull or failed pipelines. In Tekton we can achieve this by adding sepcifiec Tasks which handle the notifications. There are lot of different community *Tasks* which you can use.

* [Microsoft Teams](https://github.com/tektoncd/catalog/tree/main/task/send-to-microsoft-teams/0.1)
* [Telegram](https://github.com/tektoncd/catalog/tree/main/task/send-to-telegram/0.1)
* [Webex](https://github.com/tektoncd/catalog/tree/main/task/send-to-webex-room/0.1)
* [Discord](https://github.com/tektoncd/catalog/tree/main/task/send-to-webhook-discord/0.1)
* [SMTP Mail](https://github.com/tektoncd/catalog/tree/main/task/sendmail)


## Example {{% param sectionnumber %}}.3: Slack notifications

In this section we are going to show you how to implement s Slack channel notification for your pipelines.
First we need to create the Slack Notification task, for this we take one of the community tasks. Use following command to create the task.

```bash
{{% param cliToolName %}} apply -f https://api.hub.tekton.dev/v1/resource/tekton/task/send-to-webhook-slack/0.1/raw -n $USER
```

Next create a secret which contains the URL for the Slack webhook. **Ask your teacher for the URL!**

```bash
{{% param cliToolName %}} create secret generic webhook-secret --from-literal=url=<ask your teacher for url> -n $USER
```

To check if everything is working as expected, create following task run to test the Slack notification.
You can change the message text as you want.

{{< readfile file="src/notifications/taskrun.yaml"  code="true" lang="yaml"  >}}

Use following command to create a new *TaskRun*

```bash
{{% param cliToolName %}} create -f taskrun.yaml
```

Now you should see a new notification in the Slack channel.


## Example {{% param sectionnumber %}}.3: Slack notifications on failure

Now it is time for a more complex example. Lets take a closer look the following *PipelineRun*
The pipeline contains one single *Task* called fifty-fifty. The *Task* does nothing more than exit either with `0` or `1`.

Based on the exit condition `$(tasks.inline.status)` one of the two finally tasks is executed.
You can find a complete list of all accessible *Task* variables [here](https://tekton.dev/docs/pipelines/variables/#variables-available-in-a-task)
Further as you can see we making use of Pipelines Variable substitution in the message text. All available Pipeline variables are defined [here](https://tekton.dev/docs/pipelines/variables/#variables-available-in-a-pipeline)

{{< readfile file="src/notifications/pr.yaml" code="true" lang="yaml"  >}}


## Task {{% param sectionnumber %}}.4: Cleanp

```bash
{{% param cliToolName %}} delete -f https://api.hub.tekton.dev/v1/resource/tekton/task/send-to-webhook-slack/0.1/raw -n $USER
{{% param cliToolName %}} delete -f taskrun.yaml -n $USER
{{% param cliToolName %}} delete secret webhook-secret -n $USER
{{% param cliToolName %}} delete -f pipelinerun.yaml -n $USER
```
