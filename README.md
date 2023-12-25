# OpenShift Dev Spaces Integration and SPIFFE

Utilization of SPIFFE to provide workload identities for users and tooling operating within [OpenShift Dev Spaces](https://access.redhat.com/products/red-hat-openshift-dev-spaces/).

## Automated Injection of SPIFFE Resources

To simplify the injection of SPIFFE related resources into Pods, [Kyverno](https://kyverno.io) can be used to dynamically modify resources as they are created.

The following Policies (`ClusterPolicy`) are available:

* `spiffe-inject-pod` - Injects SPIFFE related assets into the first container of a `Pod`
    * Adds the `SPIFFE_ENDPOINT_SOCKET` environment variable
    * Adds a `csi` volume to the Pod and adds a volume mount
* `devspaces-csi-scc-volumes` - Adds `csi` to the list of allowed `volumes` in `SecurityContextConstraints` (see Notes below)
    * Individual SecurityContextContraints must be added to the policy

Apply all of the policies by executing the following command:

```shell
kubectl apply -f kyverno
```

Notes: 

* Individual policies can be applied instead if desired.
* Due to a [Kyverno bug](https://github.com/kyverno/kyverno/issues/9133), enforcement using the `devspaces-csi-scc-volumes` policy applies to only newly created resources. To trigger an update of the resource, execute the following command to temporairly add a new annotation to the target resource.

```shell
kubectl annotate securitycontextconstraint container-build --overwrite kyverno-updated="true" && kubectl annotate securitycontextconstraint container-build kyverno-updated-
```
