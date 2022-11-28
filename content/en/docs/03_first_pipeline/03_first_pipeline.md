---
title: "3. Your first pipeline"
weight: 3
sectionnumber: 3
---

In the first chapter we familiarized ourselves with the different building blocks of Tekton! Now it is time to get our hands dirty and test them on our cluster.


## Task {{% param sectionnumber %}}.1: Create our first task

We start by implementing a simple first task to echo a good old "hello, world" to our standard out.

First create a new directory `lab03` for lab 3 in your workspace directory.

```bash
mkdir lab03
```

Then create a new file `lab03/test-task.yaml` containing a `Task` resource which uses a `bash:latest` image to print `Hello, world` to standard out, with the following content:

```yaml
apiVersion: tekton.dev/v1beta1
kind: Task
metadata:
  name: test
spec:
  steps:
  - image: bash:latest
    name: echo
    resources: {}
    script: |
      #!/usr/bin/env bash
      printf "Hello, world"
```

Create the test Task in your namespace:

```bash
{{% param cliToolName %}} apply -f lab03/test-task.yaml --namespace $USER 
```

Your task resource should be created and ready in your namespace! Verify the creation of the resource:

```bash
{{% param cliToolName %}} get tasks --namespace $USER 
```

Instead of using `{{% param cliToolName %}}` you can also list the task using the Tekton CLI:

```bash
tkn task list --namespace $USER
```

which will result in something similar to:

```bash
NAME   DESCRIPTION   AGE
test                 12 seconds ago
```

Use the following command to get a list of subcommands the task command provides:

```bash
tkn task --help --namespace $USER 
```

{{% alert title="Note" color="primary" %}}Again always make sure to specify the namespace you're working in explicitly by passing the `--namespace, -n` parameter{{% /alert %}}


## Task {{% param sectionnumber %}}.2: Run your first Task

After creating and verifying the resource you should be all set to start your first task. To start the task we utilize the `tkn` Tekton CLI:

```bash
tkn task start test --namespace $USER
```
which will result in something similar to:

```
TaskRun started: test-run-<pod>

In order to track the TaskRun progress run:
tkn taskrun logs test-run-<pod> -f -n <username>
```

Remember the resource `TaskRun` which is an instantiation of a `Task` running on your cluster? You can see your run by listing all `TaskRun` resources with the `tkn` command:

```bash
tkn taskrun list --namespace $USER
```

To inspect the logs and verify that our task has done everything we wanted it to, we use:

```bash
tkn taskrun logs <taskrun-name> -f --namespace $USER
```

You should see that the tasks greets us, just like we declared it to.

```
[echo] Hello, world
```


## Task {{% param sectionnumber %}}.3: What just happened? (optional)

When we started our first `Task` in the previous chapter, the Tekton operator in the background took our `Task` definition and translated it into a `Pod`, which ran in our namespace.

```bash
{{% param cliToolName %}} get pod --namespace $USER
```

You should find one completed `Pod` in your namespace:

```
NAME                     READY   STATUS      RESTARTS   AGE
test-run-<taskrun>-pod   0/1     Completed   0          12m
```

As you can see, the name of the pod corresponds to the **name** of the `TaskRun`.

And since the `TaskRun` is a `Pod` we can also have a look at the pod logs with the following command:

```bash
{{% param cliToolName %}} logs test-run-<taskrun>-pod --namespace $USER
```

And also explore the `Pod` resource

```bash
{{% param cliToolName %}} describe pod test-run-<taskrun>-pod --namespace $USER
```

Under `Init Containers` you will find the `place-scripts` container, which is responsible to copy the actual script from our `Task` to a mounted persistent volume (`/tekton/scripts`).
The container `step-echo` will then execute this script.

If we have a closer look at the Arguments within the `place-scripts` init container, you'll find a base 64 encoded string:

