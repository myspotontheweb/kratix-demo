#!/bin/env bash

k3d cluster create kratix --port "8080:80@loadbalancer" --servers 1 --agents 2

kubectl apply --filename https://github.com/cert-manager/cert-manager/releases/download/v1.15.0/cert-manager.yaml

sleep 60

kubectl apply --filename https://github.com/syntasso/kratix/releases/latest/download/install-all-in-one.yaml
kubectl apply --filename https://github.com/syntasso/kratix/releases/latest/download/config-all-in-one.yaml