ocp_insights.py - OpenShift 4 Insights
===========================================

DESCRIPTION
------------

ocp_insights.py is a modern, pythonic script that collects the latest Insights data for a connected OpenShift 4 Cluster and parses the data in an easily readable format.

To use the script you *MUST* be on SupportShell due to the Insights data being stored locally, or use the `--remote` option to execute the script remotely on SupportShell from your local machine.

REQUIREMENTS
------------
- Python 3.9 or higher
- Access to SupportShell environment (or use `--remote` option)
- Required Python modules (all standard library):
  - `argparse`, `json`, `pathlib`, `tarfile`, `uuid`, `datetime`, `typing`, `subprocess`, `os`
- For `--remote` functionality:
  - SSH access to remote server
  - `scp` command available

INSTALLATION
------------
* Clone the repository, if on SupportShell this should be in your $HOME directory.
* Copy to a folder in your $PATH (protip: create a symbolic link then you only need to run `git pull` to use the latest version)
* Ensure the script has execute permissions: `chmod +x ocp_insights.py`

USAGE
------------

```bash
ocp_insights.py --help
usage: ocp_insights.py [-h] [--id ID] [--file FILE] [--alerts] [--customer_memory] [--etcd_metrics] [--events] [--list] [--extract] [--cluster_info] [--node_info] [--cluster_operators] [--node_logs NODE_NAME] [--remote] [--server SERVER]

OpenShift InsightsCluster Report.

options:
  -h, --help            show this help message and exit
  --id ID               ClusterID of a connected cluster used to find all connected Clusters
  --file FILE           Use a specific Insights Archive File; must specify full path.
  --alerts              Prints out Alerts in valid JSON
  --customer_memory     Prints Customer Namespace memory usage.
  --etcd_metrics        Prints etcd Slow Apply metrics for all Insights Archives for the cluster.
  --events              Prints only namespace events and exits (events are always included in full reports by default).
  --list                List available archives for a specific cluster. Must be used with --id option. Can be combined with --extract.
  --extract             Extract archive for a specific cluster to user's home directory. Must be used with --id option. Can be combined with --list to select which archive to extract.
  --cluster_info        Prints only cluster information (ID, name, version, platform, network, encryption, etc.).
  --node_info           Prints only node information (name, status, role, version, OS, CPU, memory).
  --cluster_operators   Prints only cluster operator information (name, version, status).
  --node_logs NODE_NAME Print logs for a master node. Provide the full node name (FQDN). Master nodes only.
  --remote              Connect to remote server to perform analysis
  --server SERVER       Remote server to connect to (overrides default). Use with --remote option.
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

### Cluster Information with --cluster_info

The `--cluster_info` option prints only the essential cluster information without processing nodes, operators, pods, or other detailed resources. This is useful for quick cluster identification and basic configuration checks:

```bash
# Get cluster info using cluster ID
ocp_insights.py --id <cluster-uuid> --cluster_info

# Get cluster info from a specific file
ocp_insights.py --file /path/to/insights-archive.tar.gz --cluster_info

# Example output:
Checkin: Mon Mar 31 02:09:28 PM UTC 2025

Cluster ID: abc123-def456-ghi789
Cluster Name: my-cluster.example.com
Cluster Version: 4.16.20
Channel: eus-4.16
Previous Versions: 4.16.20, 4.15.37, 4.14.31, 4.13.22

Platform: BareMetal
Install Type: IPI
Network Type: OVNKubernetes
IPsec: Disabled

Proxy Settings:
   HTTP:  False
   HTTPS: False

etcd Encryption: None
Audit Profile: Default
```

This feature is useful for:
- **Quick cluster identification**: Rapidly identify cluster details without full analysis
- **Configuration verification**: Check basic network, security, and platform settings
- **Troubleshooting**: Verify cluster version and channel information
- **Documentation**: Generate basic cluster information for reports

**Note**: This option outputs only the cluster configuration and skips all resource analysis (nodes, operators, pods, alerts, etc.).

### Node Information with --node_info

The `--node_info` option prints only the node information without processing cluster operators, pods, alerts, or other detailed resources. This is useful for quickly checking node status, capacity, and configuration:

```bash
# Get node info using cluster ID
ocp_insights.py --id <cluster-uuid> --node_info

# Get node info from a specific file
ocp_insights.py --file /path/to/insights-archive.tar.gz --node_info

# Example output:

Node Information:

