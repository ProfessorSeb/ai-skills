---
slug: explore-the-environment
id: REPLACE_ME
type: challenge
title: "Explore the Environment"
teaser: "Get familiar with the lab environment"
notes:
- type: text
  contents: |-
    # Welcome! 👋

    In this lab you'll learn how to work with **Your Product**.

    The environment includes:
    - A Kubernetes cluster
    - Pre-installed CLI tools
    - A code editor

    Let's get started!
tabs:
- title: Terminal
  type: terminal
  hostname: workstation
- title: Code Editor
  type: code
  hostname: workstation
  path: /root/lab
difficulty: basic
timelimit: 600
---

# Explore the Environment

Welcome to the lab! Let's verify everything is set up correctly.

## Step 1: Check the cluster

In the **Terminal** tab, run:

```bash
kubectl cluster-info
```

You should see the cluster control plane URL.

## Step 2: Verify tools

Check that the required tools are available:

```bash
kubectl version --client
helm version --short
```

## Step 3: Explore the lab files

Switch to the **Code Editor** tab to browse the files in `/root/lab`.

Once you've verified everything is working, click **Check** to continue!
