---
title: "Labs"
weight: 2
menu:
  main:
    weight: 2
---


[Tekton](https://tekton.dev/)


## Story

DevOps Engineer:

* Tech Swap: CICD Tool X to Jenkins
* Go Sample App Build


## Agenda

* Introduction to Tekton
* Simple Pipeline Example
* Integration in OpenShift
* Tekton in Cloud Native World
* Building Docker Images
* CICD Deep Dive
* Complex Pipeline
* Advanced Delivery Principles
* Harmony GitOps / CICD Principles
* Supply Chain


## Idea Chapters

* Tekton Introduction (Presentation)
  * CICD Intro
  * Tekton Basic Resources (Task, Pipelines, ... )
* Sample Tekton Build Go Application (acend: web-go)
  * Fast introduction from Theory to Build Go Application
  * Build, Lint, Build Image
  * Show Resouces in OpenShift GUI
* Integration OpenShift
* Tekton in Cloud native world (Presentation)
* Plain Docker Build
  * Create Docker Image from Nginx (Static Website)
  * Explain examples from first practical chapter
* Presentation CICD (Presentation)
* Lunch Break
* Wider Integration (Git Secret, Trigger) (Java Application)
  * Import private Git Repo (GitEA Private) (Secret Integration)
  * Unit Test Task, Results
  * Artifact Promotion (Build .jar / Build Container)
  * Trigger (Git Repo)
  * Verify Resources / Smoketest (Curl /health)
* Further Delivery Principles
  * Caching
  * Artifact Promotion
  * Secret Management
  * Environment / Build Parameters
  * Workflow (Advanced)
  * Failures and Notifications
  * ClusterTasks / Tasks
  * Security Scan
* Harmony GitOps / CICD (ArgoCD / Helm / Tekton)
* Supply Chain (Tekton Chains) (Presentation)