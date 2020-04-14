# skopeo-ubi [![Docker Repository on Quay](https://quay.io/repository/redhat-emea-ssa-team/skopeo-ubi/status "Docker Repository on Quay")](https://quay.io/repository/redhat-emea-ssa-team/skopeo-ubi)

## Why I build from source

because of https://github.com/containers/skopeo/issues/594

## Image sync example 

How to sync an image from docker.io to quay.io:

### 1) Create image repo on quay.io

Quay.io documentation: [https://docs.quay.io/guides/create-repo.html](https://docs.quay.io/guides/create-repo.html)

### 2) Create robot account with write permissions to the new image repo

Quay.io documentation: [https://docs.quay.io/glossary/robot-accounts.html](https://docs.quay.io/glossary/robot-accounts.html)

### 3) Create secret with the robot account credentials

```yaml
apiVersion: v1
data:
  .dockerconfigjson: xxxxx
kind: Secret
metadata:
  name: redhat-emea-ssa-team-registry-sync-pull-secret
type: kubernetes.io/dockerconfigjson
```

### 4) Deploy CronJob, don't forget to adjust command and 

```yaml
apiVersion: batch/v1beta1
kind: CronJob
metadata:
  name: registry-image-sync
spec:
  concurrencyPolicy: Allow
  failedJobsHistoryLimit: 1
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - command:
            - /bin/sh
            - -c
            - |
              skopeo copy \
                --authfile=/pushsecret/.dockerconfigjson \
                docker://docker.io/library/registry:2 \
                docker://quay.io/redhat-emea-ssa-team/registry:2
            image: quay.io/redhat-emea-ssa-team/skopeo-ubi:latest
            imagePullPolicy: Always
            name: skopeo-ubi
            resources: {}
            terminationMessagePath: /dev/termination-log
            terminationMessagePolicy: File
            volumeMounts:
            - mountPath: /pushsecret
              name: pushsecret
              readOnly: true
          dnsPolicy: ClusterFirst
          restartPolicy: Never
          schedulerName: default-scheduler
          securityContext: {}
          terminationGracePeriodSeconds: 30
          volumes:
          - name: pushsecret
            secret:
              defaultMode: 420
              secretName: redhat-emea-ssa-team-registry-sync-pull-secret
  schedule: '@weekly'
  successfulJobsHistoryLimit: 3
  suspend: false
```