NAME                READY  ROLE                                                 CREATED ON           VERSION          OS                                                     CPU  MEMORY
nyc-acp-n1.nyc.lab  True   control-plane,master,mcp-master-hp,worker,worker-hp  2024-01-06 07:20:55  v1.29.9+5865c5b  Red Hat Enterprise Linux CoreOS 416.94.202410292028-0  144  503 GB
nyc-acp-n2.nyc.lab  True   control-plane,master,mcp-master-hp,worker,worker-hp  2024-01-06 07:17:31  v1.29.9+5865c5b  Red Hat Enterprise Linux CoreOS 416.94.202410292028-0  144  503 GB
nyc-acp-n3.nyc.lab  True   control-plane,master,mcp-master-hp,worker,worker-hp  2024-01-06 07:41:52  v1.29.9+5865c5b  Red Hat Enterprise Linux CoreOS 416.94.202410292028-0  144  503 GB
nyc-acp-n4.nyc.lab  True   worker,worker-hp                                     2024-01-06 08:41:40  v1.29.9+5865c5b  Red Hat Enterprise Linux CoreOS 416.94.202410292028-0  144  503 GB
```

This feature is useful for:
- **Quick node inventory**: Rapidly view all nodes and their status
- **Capacity planning**: Check CPU and memory resources across nodes
- **Node verification**: Verify node roles and kubelet versions
- **Troubleshooting**: Identify NotReady nodes or version mismatches
- **Documentation**: Generate node inventory for reports

**Note**: This option outputs only node information and skips cluster configuration, operators, pods, and other resources.

### Cluster Operators with --cluster_operators

The `--cluster_operators` option prints only the cluster operator information without processing cluster configuration, nodes, pods, alerts, or other detailed resources. This is useful for quickly checking the health and status of cluster operators:

```bash
# Get cluster operator info using cluster ID
ocp_insights.py --id <cluster-uuid> --cluster_operators

# Get cluster operator info from a specific file
ocp_insights.py --file /path/to/insights-archive.tar.gz --cluster_operators

# Example output:

Cluster Operators:

NAME                                      VERSION  AVAILABLE  PROGRESSING  DEGRADED  REASON
authentication                            4.16.20  True       False        True      OAuthServerConfigObservationDegraded: error validating configMap openshift-config/ca-config-map: certificate expired:...
baremetal                                 4.16.20  True       False        False
cloud-controller-manager                  4.16.20  True       False        False
cloud-credential                          4.16.20  True       False        False
cluster-autoscaler                        4.16.20  True       False        False
config-operator                           4.16.20  True       False        False
console                                   4.16.20  True       False        False
dns                                       4.16.20  True       True         False     DNS "default" reports Progressing=True: "Have 26 available DNS pods, want 27."
etcd                                      4.16.20  True       False        False
image-registry                            4.16.20  True       False        False
ingress                                   4.16.20  True       False        False
kube-apiserver                            4.16.20  True       False        False
monitoring                                4.16.20  True       False        False
network                                   4.16.20  True       True         False     DaemonSet "/openshift-multus/multus" is not available (awaiting 1 nodes) DaemonSet "/openshift-multus/network-metrics...
storage                                   4.16.20  True       False        False
```

#### Features

The cluster operators output includes a **REASON** column that displays messages from problematic conditions:
- Shows messages when **Degraded=True** (e.g., certificate errors, configuration issues)
- Shows messages when **Progressing=True** (e.g., pod availability, rollout status)
- Messages are formatted on a single line for clean table display
- Long messages are truncated to 120 characters with "..." for readability
- Empty when all conditions are healthy

This feature is useful for:
- **Quick health checks**: Rapidly identify degraded or unavailable operators
- **Root cause analysis**: Immediately see why an operator is degraded or progressing
- **Troubleshooting**: Focus on operator status without full cluster analysis
- **Upgrade validation**: Verify all operators are available and not degraded
- **Status monitoring**: Check operator progression during updates with detailed reasons
- **Documentation**: Generate operator status reports with diagnostic information

**Note**: This option outputs only cluster operator information and skips cluster configuration, nodes, pods, alerts, and other resources.

### Node Logs with --node_logs

The `--node_logs` option allows you to print node logs for a specific master node. Node logs only exist for master nodes in the insights archive and are stored in the `config/node/logs/` directory:

```bash
# Get node logs using cluster ID
ocp_insights.py --id <cluster-uuid> --node_logs master1.example.com

# Get node logs from a specific file
ocp_insights.py --file /path/to/insights-archive.tar.gz --node_logs master1.example.com

# Can be used with --list to select archive first
ocp_insights.py --id <cluster-uuid> --list --node_logs master1.example.com

# Example output:

