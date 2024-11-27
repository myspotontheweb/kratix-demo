# kratix-demo

Evaluating Kratix project

# Getting started

## Required software

Install [Arkade](https://arkade.dev/)

```
curl -sLS https://get.arkade.dev | sudo sh
```

Add the following CLIs

```bash
ark get k3d
ark get kubectl
```

## Launch

Running this script will launch and local kubernetes cluster with Kratix installed

```bash
bootstrap/k3d/run.sh
```

## Usage

Following the instructions to deploy the Postgres Promise, followed by creating an Postgres database

* https://docs.kratix.io/main/quick-start#2-provide-postgres-as-a-service-via-a-kratix-promise
