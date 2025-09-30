ocp_insights.py - OpenShift 4 Insights
===========================================

DESCRIPTION
------------

ocp_insights.py is a modern, pythonic script that collects the latest Insights data for a connected OpenShift 4 Cluster and parses the data in an easily readable format.

To use the script you *MUST* be on SupportShell due to the Insights data being stored locally.

## Recent Improvements (v2.0)

This script has been significantly refactored to follow Python best practices:

- **Enhanced Security**: Replaced shell command execution with secure pathlib operations
- **Type Safety**: Added comprehensive type hints for better code reliability
- **Performance**: Optimized memory calculations and file operations
- **Maintainability**: Extracted constants and improved code organization
- **Error Handling**: More specific exception handling for better debugging
- **Python Compatibility**: Compatible with Python 3.9+ using proper typing syntax

REQUIREMENTS
------------
- Python 3.9 or higher
- Access to SupportShell environment
- Required Python modules (all standard library):
  - `argparse`, `json`, `pathlib`, `tarfile`, `uuid`, `datetime`, `typing`

INSTALLATION
------------
* Clone the repository, if on SupportShell this should be in your $HOME directory.
* Copy to a folder in your $PATH (protip: create a symbolic link then you only need to run `git pull` to use the latest version)
* Ensure the script has execute permissions: `chmod +x ocp_insights.py`

USAGE
------------

```bash
ocp_insights.py --help
usage: ocp_insights.py [-h] [--id ID] [--file FILE] [--alerts] [--customer_memory] [--etcd_metrics] [--events] [--list] [--extract]

OpenShift InsightsCluster Report.

options:
  -h, --help         show this help message and exit
  --id ID            ClusterID of a connected cluster used to find all connected Clusters
  --file FILE        Use a specific Insights Archive File; must specify full path.
  --alerts           Prints out Alerts in valid JSON
  --customer_memory  Prints Customer Namespace memory usage.
  --etcd_metrics     Prints etcd metrics for all Insights Archives for the cluster.
  --events           Prints namespace events if they exist.
  --list             List available archives for a specific cluster. Must be used with --id option. Can be combined with --extract.
  --extract          Extract archive for a specific cluster to user's home directory. Must be used with --id option. Can be combined with --list to select which archive to extract.
```

### Archive Selection with --list

The `--list` option allows you to interactively select from all available archives for a specific cluster:

```bash
# List all available archives for a cluster and select one
ocp_insights.py --id <cluster-uuid> --list

# Example output:
Available Archives for Cluster: abc123-def456-ghi789
================================================================================
#   Check-in Time                  File Name
--------------------------------------------------------------------------------
1   Wed Jan 17 02:30:45 PM UTC 2024   20240117143045-insights.tar.gz
2   Tue Jan 16 02:30:45 PM UTC 2024   20240116143045-insights.tar.gz
3   Mon Jan 15 02:30:45 PM UTC 2024   20240115143045-insights.tar.gz
--------------------------------------------------------------------------------
0   Exit

Select an archive to analyze (enter number): 2
```

This feature is useful when you need to:
- Compare data across different time periods
- Analyze historical cluster states
- Investigate issues that occurred at specific times
- Review cluster evolution over time

**Note**: Archives are displayed with the newest first (most recent check-in time at the top).

### Archive Extraction with --extract

The `--extract` option allows you to extract cluster archives to your home directory for offline analysis:

```bash
# Extract the latest archive for a cluster
ocp_insights.py --id <cluster-uuid> --extract

# Extract and analyze in one step - list archives, select one, extract it, and analyze
ocp_insights.py --id <cluster-uuid> --list --extract

# Example output for combined list+extract:
Available Archives for Cluster: abc123-def456-ghi789
================================================================================
#   Check-in Time                  File Name
--------------------------------------------------------------------------------
1   Wed Jan 17 02:30:45 PM UTC 2024   20240117143045-insights.tar.gz
2   Tue Jan 16 02:30:45 PM UTC 2024   20240116143045-insights.tar.gz
3   Mon Jan 15 02:30:45 PM UTC 2024   20240115143045-insights.tar.gz
--------------------------------------------------------------------------------
0   Exit

Select an archive to analyze (enter number): 2

Destination: /home/username/ocp/subdirectory/abc123-def456-ghi789/20240116143045-insights
Archive extraction completed successfully.

Checkin: Tue Jan 16 02:30:45 PM UTC 2024
[... full insights analysis follows ...]
```