Node Logs for: master1.prod-b.openshift.example.com
================================================================================
Dec 03 17:36:05.367709 master1.prod-b.openshift.example.com kubenswrapper[2892]: I1203 17:36:05.367681    2892 prober.go:107] "Probe failed" probeType="Readiness" pod="openshift-apiserver/apiserver-686d8478c9-p48qk" podUID="b249cc2a-bb7d-4cce-ac40-d2872676102a" containerName="openshift-apiserver" probeResult="failure" output="Get \"https://10.128.69.1:8443/readyz?exclude=etcd&exclude=etcd-readiness\": dial tcp 10.128.69.1:8443: connect: connection refused"
...
```

#### Features

- **Master nodes only**: Node logs are only available for master/control-plane nodes in insights archives
- **FQDN required**: Provide the full qualified domain name of the node
- **Auto-extension**: The `.log` extension is automatically added if not provided
- **Error handling**: Clear error message if logs don't exist or are empty

#### Examples

```bash
# With .log extension
ocp_insights.py --file insights.tar.gz --node_logs master1.example.com.log

# Without .log extension (automatically added)
ocp_insights.py --file insights.tar.gz --node_logs master1.example.com

# Non-existent or empty logs
ocp_insights.py --file insights.tar.gz --node_logs worker1.example.com
# Output: No logs for worker1.example.com
```

This feature is useful for:
- **Troubleshooting master nodes**: Review kubelet logs and system events on control-plane nodes
- **Probe failures**: Investigate readiness and liveness probe issues
- **Certificate errors**: Check for certificate-related problems
- **Node-specific issues**: Debug issues affecting specific master nodes

**Note**: Node logs are only captured for master/control-plane nodes. Worker node logs are not available in insights archives.

### Remote Execution with --remote

The `--remote` option allows you to execute the script on a remote server (typically SupportShell) from your local machine. This is useful when you don't have direct access to the server where Insights data is stored, but can connect via SSH:

```bash
# Execute analysis on the default remote server
ocp_insights.py --id <cluster-uuid> --remote

# Execute analysis on a custom remote server
ocp_insights.py --id <cluster-uuid> --remote --server custom-server.example.com

# Use with other options
ocp_insights.py --id <cluster-uuid> --remote --cluster_info
ocp_insights.py --id <cluster-uuid> --remote --events
```

#### Requirements

- **SSH Client**: The `--remote` option uses your system's SSH client to connect to the remote server
- **SSH Access**: SSH access to the remote server must be configured
- **Remote Script**: The script will be temporarily copied to `/tmp` on the remote server and cleaned up after execution

#### SSH Configuration

The `--remote` option uses your system's **SSH client** to establish connections. If you need to specify a different username or other SSH settings (port, identity file, etc.), configure your SSH client using `~/.ssh/config`:

```bash
# Example SSH config (~/.ssh/config)
Host supportshell
    HostName supportshell-1.sush-001.prod.us-west-2.aws.redhat.com
    User myusername
    Port 22
    IdentityFile ~/.ssh/my_private_key
```

Then reference your configured host when using the `--remote` option:

```bash
# Use the SSH config alias
ocp_insights.py --id <cluster-uuid> --remote --server supportshell

# Use another SSH config alias
ocp_insights.py --id <cluster-uuid> --remote --server custom-server
```

#### Features

- **Automatic Script Transfer**: The script copies itself to the remote server via SCP
- **All Options Supported**: Most command-line options work with `--remote` (except `--server` which is local-only)
- **Automatic Cleanup**: Temporary files are automatically removed from the remote server
- **Custom Server Support**: Use `--server` to override the default remote server
- **SSH Config Compatible**: Fully compatible with SSH config files for customized connection settings

#### Security Notes

- Temporary files are created with unique process IDs to avoid conflicts
- Cleanup is performed even if the remote command fails or times out
- The `--server` option can only be used together with `--remote`
- SSH authentication uses your system's SSH client configuration (keys, agent, config file)

**Default Remote Server**: `supportshell-1.sush-001.prod.us-west-2.aws.redhat.com`

### Namespace Events with --events

Namespace warning events are **always included** in the full cluster report by default. The `--events` option allows you to display **only** the namespace events without any other cluster information:

```bash
# Show ONLY namespace events (no other cluster information)
ocp_insights.py --id <cluster-uuid> --events
ocp_insights.py --file /path/to/insights-archive.tar.gz --events

# Show full cluster report INCLUDING namespace events (default behavior)
ocp_insights.py --id <cluster-uuid>
ocp_insights.py --file /path/to/insights-archive.tar.gz

# Example output with --events (only events shown):
Namespace Event Errors:

