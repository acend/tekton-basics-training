---
title: "1. Getting started"
weight: 1
sectionnumber: 1
---


## Task {{% param sectionnumber %}}.1: Web IDE

The first thing we're going to do is to explore our lab environment and get in touch with the different components.

The namespace with the name corresponding to your username is going to be used for all the hands-on labs. And you will be using the `{{% param cliToolName %}} tool` or the OpenShift webconsole.

{{% alert title="Note" color="primary" %}}You can also use your local installation of the cli tools. Make sure you completed [the setup](../../setup/) before you continue with this lab.{{% /alert %}}

{{% alert title="Note" color="primary" %}}The URL and Credentials to the Web IDE will provided by the teacher. Use Chrome for the best experience.{{% /alert %}}


Once you're successfully logged into the web IDE open a new Terminal by hitting `CTRL + SHIFT + ¨` or clicking the Menu button --> Terminal --> new Terminal and check the installed {{% param cliToolName %}}version by executing the following command:

```bash
{{% param cliToolName %}} version
```

The Web IDE Pod consists of the following tools:

* oc
* kubectl
* kustomize
* helm
* kubectx
* kubens
* tekton cli
* odo

The files in the home directory under `/home/project` are stored in a persistence volume, so please make sure to store all your persistence data in this directory.


### Task {{% param sectionnumber %}}.1.1: Local Workspace Directory

During the lab, you’ll be using local files (eg. YAML resources) which will be applied in your lab project.

Create a new folder for your `<workspace>` in your Web IDE  (for example `tekton-training` under `/home/project/tekton-training`). Either you can create it with `right-mouse-click -> New Folder` or in the Web IDE terminal

```bash
mkdir tekton-training && cd tekton-training
```


### Task {{% param sectionnumber %}}.1.2: Login on Tekton using tkn CLI

You can access Tekton via Web UI (URL and Credentials are provided by your teacher) or using the CLI. The Tekton CLI Tool is already installed on the web IDE.

```bash
// TODO: Update
```
{{% onlyWhen openshift %}}


### Task {{% param sectionnumber %}}.1.3: Lab Setup


Most of the labs will be done inside the {{% param distroName %}} project with your username. Verify that your oc tool is configured to point to the right project:


```s
oc project
```


```
Using project "<username>" on server "https://<theClusterAPIURL>".
```

The returned project name should correspond to your username.
{{% /onlyWhen  %}}


## Task {{% param sectionnumber %}}.2: Tekton CLI

The [Tekton CLI](https://tekton.dev/docs/cli/#installation) is a powerful tool to manage Tekton resources. It's a self contained binary written in Go and available for Linux, Mac OS and Windows. Thanks to the fact that the CLI is implemented in Go, it can be easily integrated into scripts and build servers for automation purposes.


### Task {{% param sectionnumber %}}.2: Getting familiar with the CLI

Print out the help of the CLI by typing

```bash
tkn --help
```

You will see a list with the available commands and flags. If you prefer to browse the manual in the browser you'll find it in the [online documentation](https://tekton.dev/docs/cli/).

TODO: Update
