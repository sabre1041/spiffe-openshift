# OpenShift GitOps Integration

Deployment of SPIFFE/SPIRE using OpenShift GitOps

## Overview

The deployment and configuration of SPIFFE/SPIRE can be managed using [OpenShift GitOps](https://www.redhat.com/en/technologies/cloud-computing/openshift/gitops).

## Prerequisites

* Deployment of a cluster scoped OpenShift GitOps instance with elevated cluster privileges
* [OpenShift CLI](https://docs.openshift.com/container-platform/4.14/cli_reference/openshift_cli/getting-started-cli.html)/[kubectl](https://kubernetes.io/docs/reference/kubectl/)
* Access to OpenShift Cluster with rights to create

## Deployment

To deploy the SPIRE CRD and SPIRE Helm Chart, execute the following command:

```shell
./deploy.sh
```

NOTE: Parameters are available to customize the deployment including the namespace to install the Argo CD Application's as well as the OpenShift Apps Subdomain.

## Validation

Login to Argo CD and confirm both Applications have synchronized successfully.
