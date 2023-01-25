ocp_insights.sh - OpenShift 4 Insights
===========================================

DESCRIPTION
------------

ocp_insight.sh is a script that collects the latest Insights data from the Insights Operator and parses the data in an easily readable format. This is the same data that connected OpenShift Clusters send to Red Hat.

This script requires access to your OpenShift Cluster and copies the archived insights to your local machine to be extracted prior to parsing the data.

SAMPLE OUTPUT
------------

```bash
$ ocp_insights.sh 

Cluster Version: 4.10.46
Channel: stable-4.11
Previous Version(s): 4.10.46

Cluster Status: Failing
Reason: ClusterOperatorDegraded
Message: Cluster operator dns is degraded

Platform: No Platform Provided
Install Type: UPI
NetworkType: OVNKubernetes
Proxy Configured:
  HTTP: false
  HTTPS: false

NAME                                                      READY    ROLE    CREATED_ON            VERSION           OS
master-0.ocp4.lab.example.com  True     master  2023-01-13T18:09:59Z  v1.23.12+8a6bfe4  Red Hat Enterprise Linux CoreOS 410.84.202212161019-0 (Ootpa)
master-1.ocp4.lab.example.com  True     master  2023-01-13T18:16:28Z  v1.23.12+8a6bfe4  Red Hat Enterprise Linux CoreOS 410.84.202212161019-0 (Ootpa)
master-2.ocp4.lab.example.com  True     master  2023-01-13T18:09:55Z  v1.23.12+8a6bfe4  Red Hat Enterprise Linux CoreOS 410.84.202212161019-0 (Ootpa)
worker-0.ocp4.lab.example.com  True     worker  2023-01-23T02:51:25Z  v1.23.12+8a6bfe4  Red Hat Enterprise Linux CoreOS 410.84.202212161019-0 (Ootpa)
worker-1.ocp4.lab.example.com  Unknown  worker  2023-01-13T18:29:03Z  v1.23.12+8a6bfe4  Red Hat Enterprise Linux CoreOS 410.84.202212161019-0 (Ootpa)
worker-2.ocp4.lab.example.com  True     worker  2023-01-23T02:52:24Z  v1.23.12+8a6bfe4  Red Hat Enterprise Linux CoreOS 410.84.202212161019-0 (Ootpa)

NAME                                      VERSION  AVAILABLE  PROGRESSING  DEGRADED
authentication                            4.10.46  True       False        False
baremetal                                 4.10.46  True       False        False
cloud-controller-manager                  4.10.46  True       False        False
cloud-credential                          4.10.46  True       False        False
cluster-autoscaler                        4.10.46  True       False        False
config-operator                           4.10.46  True       False        False
console                                   4.10.46  True       False        False
csi-snapshot-controller                   4.10.46  True       False        False
dns                                       4.10.46  True       False        True
etcd                                      4.10.46  True       False        False
image-registry                            4.10.46  True       False        True
ingress                                   4.10.46  True       False        False
insights                                  4.10.46  True       False        False
kube-apiserver                            4.10.46  True       False        False
kube-controller-manager                   4.10.46  True       False        False
kube-scheduler                            4.10.46  True       False        False
kube-storage-version-migrator             4.10.46  True       False        False
machine-api                               4.10.46  True       False        False
machine-approver                          4.10.46  True       False        False
machine-config                            4.10.46  True       True         False
marketplace                               4.10.46  True       False        False
monitoring                                4.10.46  False      True         True
network                                   4.10.46  True       False        True
node-tuning                               4.10.46  True       False        False
openshift-apiserver                       4.10.46  True       False        False
openshift-controller-manager              4.10.46  True       False        False
openshift-samples                         4.10.46  True       False        False
operator-lifecycle-manager-catalog        4.10.46  True       False        False
operator-lifecycle-manager                4.10.46  True       False        False
operator-lifecycle-manager-packageserver  4.10.46  True       False        False
service-ca                                4.10.46  True       False        False
storage                                   4.10.46  True       False        False

Installed Operators:

cluster-logging.5.5.6
compliance-operator.v0.1.59
elasticsearch-operator.5.5.5
network-observability-operator.v1.0.0-202301070345
openshift-gitops-operator.v1.7.0
openshift-pipelines-operator-rh.v1.7.3
sandboxed-containers-operator.v1.2.2
sandboxed-containers-operator.v1.3.1
sandboxed-containers-operator.v1.3.2
uma-operator.v2022.11.3-13

NAME           CONFIG                                                   UPDATED  UPDATING  DEGRADED  MACHINECOUNT  READYMACHINECOUNT  UPDATEDMACHINECOUNT  DEGRADEDMACHINECOUNT
master         rendered-master-817a390472145877ad579d1a2db53120         True     False     False     3             3                  3                    0
worker-1-only  rendered-worker-1-only-9e211d859d8b17cb49e0ef6544a0dff2  False    True      True      1             0                  1                    0
worker         rendered-worker-9e211d859d8b17cb49e0ef6544a0dff2         True     False     False     2             2                  2                    0

Pods with errors.
NAMESPACE             POD NAME             REASON
openshift-monitoring  alertmanager-main-0  containers with unready status: [alertmanager]
openshift-monitoring  alertmanager-main-1  containers with unready status: [alertmanager]
openshift-monitoring  node-exporter-9bsd6

Containers with more than 3 restarts.
NAMESPACE                                POD NAME                             CONTAINER        RESTARTS
openshift-monitoring                     alertmanager-main-0                  alertmanager     13
openshift-monitoring                     node-exporter-9bsd6                  kube-rbac-proxy  4
openshift-monitoring                     node-exporter-9bsd6                  node-exporter    4
openshift-sandboxed-containers-operator  controller-manager-57fd5bff5f-jnwg7  manager          9
openshift-user-workload-monitoring       thanos-ruler-user-workload-0         thanos-ruler     4

Last message from each namespace with events:

To see all events for openshift-machine-config-operator run: jq -r . ./extracted-data/insights-2023-01-25-205518/events/openshift-machine-config-operator.json

Namespace: openshift-machine-config-operator
Last Timestamp: 2023-01-25T20:45:38Z
Reason: NodeNotReady
Message: Node is not ready

To see all events for openshift-monitoring run: jq -r . ./extracted-data/insights-2023-01-25-205518/events/openshift-monitoring.json

Namespace: openshift-monitoring
Last Timestamp: 2023-01-25T20:45:59Z
Reason: TaintManagerEviction
Message: Cancelling deletion of Pod openshift-monitoring/telemeter-client-9fc5d455-6fm4b

To see all events for openshift-user-workload-monitoring run: jq -r . ./extracted-data/insights-2023-01-25-205518/events/openshift-user-workload-monitoring.json

Namespace: openshift-user-workload-monitoring
Last Timestamp: 2023-01-25T20:45:59Z
Reason: TaintManagerEviction
Message: Cancelling deletion of Pod openshift-user-workload-monitoring/thanos-ruler-user-workload-0
```

AUTHORS
------

Morgan Peterman

Alan Chan