---
title: "6.6 Failures and Notifications"
weight: 66
sectionnumber: 6.6
---


## {{% param sectionnumber %}}.1: Failures

//TODO

## {{% param sectionnumber %}}.2: Notifications

A common usecase is to notify your team about successfull or failed pipelines. In Tekton we can achieve this by adding sepcifiec Tasks which handle the notifications. There are lot of different community *Tasks* which you can use.


## {{% param sectionnumber %}}.3: Slack notifications

```bash
{{% param cliToolName %}} apply -f https://api.hub.tekton.dev/v1/resource/tekton/task/send-to-webhook-slack/0.1/raw -n $USER
```


```bash
{{% param cliToolName %}} create secret generic webhook-secret --from-literal=url=<ask your teacher for url> -n $USER
```


```yaml
apiVersion: tekton.dev/v1beta1
kind: TaskRun
metadata:
  name: run-send-to-webhook-slack
spec:
  params:
  - name: webhook-secret
    value: webhook-secret
  - name: message
    value: "Hello from Tekton!"
  taskRef:
    name: send-to-webhook-slack
```


## {{% param sectionnumber %}}.3: Slack notifications on failure

//TODO

{{< highlight yaml >}}{{< readfile file="src/notifications/pr.yaml" >}}{{< /highlight >}}