```bash
  place-scripts:
    Container ID:  cri-o://6dd45a5282941e4861322888970b01d1036d2045173ed82bd687080266661537
    Image:         registry.redhat.io/ubi8/ubi-minimal@sha256:c7b45019f4db32e536e69e102c4028b66bf5cde173cfff4ffd3281ccf7bb3863
    Image ID:      registry.redhat.io/ubi8/ubi-minimal@sha256:2c8e091b26cc5a73cc7c61f4baee718021cfe5bd2fbc556d1411499c9a99ccdb
    Port:          <none>
    Host Port:     <none>
    Command:
      sh
    Args:
      -c
      scriptfile="/tekton/scripts/script-0-gx7fs"
      touch ${scriptfile} && chmod +x ${scriptfile}
      cat > ${scriptfile} << '_EOF_'
      IyEvdXNyL2Jpbi9lbnYgYmFzaApwcmludGYgIkhlbGxvLCB3b3JsZCIK
      _EOF_
      /tekton/bin/entrypoint decode-script "${scriptfile}"
```

Containing our `Hello World` code

```bash
echo "IyEvdXNyL2Jpbi9lbnYgYmFzaApwcmludGYgIkhlbGxvLCB3b3JsZCIK" |base64 -d
```

```
#!/usr/bin/env bash
printf "Hello, world"
```


Enough background for now.


## Task {{% param sectionnumber %}}.4: Cleanup

Remove your created task again:

```bash
{{% param cliToolName %}} delete task test --namespace $USER
```

or us the Tekton CLI, to achieve the same:

```bash
tkn task delete test --namespace $USER
```


## Task {{% param sectionnumber %}}.5: Utilizing parameters

In the next task you will create a new Task  `Task` similar to the previous one and personalize your greeting with your name.

As we've learned in [lab 1](../../02_introduction/02_introduction/), parameters can be added in the `spec.params` map like the following:

```yaml
  params:
  - default: Chuck Norris
    name: name
    type: string
```

and again referenced in the step with `$(params.name)`.

Create a new file with the name `lab03/test-task-param.yaml`.

We add a parameter in the task's `spec.params` map to accept a parameter of type `string` with the name `name`. The added parameter is used in the step to print "Hello, $NAME" to the console!

```yaml
apiVersion: tekton.dev/v1beta1
kind: Task
metadata:
  name: test-param
spec:
  params:
  - default: Chuck Norris
    name: name
    type: string
  steps:
  - image: bash:latest
    name: echo
    resources: {}
    script: |
      #!/usr/bin/env bash
      printf "Hello, %s" "$(params.name)"
```

Again create the Task:

```bash
{{% param cliToolName %}} apply -f lab03/test-task-param.yaml --namespace $USER
```

And run it, if you want you can overwrite the default value with your value:

```bash
tkn task start test-param --namespace $USER
```

Check the logs, whether the correct name was used

{{% alert title="Note" color="info" %}}
The previous command output contains the command to check the logs.
Otherwise you can find the taskrun ID by running:
```
tkn taskrun list --namespace $USER
```
{{% /alert %}}


```bash
tkn taskrun logs <taskrun> -f --namespace $USER
```

Consult the `tkn task start` help, to find out how you could pass a parameter directly to the CLI.

```bash
tkn task start --help
```

Start the task again and say `Hello, acend`

```bash
tkn task start test-param -p name=acend --namespace $USER
```

Check the logs for verification.


{{% alert title="Note" color="primary" %}}Instead of passing the explicit `taskrun` to the `logs` command, just leave the taskrun out, which allows you to choose the taskrun with your arrow keys

```bash
tkn taskrun logs -f --namespace $USER
```
```bash
? Select taskrun:  [Use arrows to move, type to filter]
> test-pipeline-run-rd7np-inline started 7 minutes ago
  test-pipeline-run-rd7np-testref started 7 minutes ago
  test-pipeline-run-xj7xv-inline started 9 minutes ago
  test-pipeline-run-xj7xv-testref started 9 minutes ago
  test-param-run-bblbh started 21 minutes ago
```

