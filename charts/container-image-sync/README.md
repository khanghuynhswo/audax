# Container Image Sync

> A short description of your project goes here. Keep it concise and informative.

## Table of Contents

1. [Overview](#overview)
2. [Highlights](#highlights)
3. [Installation](#installation)

## Overview

Container Image Sync is an utility that can sync the docker images between registry based on the provided inputs such as modules-definition.

### Highlights

- **Feature 1**: Doesn't need to be a privileged container.
- **Feature 2**: Uses opensource tools to copy Images.

## Installation

Installing helm chart would run the utility.

### Prerequisites

- ECR Role for IRSA with access to AWS ECR repository
- GHCR PAT to Audax image repository
- Access to Audax repository require whitelisting client source IP

### Steps

1. **provide required helm values**:

    ```bash
    .Values.target.auth.serviceAccount.role - AWS IAM IRSA role with privileges to target AWS ECR
    .Values.target.url - target AWS ECR registry url
    .Values.skopeo.registry - skopeo image registry
    .Values.awscli.registry - awscli image registry
    .Values.source.auth.username - GHCR username if .Values.source.auth.secretRef.create set to true
    .Values.source.auth.token -  GHCR token if .Values.source.auth.secretRef.create set to true
    ```

2. **Create container-image-sync-secret if  .Values.source.auth.secretRef.create set to false by chart

    ```bash

        apiVersion: v1
        kind: Secret
        metadata:
          annotations:
           name: container-image-sync-secret
           namespace: audax-system
          data:
            ecr-user: XXX
            ghcr-token: XXX
            ghcr-user: XXX
         type: Opaque
    ```
3. **Run the utility with the helm installation command**:

    ```bash
    helm upgrade --install container-image-sync . -n <your-namespace> -f <yourfile-path>/modules-definition.yaml
    ```