NAMESPACE                        TYPE     REASON              TIME
openshift-kube-apiserver         Warning  FailedMount         2025-03-31 13:15:23
openshift-monitoring             Warning  BackOff             2025-03-31 14:22:15
openshift-etcd                   Warning  Unhealthy           2025-03-31 15:30:42
```

#### Key Behavior:
- **With `--events` flag**: Displays **only** namespace events and exits (no other cluster data)
- **Without `--events` flag**: Displays **full cluster report** including namespace events as one of many sections

This feature is useful for:
- **Quick troubleshooting**: Identify namespace-level issues rapidly without full report
- **Event analysis**: Focus exclusively on warning events
- **Log extraction**: Generate clean event-only reports for documentation
- **Piping to other tools**: Extract just events for further processing

**Note**: Only warning-type events are displayed. If no warning events exist, "No namespace events found." will be displayed.

### etcd Metrics with --etcd_metrics

The `--etcd_metrics` option extracts etcd slow apply metrics from insights archives. It can be used with both `--id` and `--file` options:

```bash
# Extract metrics from all archives for a cluster
ocp_insights.py --id <cluster-uuid> --etcd_metrics

# Extract metrics from a specific file
ocp_insights.py --file /path/to/insights-archive.tar.gz --etcd_metrics

# Example output (CSV format):
etcd-nyc-acp-n1.nyc.lab,Mon Mar 31 02:09:28 PM UTC 2025,42
etcd-nyc-acp-n2.nyc.lab,Mon Mar 31 02:09:28 PM UTC 2025,38
etcd-nyc-acp-n3.nyc.lab,Mon Mar 31 02:09:28 PM UTC 2025,45
```

**Output format**: `pod_name,check_in_time,slow_apply_count`

This feature is useful for:
- **Performance analysis**: Track etcd slow apply operations over time
- **Capacity planning**: Identify nodes experiencing storage or performance issues
- **Troubleshooting**: Correlate etcd slowness with cluster issues
- **Historical tracking**: Compare metrics across different time periods

**Note**: For files without timestamp-based names, the file's modification time is used for the check-in time.

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

Pending CSRs: 0

NAME                READY  ROLE                                                 CREATED ON           VERSION          OS                                                     CPU  MEMORY
nyc-acp-n1.nyc.lab  True   control-plane,master,mcp-master-hp,worker,worker-hp  2024-01-06 07:20:55  v1.29.9+5865c5b  Red Hat Enterprise Linux CoreOS 416.94.202410292028-0  144  503 GB
nyc-acp-n2.nyc.lab  True   control-plane,master,mcp-master-hp,worker,worker-hp  2024-01-06 07:17:31  v1.29.9+5865c5b  Red Hat Enterprise Linux CoreOS 416.94.202410292028-0  144  503 GB
nyc-acp-n3.nyc.lab  True   control-plane,master,mcp-master-hp,worker,worker-hp  2024-01-06 07:41:52  v1.29.9+5865c5b  Red Hat Enterprise Linux CoreOS 416.94.202410292028-0  144  503 GB
nyc-acp-n4.nyc.lab  True   worker,worker-hp                                     2024-01-06 08:41:40  v1.29.9+5865c5b  Red Hat Enterprise Linux CoreOS 416.94.202410292028-0  144  503 GB

Cluster Operators:

NAME                                      VERSION  AVAILABLE  PROGRESSING  DEGRADED  REASON
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
IngressWithoutClassName             ACTIVE  2025-03-21T05:48:35.236Z

PodNetworkConnectivitChecks:

ERROR                                 TIMESTAMP
kubernetes-default-service-cluster-0  2025-12-03 16:21:54Z
load-balancer-api-external            2025-12-03 17:18:55Z
load-balancer-api-internal            2025-12-03 17:07:55Z
openshift-apiserver-service-cluster   2025-12-03 17:11:54Z

Conditional Update Risks:

RISK                                     REFERENCE                                         AFFECTED VERSIONS
ConsoleEnabledTargetDownAlert            https://issues.redhat.com/browse/CONSOLE-4632     4.18.12, 4.18.13, 4.18.14, 4.18.15, 4.18.16, 4.18.17
ContinuousNodeRebootingDueToKernelPanic  https://issues.redhat.com/browse/COS-3700         4.18.24, 4.18.25, 4.18.26
CrunConflictsWithNVIDIA                  https://issues.redhat.com/browse/RUN-3446         4.18.22, 4.18.23
HyperShiftClusterVersionOperatorMetrics  https://issues.redhat.com/browse/OTA-1705         4.18.23, 4.18.24, 4.18.25, 4.18.26
HyperShiftProxyScheme                    https://issues.redhat.com/browse/CNTRLPLANE-1407  4.18.22, 4.18.23, 4.18.24
MetallbBgpBfdFrrRpm                      https://issues.redhat.com/browse/CNF-17689        4.18.10, 4.18.11
NMStateServiceFailure                    https://issues.redhat.com/browse/CORENET-6419     4.18.22, 4.18.23, 4.18.24
```

CONTRIBUTING
------------

All contributions are welcome to the project as long as they do not change the core functionality of the script.

In your Pull Request please provide the ClusterID you used to test.

AUTHORS
------

Morgan Peterman
