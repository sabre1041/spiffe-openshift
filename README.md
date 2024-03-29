# SPIFFE on OpenShift

This repository contains assets that demonstrates the use of SPIFFE/SPIRE on OpenShift including the installation, configurations and use

## OpenShift GitOps / Argo CD

The deployment and configuration of SPIFFE/SPIRE can be managed using [OpenShift GitOps](https://www.redhat.com/en/technologies/cloud-computing/openshift/gitops).

### Prerequisites

* Deployment of a cluster scoped OpenShift GitOps instance with elevated cluster privileges
* [OpenShift CLI](https://docs.openshift.com/container-platform/4.14/cli_reference/openshift_cli/getting-started-cli.html)/[kubectl](https://kubernetes.io/docs/reference/kubectl/)
* Access to OpenShift Cluster with rights to create

### Deployment

To deploy the SPIRE CRD and SPIRE Helm Chart, execute the following command:

```shell
./scripts/deploy.sh
```

### Validation

Login to Argo CD and confirm both Applications have synchronized successfully and that the `spire-system` and `spire-server` projects have been created and that all pods are active.

## RHTAS Demo Deployment

To both verify and demonstrate the capabilities provided by the integration between SPIFFE/SPIRE deployment and Red Hat Trusted Artifact Signer (RHTAS), an example workload can be deployed to act as an environment to utilize tooling related to the [sigstore project](https://www.sigstore.dev).

### Prerequisites

The deployment of SPIFFE/SPIRE as documented in the prior section must be completed beforehand as well as the deployment of RHTAS with SPIFFE/SPIRE support.

### Deployment

Execute the following command which will deploy an Argo CD Application which will create a new namespace `spiffe-demo` and a `Deployment` that is configured with the necessary development tooling included and configured with RHTAS support:

```shell
./scripts/deploy-spiffe-deployment-demo.sh
```

### Usage

To be able to demonstrate leverage the tooling that was just deployed, obtain a remote session in the Deployment:

```shell
oc rsh -n spiffe-demo deployment/spiffe-demo
```

All of the RHTAS binary artifacts including common development tooling including `git` and `helm` are included and the environment has been initialized, so it is ready for immediate use.

## OpenShift Pipelines / Tekton Chains

Automation is available to facilitate the deployment and integration with OpenShift Pipelines and [Tekton Chains](https://docs.openshift.com/pipelines/1.13/secure/using-tekton-chains-for-openshift-pipelines-supply-chain-security.html).

### Prerequisites

The deployment of SPIFFE/SPIRE as documented in the prior section must be completed beforehand.

In addition, to execute the demonstration as described in the Validation section, a container registry must be available as a target for the container build.

### Deployment

A script is available to trigger the creation of an Argo CD `Application` to deploy OpenShift Pipelines with Tekton Chains integration.

Execute the following script to deploy the integration using the following command:

```shell
./script/deploy-openshift-pipelines.sh
```

### Validation

Once Tekton Chains has been integrated a sample set of assets are available to verify the integration between SPIFFE/SPIRE and OpenShift Pipelines/Tekton Chains.

A sample demonstration is in the [pipelines/demo](pipelines/demo) directory which performs a simple container build and generation of various Software Bill of Materials (SBOM using [syft](https://github.com/anchore/syft)).

Execute the following command to create the demo assets:

```script
kubectl apply -f pipelines/demo
```

A Tekton `PipelineRun` manifest is located in the [pipelines/demo/pipeline](pipelines/demo/pipeline) directory to demonstrate the execution of the pipeline. This resource must be updated to align with your environment. The [yq](https://mikefarah.gitbook.io/yq) tool can be used to update this resource.

Execute the following updating the content based on your environment:


NOTE: The demo set of assets assume the git and container sources and destinations do not have any authentication enabled. Consult the [Tekton Documentation](https://tekton.dev/docs/pipelines/auth/) for more information on how to add those assets.


```shell
OPENSHIFT_APPS_DOMAIN=$(kubectl get cm -n openshift-config-managed  console-public -o go-template="{{ .data.consoleURL }}" | sed 's@https://@@; s/^[^.]*\.//')

# Set Destination Registry. Replace Value accordingly
yq '.spec.params.2.value = "<IMAGE_REGISTRY>/<NAMESPACE>/pipelines-vote-api"' -i pipelines/demo/pipelinerun/pipelinerun.yaml
yq ".spec.params.3.value = \"https://fulcio.${OPENSHIFT_APPS_DOMAIN}\"" -i pipelines/demo/pipelinerun/pipelinerun.yaml
yq ".spec.params.4.value = \"https://rekor.${OPENSHIFT_APPS_DOMAIN}\"" -i pipelines/demo/pipelinerun/pipelinerun.yaml
yq ".spec.params.5.value = \"https://oidc-discovery.${OPENSHIFT_APPS_DOMAIN}\"" -i pipelines/demo/pipelinerun/pipelinerun.yaml
```

Create the `PipelineRun`

```shell
kube create -f pipelines/demo/pipelinerun/pipelinerun.yaml
```

Monitor the state of the pipeline

```shell
kubectl get pipelines -n demo
```

Once complete, confirm the `TaskRuns` in the `demo` namespace have the following annotations confirming they have been successfully signed:

* `chains.tekton.dev/signed`
* `chains.tekton.dev/transparency`

The certificate that was used to sign the `TaskRun` can be found by running the following command:

```shell
curl -Lk $(oc get taskrun -n demo $(oc get pipelinerun -n demo -o jsonpath='{ .items[*].status.childReferences[0].name }') -o jsonpath='{ .metadata.annotations.chains\.tekton\.dev/transparency }') | jq -r 'to_entries|.[0].value.body' |  base64 -d | jq -r '.spec.publicKey' | base64 -d | openssl x509 -text -noout
```

Finally, use Skopeo to confirm a signature has been generated and stored for the generated container image:

```shell
skopeo list-tags docker://<IMAGE_REGISTRY>/<NAMESPACE>/pipelines-vote-api
```

A valid signature will have a `.sig` extension in the list of tags