#### Extraction Path Structure

Archives are extracted to maintain the original directory structure:
- **Source**: `/ocp/subdirectory/cluster_id/archive.tar.gz`
- **Destination**: `~/ocp/subdirectory/cluster_id/archive_name/`

This feature is useful for:
- **Offline analysis**: Extract archives for analysis without network access
- **Archive preservation**: Keep local copies of important cluster snapshots
- **Comparative analysis**: Extract multiple archives to compare cluster states
- **Backup purposes**: Maintain local copies of cluster insights data

#### Security Features

- **Safe extraction**: Protects against directory traversal attacks (CVE-2007-4559)
- **Path validation**: Ensures extraction stays within the target directory
- **Trusted filtering**: Uses secure tarfile extraction methods

SAMPLE OUTPUT
------------

```bash
$ Checkin: Mon Mar 31 02:09:28 PM UTC 2025

Cluster Version: 4.16.20
Channel: eus-4.16
Previous Versions: 4.16.20, 4.15.37, 4.14.31, 4.13.22, 4.13.22
Platform: BareMetal
Install Type: IPI
Network Type: OVNKubernetes
Proxy Settings:
   HTTP:  False
   HTTPS: False

etcd Encryption: None
Audit Profile: Default

NAME                READY  ROLE                                                 CREATED ON            VERSION          OS                                                     CPU  MEMORY
nyc-acp-n1.nyc.lab  True   control-plane,master,mcp-master-hp,worker,worker-hp  2024-01-06T07:20:55Z  v1.29.9+5865c5b  Red Hat Enterprise Linux CoreOS 416.94.202410292028-0  144  503 GB
nyc-acp-n2.nyc.lab  True   control-plane,master,mcp-master-hp,worker,worker-hp  2024-01-06T07:17:31Z  v1.29.9+5865c5b  Red Hat Enterprise Linux CoreOS 416.94.202410292028-0  144  503 GB
nyc-acp-n3.nyc.lab  True   control-plane,master,mcp-master-hp,worker,worker-hp  2024-01-06T07:41:52Z  v1.29.9+5865c5b  Red Hat Enterprise Linux CoreOS 416.94.202410292028-0  144  503 GB
nyc-acp-n4.nyc.lab  True   worker,worker-hp                                     2024-01-06T08:41:40Z  v1.29.9+5865c5b  Red Hat Enterprise Linux CoreOS 416.94.202410292028-0  144  503 GB

Cluster Operators:

NAME                                      VERSION  AVAILABLE  PROGRESSING  DEGRADED
authentication                            4.16.20  True       False        False
baremetal                                 4.16.20  True       False        False
cloud-controller-manager                  4.16.20  True       False        False
cloud-credential                          4.16.20  True       False        False
cluster-autoscaler                        4.16.20  True       False        False
config-operator                           4.16.20  True       False        False
console                                   4.16.20  True       False        False
control-plane-machine-set                 4.16.20  True       False        False
csi-snapshot-controller                   4.16.20  True       False        False
dns                                       4.16.20  True       False        False
etcd                                      4.16.20  True       False        False
image-registry                            4.16.20  True       False        False
ingress                                   4.16.20  True       False        False
insights                                  4.16.20  True       False        False
kube-apiserver                            4.16.20  True       False        False
kube-controller-manager                   4.16.20  True       False        False
kube-scheduler                            4.16.20  True       False        False
kube-storage-version-migrator             4.16.20  True       False        False
machine-api                               4.16.20  True       False        False
machine-approver                          4.16.20  True       False        False
machine-config                            4.16.20  True       False        False
marketplace                               4.16.20  True       False        False
monitoring                                4.16.20  True       False        False
network                                   4.16.20  True       False        False
node-tuning                               4.16.20  True       False        False
openshift-apiserver                       4.16.20  True       False        False
openshift-controller-manager              4.16.20  True       False        False
openshift-samples                         4.16.20  True       False        False
operator-lifecycle-manager                4.16.20  True       False        False
operator-lifecycle-manager-catalog        4.16.20  True       False        False
operator-lifecycle-manager-packageserver  4.16.20  True       False        False
service-ca                                4.16.20  True       False        False
storage                                   4.16.20  True       False        False

Install Plans:

CSV                                                 NAMESPACE
cluster-logging.v5.8.10                             openshift-logging
cluster-logging.v5.8.11                             openshift-logging
cluster-logging.v5.8.12                             openshift-logging
cluster-logging.v5.8.13                             openshift-logging
cluster-logging.v5.8.9                              openshift-logging
clusterkubedescheduleroperator.4.13.0-202409240037  openshift-kube-descheduler-operator
clusterkubedescheduleroperator.4.13.0-202410190100  openshift-kube-descheduler-operator
clusterkubedescheduleroperator.4.14.0-202410182001  openshift-kube-descheduler-operator
clusterkubedescheduleroperator.v5.0.1               openshift-kube-descheduler-operator
clusterkubedescheduleroperator.v5.0.2               openshift-kube-descheduler-operator
compliance-operator.v1.5.0                          openshift-compliance
compliance-operator.v1.5.1                          openshift-compliance
compliance-operator.v1.6.0                          openshift-compliance
compliance-operator.v1.6.1                          openshift-compliance
compliance-operator.v1.6.2                          openshift-compliance
dell-csm-operator.v1.8.0                            openshift-operators
jaeger-operator.v1.57.0-10                          openshift-distributed-tracing
jaeger-operator.v1.57.0-10-0.1730817420.p           openshift-distributed-tracing
jaeger-operator.v1.62.0-1                           openshift-distributed-tracing
jaeger-operator.v1.62.0-2                           openshift-distributed-tracing
jaeger-operator.v1.65.0-1                           openshift-distributed-tracing
kiali-operator.v1.89.9                              openshift-operators
kiali-operator.v2.4.3                               openshift-operators
kubernetes-nmstate-operator.4.16.0-202501211505     openshift-nmstate
kubernetes-nmstate-operator.4.16.0-202501281135     openshift-nmstate
kubernetes-nmstate-operator.4.16.0-202502111405     openshift-nmstate
kubernetes-nmstate-operator.4.16.0-202502190034     openshift-nmstate
kubernetes-nmstate-operator.4.16.0-202502250034     openshift-nmstate
kubevirt-hyperconverged-operator.v4.16.2            openshift-cnv
kubevirt-hyperconverged-operator.v4.16.3            openshift-cnv
kubevirt-hyperconverged-operator.v4.16.4            openshift-cnv
kubevirt-hyperconverged-operator.v4.16.5            openshift-cnv
kubevirt-hyperconverged-operator.v4.16.6            openshift-cnv
mtv-operator.v2.7.10                                openshift-mtv
mtv-operator.v2.7.11                                openshift-mtv
mtv-operator.v2.7.7                                 openshift-mtv
mtv-operator.v2.7.8                                 openshift-mtv
mtv-operator.v2.7.9                                 openshift-mtv
nfd.4.16.0-202412042304                             openshift-nfd
nfd.4.16.0-202412170135                             openshift-nfd
nfd.4.16.0-202501271512                             openshift-nfd
nfd.4.16.0-202502111405                             openshift-nfd
nfd.4.16.0-202502250034                             openshift-nfd
openshift-gitops-operator.v1.14.1                   openshift-gitops-operator
openshift-gitops-operator.v1.14.2                   openshift-gitops-operator
openshift-gitops-operator.v1.15.0                   openshift-gitops-operator
openshift-gitops-operator.v1.15.0-0.1738074324.p    openshift-gitops-operator
openshift-gitops-operator.v1.15.1                   openshift-gitops-operator
quay-operator.v3.11.9                               openshift-operators

Installed OLM Operators:

NAME                               DISPLAY NAME                                    VERSION                NAMESPACE
cluster-aas-operator                                                                                      openshift-operators
cluster-kube-descheduler-operator  Kube Descheduler Operator                       v5.0.2                 openshift-kube-descheduler-op
cluster-kube-descheduler-operator                                                                         virt-demo
cluster-logging                    Red Hat OpenShift Logging                       v5.8.12                openshift-logging
compliance-operator                Compliance Operator                             v1.6.2                 openshift-compliance
crunchy-postgres-operator                                                                                 gdit-poc
dell-csm-operator                  Dell Container Storage Modules                  v1.7.0                 openshift-operators
dell-csm-operator-certified                                                                               openshift-operators
devworkspace-operator              DevWorkspace Operator                           v0.31.2                openshift-operators
f5-bigip-ctlr-operator                                                                                    i2c
gpu-operator-certified             NVIDIA GPU Operator                             v23.9.2                nvidia-gpu-operator
istio-workspace-operator           Istio Workspace                                 v0.5.3                 openshift-operators
jaeger-product                     Red Hat OpenShift distributed tracing platform  v1.65.0-1              openshift-distributed-tracing
kiali-ossm                         Kiali Operator                                  v1.89.8                openshift-operators
kubernetes-nmstate-operator        Kubernetes NMState Operator                     4.16.0-202502250034    openshift-nmstate
kubevirt-hyperconverged            OpenShift Virtualization                        v4.16.6                openshift-cnv
metallb-operator                   MetalLB Operator                                v4.16.0-202502260004   metallb-system
minio-aistor-operator                                                                                     openshift-operators
mtv-operator                       Migration Toolkit for Virtualization Operator   v2.7.11                openshift-mtv
mtv-operator                                                                                              project1
mtv-operator                                                                                              project2
nfd                                Node Feature Discovery Operator                 4.16.0-202502250034    openshift-nfd
openshift-cert-manager-operator    cert-manager Operator for Red Hat OpenShift     v1.15.1                cert-manager-operator
openshift-gitops-operator          Red Hat OpenShift GitOps                        v1.15.1                openshift-gitops-operator
openshift-pipelines-operator-rh                                                                           openshift-operators
quay-operator                      Red Hat Quay                                    v3.11.7                openshift-operators
redhat-oadp-operator               OADP Operator                                   v1.3.0                 velero-ppdm
rhods-operator                     Red Hat OpenShift AI                            2.16.2                 redhat-ods-operator
servicemeshoperator                Red Hat OpenShift Service Mesh                  v2.6.4                 openshift-operators
web-terminal                       Web Terminal                                    v1.8.0-0.1730804434.p  openshift-operators

MachineConfigPools:

NAME    CONFIG                                            UPDATED  UPDATING  DEGRADED  MACHINECOUNT  READYMACHINECOUNT  UPDATEDMACHINECOUNT  DEGRADEDMACHINECOUNT
master  rendered-master-f2c702fa0d84f3d34584dc263cbe248b  True     False     False     3             3                  3                    0
worker  rendered-worker-2afc5205f99e7b4b31fe7617a1bcd26e  True     False     False     1             1                  1                    0

MachineSets:

NAME                   DESIRED  CURRENT  READY  AVAILABLE
acp-rh-pld9l-worker-0  0        0        0      0

StorageClasses:

NAME                           PROVISIONER                   RECLAIM POLICY  BINDING MODE          VOLUME EXPANSION
mcp-pf-fs-storageclass-mw      csi-vxflexos.dellemc.com      Delete          Immediate             True
mcp-pf-fs-storageclass-custom  csi-vxflexos.dellemc.com      Delete          WaitForFirstConsumer  True
mcp-pf-fs-storageclass         csi-vxflexos.dellemc.com      Delete          WaitForFirstConsumer  True
manual-local                   kubernetes.io/no-provisioner  Retain          WaitForFirstConsumer  None
manual                         kubernetes.io/no-provisioner  Delete          WaitForFirstConsumer  None

Cluster Namespace Memory Usage:

NAMESPACE                                         MEMORY
default                                           1.05 GB
openshift-apiserver                               5.45 GB
openshift-apiserver-operator                      401.30 MB
openshift-authentication                          395.69 MB
openshift-authentication-operator                 232.02 MB
openshift-cloud-controller-manager-operator       159.24 MB
openshift-cloud-credential-operator               187.40 MB
openshift-cluster-machine-approver                218.27 MB
openshift-cluster-node-tuning-operator            811.06 MB
openshift-cluster-samples-operator                126.13 MB
openshift-cluster-storage-operator                368.02 MB
openshift-cluster-version                         211.96 MB
openshift-cnv                                     6.36 GB
openshift-compliance                              139.45 MB
openshift-config-operator                         102.31 MB
openshift-console                                 3.77 GB
openshift-console-operator                        207.23 MB
openshift-controller-manager                      704.92 MB
openshift-controller-manager-operator             298.38 MB
openshift-distributed-tracing                     132.96 MB
openshift-dns                                     656.50 MB
openshift-dns-operator                            133.78 MB
openshift-etcd                                    7.46 GB
openshift-etcd-operator                           241.06 MB
openshift-gitops                                  476.10 MB
openshift-gitops-operator                         332.41 MB
openshift-image-registry                          6.97 GB
openshift-ingress                                 326.74 MB
openshift-ingress-canary                          338.58 MB
openshift-ingress-operator                        281.84 MB
openshift-insights                                342.69 MB
openshift-kni-infra                               3.04 GB
openshift-kube-apiserver                          22.53 GB
openshift-kube-apiserver-operator                 508.05 MB
openshift-kube-controller-manager                 2.14 GB
openshift-kube-controller-manager-operator        220.67 MB
openshift-kube-descheduler-operator               172.50 MB
openshift-kube-scheduler                          1.10 GB
openshift-kube-scheduler-operator                 166.77 MB
openshift-kube-storage-version-migrator           66.87 MB
openshift-kube-storage-version-migrator-operator  58.18 MB
openshift-logging                                 116.13 GB
openshift-machine-api                             1.41 GB
openshift-machine-config-operator                 3.53 GB
openshift-marketplace                             587.75 MB
openshift-monitoring                              104.56 GB
openshift-mtv                                     17.25 GB
openshift-multus                                  2.82 GB
openshift-network-diagnostics                     305.83 MB
openshift-network-node-identity                   411.00 MB
openshift-network-operator                        952.10 MB
openshift-nfd                                     952.57 MB
openshift-nmstate                                 597.50 MB
openshift-oauth-apiserver                         1.80 GB
openshift-operator-lifecycle-manager              2.01 GB
openshift-operators                               3.43 GB
openshift-ovn-kubernetes                          2.77 GB
openshift-pipelines                               1.26 GB
openshift-route-controller-manager                303.56 MB
openshift-service-ca                              337.87 MB
openshift-service-ca-operator                     95.27 MB
openshift-user-workload-monitoring                2.39 GB
openshift-virtualization-os-images                63.39 MB

Total Cluster Namespace Memory Usage: 332.54 GB

Failing Pods:

NAMESPACE                        POD NAME                                                      REASON
openshift-workload-availability  self-node-remediation-ds-vnkkb                                ContainersNotReady
openshift-workload-availability  self-node-remediation-ds-bf496                                ContainersNotReady
openshift-workload-availability  self-node-remediation-ds-6v6h7                                ContainersNotReady
openshift-operators              istio-workspace-operator-controller-manager-777ff698bf-nv7g5  ContainersNotReady

Containers with more than 3 restarts:

NAMESPACE                          POD NAME                                                       CONTAINER NAME                               RESTARTS
openshift-cnv                      virt-template-validator-5bdbf78f97-rvlnm                       webhook                                      7
openshift-cnv                      virt-operator-75c9bbc5dd-pss6s                                 virt-operator                                7
openshift-cnv                      virt-operator-75c9bbc5dd-cf8d9                                 virt-operator                                73
openshift-cnv                      virt-controller-579b97b48c-w9tkd                               virt-controller                              39
openshift-cnv                      virt-controller-579b97b48c-7bzvf                               virt-controller                              46
openshift-cnv                      ssp-operator-599476cc59-wjbxp                                  manager                                      21
openshift-cnv                      mtq-operator-5d7644c54-lsw4c                                   mtq-operator                                 26
openshift-cnv                      hostpath-provisioner-operator-6fc568f77d-lwh26                 hostpath-provisioner-operator                31
openshift-cnv                      hco-operator-6b8cc448ff-f8p94                                  hyperconverged-cluster-operator              20
openshift-cnv                      cdi-operator-674bc5b4b5-9dq8j                                  cdi-operator                                 132
openshift-cnv                      cdi-deployment-654fd57646-sqvcj                                cdi-deployment                               27
openshift-cnv                      aaq-operator-58b946795b-7nbx4                                  aaq-operator                                 28
openshift-compliance               compliance-operator-58fd4d4ddc-nljg4                           compliance-operator                          10
openshift-etcd                     etcd-nyc-acp-n2.nyc.lab                                        etcd                                         50
openshift-etcd                     etcd-nyc-acp-n2.nyc.lab                                        etcd-metrics                                 26
openshift-etcd                     etcd-nyc-acp-n2.nyc.lab                                        etcd-readyz                                  26
openshift-etcd                     etcd-nyc-acp-n2.nyc.lab                                        etcdctl                                      28
openshift-gitops-operator          openshift-gitops-operator-controller-manager-5f9b7bf8f6-mjm9k  manager                                      30
openshift-kube-controller-manager  kube-controller-manager-nyc-acp-n3.nyc.lab                     cluster-policy-controller                    529
openshift-kube-controller-manager  kube-controller-manager-nyc-acp-n3.nyc.lab                     kube-controller-manager                      527
openshift-kube-controller-manager  kube-controller-manager-nyc-acp-n3.nyc.lab                     kube-controller-manager-cert-syncer          8
openshift-kube-controller-manager  kube-controller-manager-nyc-acp-n3.nyc.lab                     kube-controller-manager-recovery-controller  10
openshift-kube-controller-manager  kube-controller-manager-nyc-acp-n2.nyc.lab                     cluster-policy-controller                    69
openshift-kube-controller-manager  kube-controller-manager-nyc-acp-n2.nyc.lab                     kube-controller-manager                      28
openshift-kube-controller-manager  kube-controller-manager-nyc-acp-n2.nyc.lab                     kube-controller-manager-cert-syncer          16
openshift-kube-controller-manager  kube-controller-manager-nyc-acp-n2.nyc.lab                     kube-controller-manager-recovery-controller  13
openshift-kube-controller-manager  kube-controller-manager-nyc-acp-n1.nyc.lab                     cluster-policy-controller                    18
openshift-kube-controller-manager  kube-controller-manager-nyc-acp-n1.nyc.lab                     kube-controller-manager                      27
openshift-kube-controller-manager  kube-controller-manager-nyc-acp-n1.nyc.lab                     kube-controller-manager-cert-syncer          8
openshift-kube-controller-manager  kube-controller-manager-nyc-acp-n1.nyc.lab                     kube-controller-manager-recovery-controller  9
openshift-kube-scheduler           openshift-kube-scheduler-nyc-acp-n2.nyc.lab                    kube-scheduler                               13
openshift-kube-scheduler           openshift-kube-scheduler-nyc-acp-n2.nyc.lab                    kube-scheduler-cert-syncer                   18
openshift-kube-scheduler           openshift-kube-scheduler-nyc-acp-n2.nyc.lab                    kube-scheduler-recovery-controller           10
openshift-mtv                      forklift-operator-5c48c9857d-vmgd2                             forklift-operator                            29
openshift-multus                   multus-v6d67                                                   kube-multus                                  36
openshift-network-node-identity    network-node-identity-wb892                                    approver                                     30
openshift-network-node-identity    network-node-identity-wb892                                    webhook                                      21
openshift-nfd                      nfd-worker-srwks                                               nfd-worker                                   597
openshift-nfd                      nfd-worker-p7t65                                               nfd-worker                                   735
openshift-nfd                      nfd-worker-jqc2f                                               nfd-worker                                   747
openshift-nfd                      nfd-worker-2tvpk                                               nfd-worker                                   78
openshift-nfd                      nfd-topology-updater-62sw4                                     nfd-topology-updater                         33
openshift-nfd                      nfd-controller-manager-6c584fbfdf-d5gdm                        manager                                      21
openshift-nmstate                  nmstate-handler-vjss9                                          nmstate-handler                              5
openshift-nmstate                  nmstate-handler-5sllr                                          nmstate-handler                              9
openshift-operators                istio-workspace-operator-controller-manager-777ff698bf-nv7g5   istio-workspace                              4918
openshift-operators                istio-operator-9c76c78bd-lplvz                                 istio-operator                               27
openshift-operators                devworkspace-controller-manager-64899794c9-wx46n               devworkspace-controller                      138
openshift-operators                devworkspace-controller-manager-64899794c9-wx46n               kube-rbac-proxy                              9
openshift-operators                dell-csm-operator-controller-manager-8555bcf57f-bcgr4          manager                                      7

ALERT NAME                          STATE   START TIME
PodDisruptionBudgetLimit            ACTIVE  2025-03-17T20:30:28.279Z
TargetDown                          ACTIVE  2025-03-17T20:30:04.000Z
KubevirtVmHighMemoryUsage           ACTIVE  2025-03-27T20:13:02.629Z
TargetDown                          ACTIVE  2025-03-17T20:30:04.000Z
KubeContainerWaiting                ACTIVE  2025-03-17T21:15:28.460Z
TargetDown                          ACTIVE  2025-03-17T20:30:04.000Z
UpdateAvailable                     ACTIVE  2025-03-28T19:19:29.323Z
NonCompliant                        ACTIVE  2025-03-17T20:29:15.471Z
KubeDaemonSetRolloutStuck           ACTIVE  2025-03-20T12:03:58.460Z
PodStartupStorageOperationsFailing  ACTIVE  2025-03-17T20:21:06.441Z
KubeJobFailed                       ACTIVE  2025-03-17T20:30:28.460Z
KubeStatefulSetReplicasMismatch     ACTIVE  2025-03-17T20:30:28.460Z
KubePodCrashLooping                 ACTIVE  2025-03-17T20:30:28.460Z
TargetDown                          ACTIVE  2025-03-17T20:30:04.000Z
KubeJobFailed                       ACTIVE  2025-03-17T20:30:28.460Z
KubeDeploymentReplicasMismatch      ACTIVE  2025-03-31T13:09:03.218Z
KubevirtVmHighMemoryUsage           ACTIVE  2025-03-31T10:10:02.629Z
InsightsRecommendationActive        ACTIVE  2025-03-17T20:20:32.985Z
PodStartupStorageOperationsFailing  ACTIVE  2025-03-17T20:22:06.441Z
PodStartupStorageOperationsFailing  ACTIVE  2025-03-17T20:21:36.441Z
TargetDown                          ACTIVE  2025-03-17T20:30:04.000Z
TargetDown                          ACTIVE  2025-03-17T20:30:04.000Z
TargetDown                          ACTIVE  2025-03-17T20:30:04.000Z
ClusterNotUpgradeable               ACTIVE  2025-03-17T21:14:59.448Z
KubeDaemonSetNotScheduled           ACTIVE  2025-03-17T20:25:28.460Z
IngressWithoutClassName             ACTIVE  2025-03-21T05:48:35.236Z
TargetDown                          ACTIVE  2025-03-17T20:30:04.000Z
TargetDown                          ACTIVE  2025-03-17T20:30:04.000Z
KubeJobFailed                       ACTIVE  2025-03-17T20:30:28.460Z
KubeContainerWaiting                ACTIVE  2025-03-17T21:15:28.460Z
IngressWithoutClassName             ACTIVE  2025-03-21T05:48:35.236Z$
```

CONTRIBUTING
------------

All contributions are welcome to the project as long as they do not change the core functionality of the script.

### Development Guidelines
- Follow PEP 8 style guidelines
- Add type hints for new functions
- Use pathlib for file operations
- Extract magic numbers as named constants
- Write descriptive docstrings
- Ensure Python 3.9+ compatibility

In your Pull Request please provide the ClusterID you used to test.

### Code Quality
The codebase follows modern Python practices:
- Type safety with comprehensive type hints
- Secure file operations using pathlib
- Named constants for maintainability
- Proper error handling and logging
- Performance optimizations

AUTHORS
------

Morgan Peterman
