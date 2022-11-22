---
title: "6.4 Authentication"
weight: 64
sectionnumber: 6.4
---

## {{% param sectionnumber %}}.1: Authentication concepts


Tekton supports authentication via the Kubernetes first-class Secret types listed below.

| Git                      | Docker                         |
|--------------------------|--------------------------------|
| kubernetes.io/basic-auth | kubernetes.io/basic-auth       |
| kubernetes.io/ssh-auth   | kubernetes.io/dockercfg        |
|                          | kubernetes.io/dockerconfigjson |

A Run gains access to these Secrets through its associated ServiceAccount. Tekton requires that each supported Secret includes a Tekton-specific annotation.

Tekton converts properly annotated Secrets of the supported types and stores them in a Step's container as follows:

* Git: Tekton produces a ~/.gitconfig file or a ~/.ssh directory.
* Docker: Tekton produces a ~/.docker/config.json file.

Each Secret type supports multiple credentials covering multiple domains and establishes specific rules governing credential formatting and merging. Tekton follows those rules when merging credentials of each supported type.

To consume these Secrets, Tekton performs credential initialization within every Pod it instantiates, before executing any Steps in the Run. During credential initialization, Tekton accesses each Secret associated with the Run and aggregates them into a /tekton/creds directory. Tekton then copies or symlinks files from this directory into the user’s $HOME directory.

Understanding credential selection

A Run might require multiple types of authentication. For example, a Run might require access to multiple private Git and Docker repositories. You must properly annotate each Secret to specify the domains for which Tekton can use the credentials that the Secret contains. Tekton ignores all Secrets that are not properly annotated.

A credential annotation key must begin with tekton.dev/git- or tekton.dev/docker- and its value is the URL of the host for which you want Tekton to use that credential. In the following example, Tekton uses a basic-auth (username/password pair) Secret to access Git repositories at github.com and gitlab.com as well as Docker repositories at gcr.io:

```yaml
apiVersion: v1
kind: Secret
metadata:
  annotations:
    tekton.dev/git-0: https://github.com
    tekton.dev/git-1: https://gitlab.com
    tekton.dev/docker-0: https://gcr.io
type: kubernetes.io/basic-auth
stringData:
  username: <cleartext username>
  password: <cleartext password>
```

And in this example, Tekton uses an ssh-auth Secret to access Git repositories at github.com only:

```yaml
apiVersion: v1
kind: Secret
metadata:
  annotations:
    tekton.dev/git-0: github.com
type: kubernetes.io/ssh-auth
stringData:
  ssh-privatekey: <private-key>
  # This is non-standard, but its use is encouraged to make this more secure.
  # Omitting this results in the server's public key being blindly accepted.
```


## Example {{% param sectionnumber %}}.2: How to authenticate to Git with SSH

A common use case is authentication in Git with an private shh key. In this example we are going to create a SSH keypair and configure our Gitea account to allow cloning private repositories with this particular key.

First create a new SSH keypair with following command:

```bash
mkdir ~/.ssh && ssh-keygen -t rsa -C "$USER" -f "$HOME/.ssh/id_rsa" -P "" -q
```

Next create a Kubernetes secret which contains our private shh key and annotate the secret.

```bash
{{% param cliToolName %}} create secret generic git-ssh-key --from-file=ssh-privatekey=$HOME/.ssh/id_rsa --type=kubernetes.io/ssh-auth -n $USER
{{% param cliToolName %}} annotate secrets git-ssh-key tekton.dev/git-0={{% param giteaUrl %}} -n $USER
```

Afterwards open Gitea in your browser and add your public key to your personal account. For this, copy the public key which we created before:

Display and copy the public key with following command:

```bash
cat "$HOME/.ssh/id_rsa.pub"
```

Open Gitea (https://{{% param giteaUrl %}}) in your browser, log in with your credentials, then click on your profile in the top right corner and navigate to `Settings` and click on `SHH-/PGP Keys` in the menu bar.
Now add a new key with `Add Key`. Set a name for the key and paste your public key inside the form and click `Add key`.

![Add SSH Key in Gitea](../ssh.gif)

Now your Gitea account is configured to work with your new created SSH key.
