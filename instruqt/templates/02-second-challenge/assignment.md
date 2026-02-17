---
slug: deploy-the-application
id: REPLACE_ME
type: challenge
title: "Deploy the Application"
teaser: "Deploy and verify the application"
notes:
- type: text
  contents: |-
    # Deployment Time! 🚀

    Now that you've explored the environment, it's time to deploy
    the application to your Kubernetes cluster.
tabs:
- title: Terminal
  type: terminal
  hostname: workstation
- title: Code Editor
  type: code
  hostname: workstation
  path: /root/lab
- title: App UI
  type: service
  hostname: workstation
  port: 8080
difficulty: basic
timelimit: 900
---

# Deploy the Application

In this challenge, you'll deploy the application to your cluster.

## Step 1: Review the manifest

In the **Code Editor** tab, open `deploy.yaml` and review the Kubernetes resources.

## Step 2: Apply the manifest

In the **Terminal** tab, run:

```bash
kubectl apply -f /root/lab/deploy.yaml
```

## Step 3: Wait for the deployment

```bash
kubectl rollout status deployment/my-app --timeout=120s
```

## Step 4: Verify

Check that the pod is running:

```bash
kubectl get pods
```

You should see `my-app` pods in `Running` state.

Switch to the **App UI** tab to see the running application!

Click **Check** when you're done.
