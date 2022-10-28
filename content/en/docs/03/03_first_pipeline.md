---
title: "3. Your first pipeline"
weight: 3
sectionnumber: 3
---

In the first chapter we familiarized ourselves with the different building blocks of Tekton! Now it is time to get our hands dirty and test them on our cluster.


## Task {{% param sectionnumber %}}.1: Create our first task

We start by implementing a simple first task to echo a good old "hello, world" to our standard out. Create a new file `test-task.yaml` containing a `Task` resource which uses a `bash:latest` image to print "Hello, world" to standard out.

{{% details title="Hint" %}}

Consider looking at the example task in the previous chapter.

{{% /details %}}

{{% details title="Solution" %}}

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

{{% /details %}}

Create the test Task in your namespace:

{{% onlyWhen openshift %}}

```bash
oc -n $USER create -f test-task.yaml
```

{{% /onlyWhen %}}
{{% onlyWhenNot openshift %}}

```bash
kubectl -n $USER create -f test-task.yaml
```

{{% /onlyWhen %}}

Your task resource should be created and ready in your namespace! Verify the creation of the resource:

{{% onlyWhen openshift %}}

```bash
oc -n $USER get tasks
```

{{% /onlyWhen %}}
{{% onlyWhenNot openshift %}}

```bash
kubectl -n $USER get tasks
```

{{% /onlyWhen %}}

After creating and verifying the resource you should be all set to start your first task. To start the task we utilize the `tkn` Tekton CLI:

```bash
tkn task start test
```

Remember the resource `TaskRun` which is an instantiation of a `Task` running on your cluster? You can see your run by listing all `TaskRun` resources with the `tkn` command:

```bash
tkn taskrun list
```

To inspect the logs and verify that our task has done everything we wanted it to we use:

```bash
tkn taskrun logs $TASKRUN -f -n $USER
```

You should see that the tasks greets us, just like we declared it to.

Remove your created task again:

{{% onlyWhen openshift %}}

```bash
oc -n $USER delete task test
```

{{% /onlyWhen %}}
{{% onlyWhenNot openshift %}}

```bash
kubectl -n $USER delete task test
```

{{% /onlyWhen %}}


## Task {{% param sectionnumber %}}.2: Utilizing parameters

In the next task you will alter the test `Task` created before to personalize your greeting with your name.

Add a parameter in the task's `spec.params` map to accept a parameter of type `string` with the name `name`. With the added parameter, alter the step to print "Hello, $NAME" to the console!

{{% details title="Hint" %}}

Parameters can be added in the `spec.params` map like the following:

```yaml
  params:
  - default: Chuck Norris
    name: name
    type: string
```

and again referenced in the step with `$(params.name)`.

{{% /details %}}

{{% details title="Solution" %}}

```yaml

apiVersion: tekton.dev/v1beta1
kind: Task
metadata:
  name: test
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

{{% /details %}}

Run the task again and verify your greeting with your name.


## Task {{% param sectionnumber %}}.3: Pipeline

Tekton is all about pipelines, now let us create a pipeline from our first task created! The `Pipeline` custom resource of the Tekton API is pretty straight forward.

The `Pipeline` resource has an list of tasks defined in the `spec.tasks` section. We can either create `Tasks` from scratch in the Pipeline resource itself as `taskSpec` elements or reference them as a `taskRef`.

Create a pipeline running your test task created from before. Try to define the task in the pipeline itself and reference it as a task reference.


{{% details title="Hint" %}}

Create the task in the pipeline's `spec.tasks` section or reference it:

```yaml
  spec:
    tasks:
    - name: inline
      taskSpec:
        # TASK SECTION
    - name: testref
      taskRef:
        name: test
```

and again referenced in the step with `$(params.name)`.

{{% /details %}}

{{% details title="Solution" %}}

```yaml

apiVersion: tekton.dev/v1beta1
kind: Pipeline
metadata:
  name: test
spec:
  tasks:
    - name: inline
      taskSpec:
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
    - name: testref
      taskRef:
        name: test

```

{{% /details %}}

Similar to the `TaskRun` creation we can start pipelines with the `tkn` cli:

```bash
tkn pipeline start test
```

Start your pipeline and verify the output!


## Task {{% param sectionnumber %}}.4: Parameterize the pipeline

We have seen how we can use parameters in the task's `spec.params` section. In the `Pipeline` resource the parameters can be applied exactly in the same way. Define the desired parameters in the pipeline's `spec.params` section.

Alter your pipeline to accept parameters to override the task's parameter `name`.


{{% details title="Solution" %}}

```yaml
apiVersion: tekton.dev/v1beta1
kind: Pipeline
metadata:
  name: test
spec:
  params:
    - name: name
      description: The name to be greeted as
      default: Chuck Norris
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
        name: test
      params:
      - name: name
        value: $(params.name)
```

{{% /details %}}

Run the pipeline and see if your parameters apply to your results printed out to the console!

```bash
tkn pipeline start test

tkn pipelinerun logs $pipelinerun -f -n $USER
```


## Task {{% param sectionnumber %}}.5: Cleanup

Clean up all `Task` and `Pipeline` resources created in this chapter:

{{% onlyWhen openshift %}}

```bash
oc -n $USER delete pipeline test
oc -n $USER delete task test
```

{{% /onlyWhen %}}
{{% onlyWhenNot openshift %}}

```bash
kubectl -n $USER delete pipeline test
kubectl -n $USER delete task test
```

{{% /onlyWhen %}}