{{% /alert %}}


## Task {{% param sectionnumber %}}.6: Pipeline

Tekton is all about pipelines, now let us create a pipeline from our first task created! The `Pipeline` custom resource of the Tekton API is pretty straight forward.

The `Pipeline` resource has a list of tasks defined in the `spec.tasks` section. We can either create `Tasks` from scratch in the Pipeline resource itself as `taskSpec` elements or reference them as a `taskRef`.

We now create a pipeline running your `test-param` task created from before. We define the task both in the pipeline itself and reference it as a task reference:

```yaml
  spec:
    tasks:
    - name: inline
      taskSpec:
        # TASK SECTION
    - name: testref
      taskRef:
        name: test-param
```

Create a new file with the name `lab03/first-pipeline.yaml` and the following content:


```yaml
apiVersion: tekton.dev/v1beta1
kind: Pipeline
metadata:
  name: test-pipeline
spec:
  tasks:
    - name: inline
      taskSpec:
        params:
        - default: Chuck Norris (inline)
          name: name
          type: string
        steps:
        - image: bash:latest
          name: echo
          resources: {}
          script: |
            #!/usr/bin/env bash
            printf "Hello, %s" "$(params.name)"
    - name: testref
      taskRef:
        name: test-param
```

Let's now create the pipeline and apply it to the cluster:

```bash
{{% param cliToolName %}} apply -f lab03/first-pipeline.yaml --namespace $USER
```

Use the following command to verify, whether the pipeline was created:
```bash
tkn pipeline list --namespace $USER
```

Similar to the `TaskRun` creation we can start pipelines with the `tkn` cli:

```bash
tkn pipeline start test-pipeline --namespace $USER 
```

Start your pipeline and verify the output. Copy the command from the pipeline start command output, which looks similar to:

```bash
PipelineRun started: <pipelinerun>

In order to track the PipelineRun progress run:
tkn pipelinerun logs <pipelinerun> -f -n <username>
```

The logoutput should then look similar to:

```bash
[inline : echo] Hello, Chuck Norris (inline)

[testref : echo] Hello, Chuck Norris
```


## Task {{% param sectionnumber %}}.7: Parameterize the pipeline

We have seen how we can use parameters in the task's `spec.params` section. In the `Pipeline` resource the parameters can be applied exactly in the same way. Let's define the desired parameters in the pipeline's `spec.params` section.

Alter your pipeline to accept parameters to override the task's parameter `name`.

```yaml
apiVersion: tekton.dev/v1beta1
kind: Pipeline
metadata:
  name: test-pipeline
spec:
  params:
    - name: name
      description: The name to be greeted as
      default: Chuck Norris (inline)
  tasks:
    - name: inline
      params:
      - name: name
        value: $(params.name)
      taskSpec:
        params:
        - name: name
          type: string
        steps:
        - image: bash:latest
          name: echo
          resources: {}
          script: |
            #!/usr/bin/env bash
            printf "Hello, %s" "$(params.name)"
    - name: testref
      taskRef:
        name: test-param
      params:
      - name: name
        value: $(params.name)
```

Apply the changes:

```bash
{{% param cliToolName %}} apply -f lab03/first-pipeline.yaml --namespace $USER
```


Run the pipeline and see if your parameters apply to your results printed out to the console!

```bash
tkn pipeline start test-pipeline --namespace $USER

tkn pipelinerun logs $pipelinerun -f --namespace $USER 
```

Similar to the `task start` command, you can directly pass the parameters using the `-p` option: `tkn pipeline start test-pipeline -p name=Pipelineparam --namespace $USER` or use the option `--use-param-defaults` to use the default values.


## Task {{% param sectionnumber %}}.8: Cleanup

Clean up all `Task` and `Pipeline` resources created in this chapter:


```bash
{{% param cliToolName %}} delete pipeline test-pipeline --namespace $USER
{{% param cliToolName %}} delete task test-param --namespace $USER
```
