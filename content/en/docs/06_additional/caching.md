---
title: "6.1 Caching"
weight: 61
sectionnumber: 6.1
---


## {{% param sectionnumber %}}.1: Workspaces

As we already see in the previous labs, Tekton offers the possibility to use *Workspaces* for transferring data between different Tasks.

At it’s base the Workspace is just another Kubernetes resource being shared and mounted to your Pods running the pipeline / tasks. In the definition of the Pipeline we can state all the Workspace resources used and in the definition of each Task we will define to which Workspace the pods have access to.

You can use *Workspaces* for different use cases:

* Pass arbritary data between Tasks
* Use Workspaces as cache between Tasks
* Promote build artifacts between Tasks


## Example {{% param sectionnumber %}}.2: Chache dependencies

//TODO
