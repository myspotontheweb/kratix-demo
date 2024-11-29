#!/bin/env bash

CERT_MANAGER_VERSION=v1.16.2
MINIO_VERSION=14.8.5
KRATIX_VERSION=0.0.1

MINIO_USER=admin
MINIO_PASS=$(tr -dc [:alnum:] </dev/urandom | head -c 20)

k3d cluster create kratix --port "8080:80@loadbalancer" --servers 1 --agents 2

#
# Install dependencies
#
helm install cert-manager cert-manager --repo https://charts.jetstack.io --version $CERT_MANAGER_VERSION --namespace cert-manager --create-namespace --set crds.enabled=true
helm install minio oci://registry-1.docker.io/bitnamicharts/minio --version $MINIO_VERSION --namespace minio --create-namespace --set rootUser=$MINIO_USER --set rootPassword=$MINIO_PASS

#
# Install Kratix platform
#
cat <<END > kratix-values.yaml
stateStores: {}
additionalResources:
- apiVersion: v1
  kind: Secret
  metadata:
    name: minio-credentials
    namespace: default
  type: Opaque
  stringData: 
    accesskey: $MINIO_USER
    secretkey: $MINIO_PASS
- apiVersion: batch/v1
  kind: Job
  metadata:
    name: minio-create-bucket
    namespace: default
  spec:
    template:
      spec:
        serviceAccountName: minio-create-bucket
        initContainers:
          - name: wait-for-minio
            image: docker.io/bitnami/kubectl:1.28.6
            command: ["sh", "-c", "kubectl wait --for=condition=Ready --timeout=120s -n kratix-platform-system pod -l run=minio"]
        containers:
          - name: minio-event-configuration
            image: docker.io/minio/mc:RELEASE.2023-06-06T13-48-56Z
            command: ["mc", "mb", "--ignore-existing", "minio/kratix"]
            env:
              - name: MC_ACCESS_KEY
                valueFrom:
                  secretKeyRef:
                    name: minio-credentials
                    key: accesskey
              - name: MC_SECRET_KEY
                valueFrom:
                  secretKeyRef:
                    name: minio-credentials
                    key: ssecretkey
              - name: MC_ENDPOINT
                value: minio.minio.svc.cluster.local
              - name: MC_HOST_minio
                value: "http://\$(MC_ACCESS_KEY):\$(MC_SECRET_KEY)@\$(MC_ENDPOINT)"
        restartPolicy: Never
    backoffLimit: 4
- apiVersion: platform.kratix.io/v1alpha1
  kind: BucketStateStore
  metadata:
    name: default
  spec:
    endpoint: minio.minio.svc.cluster.local
    insecure: true
    bucketName: kratix
    authMethod: accessKey
    secretRef:
      name: minio-credentials
      namespace: default
- apiVersion: platform.kratix.io/v1alpha1
  kind: Destination
  metadata:
    name: worker-1
    labels:
      environment: dev
  spec:
    stateStoreRef:
      name: default
      kind: BucketStateStore
END

helm template kratix kratix --repo https://syntasso.github.io/helm-charts --version v$KRATIX_VERSION --namespace default -f kratix-values.yaml

#
# Install Kratix worker
#
helm template kratix-destination kratix-destination --repo https://syntasso.github.io/helm-charts --version $KRATIX_VERSION --namespace default