ocp_insights.sh - OpenShift 4 Insights
===========================================

DESCRIPTION
------------

This version of the script looks at insights archives that have been collected in a must-gather.

USAGE
------------

```bash
$ ocp_insights.sh --file insights-2024-08-14-144858.tar.gz

Cluster Version: 4.14.27
Channel: eus-4.14
Previous Version(s): 4.14.27, 4.14.18, 4.13.30, 4.12.36, 4.12.22, 4.12.13, 4.11.33, 4.11.20, 4.11.17, 4.11.12, 4.11.9

Platform: VSphere
Install Type: IPI
NetworkType: OpenShiftSDN
Proxy Configured:
  HTTP: false
  HTTPS: false
apiServerInternalIP: 10.1.18.6
ingressIP: 10.1.18.6

etcd Encryption: None
Audit Profile: Default

NAME                       READY  ROLE    CREATED ON            VERSION           OS                                                            CPU  MEMORY
ocpprd-control-plane-1     True   master  2024-08-01T21:07:31Z  v1.27.13+048520e  Red Hat Enterprise Linux CoreOS 414.92.202405162017-0 (Plow)  16   63G
ocpprd-worker-infra-01     True   worker  2024-08-01T21:18:13Z  v1.27.13+048520e  Red Hat Enterprise Linux CoreOS 414.92.202405162017-0 (Plow)  16   63G
...
```

SAMPLE OUTPUT
------------

```bash
$ ocp_insights.sh --help

USAGE: ocp_insights.sh

Displays information obtained from the latest Insights data for the cluster ID provided.

Options:
      --all                       Lists all of the following options
        --customer_memory         Lists memory usage for non-OpenShift Cluster Namespaces
        --uid                     Lists Namespaces with overlapping UIDs
        --storage_classes         Lists Storage Class information
      --file                      Run the script against a specific insights file
                                    E.g.: temp_ocp_insights.sh --file ~/insights_archive.tar.gz
      --etcd_metrics              Returns metrics from Insights Metrics Data
      --customer_memory_report    Returns metrics from Insights Metrics Data
  -h, --help                      Shows this help message.
```

AUTHORS
------

Morgan Peterman

Alan Chan