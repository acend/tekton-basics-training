---
title: "6.7 Tekton chains"
weight: 67
sectionnumber: 6.7
---

## {{% param sectionnumber %}}.1: Tekton Chains

Tekton Chains allows you to manage your supply chain security when using Tekton as your CICD System. It basically observes all TaskRuns and PipelineRuns, takes a snapshot of them, signs them and stores them somewhere. It allows you to cryptographically prove what steps and commands, in what containers were executed, during a specific Task- or PipelineRun.

In addition to that Tekton Chains also supports signing the resulting OCI images.

Read the [documentation](https://tekton.dev/docs/chains/) for additional Information.

We've already created a Keypair, which Tekton Chains uses to sign your TaskRuns and PipelineRuns using the `cosign` tool. This created a secret in the `openshift-pipelines` namespace. And we configured Tekton Chains to store the signatures and payloads as annotations to the corresponding TaksRuns and PipelineRuns.

You might have noticed the Tekton Chains annotations in your TaksRun and PipelineRun Resources, since Tektion Chains was running and signing the whole day.


## Task {{% param sectionnumber %}}.2: TaskRun

Let's again simply create a Task `chains-task.yaml` with the following content:

```yaml
apiVersion: tekton.dev/v1beta1
kind: Task
metadata:
  name: tekton-chains-task
spec:
  steps:
  - image: bash:latest
    name: echo
    resources: {}
    script: |
      #!/usr/bin/env bash
      printf "Hello, Tekton Chains"
```

Create the Task in your namespace:

```bash
{{% param cliToolName %}} --namespace $USER apply -f chains-task.yaml
```

And start it:


```bash
tkn --namespace $USER task start tekton-chains-task
```

After the Task ran successfully we can now check for the Tekton Chains annotations.

We need the TaskRun UID to get the correct annotations, so execute:
```bash
export TASKRUN_UID=$(tkn tr describe --last -o  jsonpath='{.metadata.uid}' --namespace $USER)
```

Then use the following command to safe the signature into a file with the name `signature`:
```bash
tkn tr describe --last -o jsonpath="{.metadata.annotations.chains\.tekton\.dev/signature-taskrun-$TASKRUN_UID}" > signature
```

And do the same for the payload:
```bash
tkn tr describe --last -o jsonpath="{.metadata.annotations.chains\.tekton\.dev/payload-taskrun-$TASKRUN_UID}" | base64 -d > payload
```

Explore the contents of both files


## {{% param sectionnumber %}}.3: Verify Signature

First need to install the cosign tool in your Webshell:

```bash
wget "https://github.com/sigstore/cosign/releases/download/v1.6.0/cosign-linux-amd64"
chmod +x cosign-linux-amd64 
mv cosign-linux-amd64 /usr/local/bin/cosign
```

Then create a file with the name `cosign.pub`, containing the public Key provided by the Teacher.

To verify the signature we can now simply execute the following command, where `signature` and `payload` are the two files containing the signature and payload of your TaksRun.

```bash
cosign verify-blob --key cosign.pub --signature ./signature ./payload
```


## Task {{% param sectionnumber %}}.3: PipelineRun

Similar to TaskRuns explore a PipelineRun and verify whether the annotations are set or not.


## {{% param sectionnumber %}}.4: Read the docs about Signing OCI Images

For simplicity reasons we didn't implement a OCI signing example, for more information please consult the [docs](https://docs.openshift.com/container-platform/4.11/cicd/pipelines/using-tekton-chains-for-openshift-pipelines-supply-chain-security.html#using-tekton-chains-to-sign-and-verify-image-and-provenance_using-tekton-chains-for-openshift-pipelines-supply-chain-security).
