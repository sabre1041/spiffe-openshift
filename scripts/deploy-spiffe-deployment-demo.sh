#!/bin/bash

SCRIPT_BASE_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

export OPENSHIFT_APPS_DOMAIN=""
export OPENSHIFT_GITOPS_NAMESPACE="openshift-gitops"

export REPOSITORY="https://github.com/sabre1041/spiffe-openshift.git"
export BRANCH="main"
OC_TOOL="oc"

function display_help {
  echo "./$(basename "$0") [ -a | --apps-domain APPS_DOMAIN ] [ -b | --branch BRANCH ] [ -gn | --gitops-namespace NAMESPACE ] [ -h | --help ] [ -r | --repository REPOSITORY ] [ -t | --tool TOOL ]

Deployment of a Demo Pod to test SPIFFE Integration

Where:
  -a  | --apps-domain       OpenShift 'apps' domain
  -gn | --gitops-namespace  Namespace where Argo CD Applications will be installed within. Defaults to '${OPENSHIFT_GITOPS_NAMESPACE}'
  -h  | --help              Display this help text
  -r  | --repository        Repository containing the source content. Defaults to '${REPOSITORY}'
  -b  | --branch            Branch of the repository containing the source content. Defaults to '${BRANCH}'
  -t  | --tool              Tool for communicating with OpenShift cluster. Defaults to '${OC_TOOL}'

"
}


for i in "${@}"
do
case $i in
    -a | --apps-domain )
    shift
    OPENSHIFT_APPS_DOMAIN="${1}"
    shift
    ;;
    -b | --branch )
    shift
    BRANCH="${1}"
    shift
    ;;
    -gn | --gitops-namespace )
    OPENSHIFT_GITOPS_NAMESPACE="${1}"
    shift
    ;;
    -r | --repository )
    shift
    REPOSITORY="${1}"
    shift
    ;;
    -t | --tool )
    OC_TOOL="${1}"
    shift
    ;;
    -h | --help )
    display_help
    exit 0
    ;;
    -*) echo >&2 "Invalid option: " "${@}"
    exit 1
    ;;
esac
done

# Check if envsubst is installed
command -v envsubst >/dev/null 2>&1 || { echo >&2 "envsubst is required but not installed.  Aborting."; exit 1; }

# Check if oc or compatible is installed
command -v ${OC_TOOL} >/dev/null 2>&1 || { echo >&2 "OpenShift or CLI tool is required but not installed.  Aborting."; exit 1; } 

# Check that User can return Argo CD Applications
${OC_TOOL} get applications.argoproj.io -n ${OPENSHIFT_GITOPS_NAMESPACE} >/dev/null 2>&1

if [[ $? -ne 0 ]]; then
    echo "Failed to query Argo CD Application in the '${OPENSHIFT_GITOPS_NAMESPACE}' namespace."
    exit 1
fi

# Check if OpenShift GitOps is installed
${OC_TOOL} get crd applications.argoproj.io  >/dev/null 2>&1 || { echo >&2 "Argo CD Required CRD's are not available. Ensure OpenShift GitOps has been installed.  Aborting."; exit 1; } 

if [[ -z "${OPENSHIFT_APPS_DOMAIN}" ]]; then
  OPENSHIFT_APPS_DOMAIN=$(${OC_TOOL} get cm -n openshift-config-managed  console-public -o go-template="{{ .data.consoleURL }}" | sed 's@https://@@; s/^[^.]*\.//')
fi

# Install SPIFFE Deployment Demo
envsubst < ${SCRIPT_BASE_DIR}/../gitops/templates/spiffe-deployment-demo.yaml.template | ${OC_TOOL} apply -n ${OPENSHIFT_GITOPS_NAMESPACE} -f-

if [[ $? -ne 0 ]]; then
    echo "Failed to create SPIFFE Deployment Demo Application."
    exit 1
fi

echo "OpenShift SPIFFE Deployment Demo Complete!"
echo
