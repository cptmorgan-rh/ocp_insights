#!/usr/bin/env bash

## Enabling -e cause getopt to exit right away when invalid options detect
## Enable only when debug
## set -e

parse_args(){

  options=$(getopt -n "ocp_insights.sh" -o cfhl --long help,file:,customer_memory,uid,storage_classes,all,etcd_metrics, -- "$@")

  if [[ $? != 0 ]]; then
    echo
    show_help
    exit 1
  fi

  eval set -- "$options"
  while true; do
    case "$1" in
      --all)
        all=true; shift;;
      --storage_classes)
        sc_info=true; shift;;
      --customer_memory)
        customer_memory=true; shift;;
      --uid)
        uids=true; shift;;
      --file)
        insights_file=$2;file=true; shift 2;;
      --etcd_metrics)
        etcd_stats=true; shift;;
      -h | --help)
        shift; echo; show_help; exit 0;;
      --)
        shift;;
      *)
        if [[ -z "$1" ]]; then break; else echo; show_help; exit 1; fi;;
    esac
  done

}

run(){

  if [[ "$cus_memory_report" = true ]]; then
    cus_memory_rpt
  fi

  if [[ "$file" == true ]]; then
    if [[ -f "$insights_file" ]]; then
      extract_insights_file
    else
      echo -n "File not found."
      exit 127
    fi
  fi

}

extract_insights_file(){

  extract_dir="${insights_file:0:-7}"
  mkdir -p ${extract_dir}
  tar xzf "$insights_file" -C ${extract_dir}
  cd ${extract_dir}
  if [[ "$etcd_stats" = true ]]; then
    etcd_metrics
    exit 0
  fi
  ocp_platform

}

ocp_platform(){

  if [ -f config/infrastructure.json ]; then

    platform=$(jq -r '.status.platformStatus.type' config/infrastructure.json)

    case "$platform" in
      VSphere)
        pltf_vsphere "$platform"
        ;;

      AWS)
        pltf_aws "$platform"
        ;;

      Azure)
        pltf_azure "$platform"
        ;;

      GCP)
        pltf_gcp "$platform"
        ;;

      OpenStack)
        pltf_openstack "$platform"
        ;;

      oVirt)
        pltf_ovirt "$platform"
        ;;

      Nutanix)
        pltf_nutanix "$platform"
        ;;

      Baremetal)
        pltf_baremetal "$platform"
        ;;

      BareMetal)
        pltf_baremetal "$platform"
        ;;

      IBMCloud)
        pltf_ibmcloud "$platform"
        ;;

      External)
        pltf_external "$platform"
        ;;

      None)
        pltf_none
        ;;

      *)
        echo "Unknown Platform."
        pltf_none
    esac

fi

}

pltf_ovirt(){

  if $(jq -r '.status.platformStatus | has("ovirt")' config/infrastructure.json);
  then
    install_type="IPI"
    api_internal_ip=$(jq -r '.status.platformStatus.ovirt.apiServerInternalIP' config/infrastructure.json)
    ingressip=$(jq -r '.status.platformStatus.ovirt.ingressIP' config/infrastructure.json)
  else
    install_type="UPI"
  fi

  output "$1" "${install_type}"
  printf "\n"

}

pltf_aws(){

  if $(jq -r '.status.platformStatus | has("aws")' config/infrastructure.json);
  then
    install_type="IPI"
    aws_region=$(jq -r '.status.platformStatus.aws.region' config/infrastructure.json )
  else
    install_type="UPI"
  fi

  output "$1" "${install_type}"
  printf "\n"

}

pltf_azure(){

  if $(jq -r '.status.platformStatus | has("azure")' config/infrastructure.json);
  then
    install_type="IPI"
    azure_resourcegroupname=$(jq -r '.status.platformStatus.azure.resourceGroupName' config/infrastructure.json)
    azure_networkresourcegroupname=$(jq -r '.status.platformStatus.azure.networkResourceGroupName' config/infrastructure.json)
  else
    install_type="UPI"
  fi

  output "$1" "${install_type}"
  printf "\n"

}

pltf_baremetal(){

  if $(jq -r '.status.platformStatus | has("baremetal")' config/infrastructure.json);
  then
    install_type="IPI"
    api_internal_ip=$(jq -r '.status.platformStatus.baremetal.apiServerInternalIP' config/infrastructure.json)
    ingressip=$(jq -r '.status.platformStatus.baremetal.ingressIP' config/infrastructure.json)
  else
    install_type="UPI"
  fi

  output "$1" "${install_type}"
  printf "\n"

}

pltf_gcp(){

  if $(jq -r '.status.platformStatus | has("gcp")' config/infrastructure.json);
  then
    install_type="IPI"
    gcp_projectid=$(jq -r '.status.platformStatus.gcp.projectID' config/infrastructure.json)
    gcp_region=$(jq -r '.status.platformStatus.gcp.region' config/infrastructure.json)
  else
    install_type="UPI"
  fi

  output "$1" "${install_type}"
  printf "\n"

}

pltf_openstack(){

  if $(jq -r '.status.platformStatus | has("openstack")' config/infrastructure.json);
  then
    install_type="IPI"
    api_internal_ip=$(jq -r '.status.platformStatus.openstack.apiServerInternalIP' config/infrastructure.json)
    ingressip=$(jq -r '.status.platformStatus.openstack.ingressIP' config/infrastructure.json)
    nodeDNSIP=$(jq -r '.status.platformStatus.openstack.nodeDNSIP' config/infrastructure.json)
  else
    install_type="UPI"
  fi

  output "$1" "${install_type}"
  printf "\n"

}

pltf_vsphere(){

  if $(jq -r '.status.platformStatus | has("vsphere")' config/infrastructure.json);
  then
    install_type="IPI"
    api_internal_ip=$(jq -r '.status.platformStatus.vsphere.apiServerInternalIP' config/infrastructure.json)
    ingressip=$(jq -r '.status.platformStatus.vsphere.ingressIP' config/infrastructure.json)
  else
    install_type="UPI"
  fi

  output "$1" "${install_type}"
  printf "\n"

}

pltf_nutanix(){

  if $(jq -r '.status.platformStatus | has("nutanix")' config/infrastructure.json);
  then
    install_type="IPI"
    api_internal_ip=$(jq -r '.status.platformStatus.nutanix.apiServerInternalIP' config/infrastructure.json)
    ingressip=$(jq -r '.status.platformStatus.nutanix.ingressIP' config/infrastructure.json)
  else
    install_type="UPI"
  fi

  output "$1" "${install_type}"
  printf "\n"

}

pltf_ibmcloud(){

  if $(jq -r '.status.platformStatus | has("ibmcloud")' config/infrastructure.json);
  then
    install_type="IPI"
    api_internal_ip=$(jq -r '.status.platformStatus.ibmcloud.apiServerInternalIP' config/infrastructure.json)
    ingressip=$(jq -r '.status.platformStatus.ibmcloud.ingressIP' config/infrastructure.json)
  else
    if $(grep -E 'hypershift|ROKS' config/configmaps/openshift-config/openshift-install/invoker >/dev/null 2>&1)
    then
      install_type="HyperShift"
    else
      install_type="UPI"
    fi
  fi

  output "$1" "${install_type}"
  printf "\n"

}

pltf_external(){

  if $(jq -r '.status.platformStatus.type | contains("External")' config/infrastructure.json);
  then
    install_type="UPI"
    provider=$(jq -r '.spec.platformSpec.external.platformName' config/infrastructure.json)
  fi

  output "$1" "${install_type}" "${provider}"
  printf "\n"

}

pltf_none(){

  output "No Platform Provided" "UPI"
  printf "\n"

}

ipi_info(){

  # Outputs specific information related to the IPI Installation

  # vSphere, BareMetal, and OpenStack
  if [ -n "$api_internal_ip" ] && [ -n "$ingressip" ]; then
    echo "apiServerInternalIP: $api_internal_ip"
    echo "ingressIP: $api_internal_ip"
  fi

  # OpenStack
  if [ -n "$nodeDNSIP" ]; then
    echo "nodeDNSIP: $nodeDNSIP"
  fi

  # Azure
  if [ -n "$azure_resourcegroupname" ]; then
    echo "Azure Resource Group: $azure_resourcegroupname"
  fi
  if [ -n "$azure_networkresourcegroupname" ]; then
    echo "Azure Network Resource Group: $azure_networkresourcegroupname"
  fi

  # GCP
  if [ -n "$gcp_projectid" ]; then
    echo "GCP Project ID: $gcp_projectid"
  fi
  if [ -n "$gcp_region" ]; then
    echo "GCP Region: $gcp_region"
  fi

  # AWS
  if [ -n "$aws_region" ]; then
    echo "AWS Region: $aws_region"
  fi

  printf "\n"

}

node_status(){

  if [[ "$(ls -A config/node/*.json | wc -l 2>/dev/null)" -ne 0 ]]; then
    nodes_arr=("NAME|READY|ROLE|CREATED ON|VERSION|OS|CPU|MEMORY")
    for i in config/node/*.json; do
      nodes_arr+=("$(jq -r '[.metadata.name, (.status.conditions[] | select(.type == "Ready") | .status), (.metadata.labels|with_entries(select(.key|match("node-role.kubernetes.io")))|keys|map(split("/")[1])|join(",")), .metadata.creationTimestamp, .status.nodeInfo.kubeletVersion, .status.nodeInfo.osImage] | join("|")' "$i")|$(jq -r '.status.capacity.cpu' "$i")|$(jq -r '.status.capacity.memory' "$i" | numfmt --from=auto --to=iec --round up)");
    done
    printf '%s\n' "${nodes_arr[@]}" | column -t -s '|'
    printf "\n"

    unset nodes_arr
  else
    printf "Node Information Missing\n"
  fi

}

clusteroperator_status(){

  if [[ "$(ls -A config/clusteroperator/*.json | wc -l 2>/dev/null)" -ne 0 ]]; then
    clusteroperator_arr=("NAME|VERSION|AVAILABLE|PROGRESSING|DEGRADED")
    for i in config/clusteroperator/*.json; do
      clusteroperator_arr+=("$(jq -r '[.metadata.name, (.status.versions[] | select(.name == "operator") | .version), (.status.conditions[] | select(.type == "Available") | .status), (.status.conditions[] | select(.type == "Progressing") | .status), (.status.conditions[] | select(.type == "Degraded") | .status)] | join("|")' "$i")");
    done
    printf '%s\n' "${clusteroperator_arr[@]}" | column -t -s '|'
    printf "\n"

    unset clusteroperator_arr
  fi

}

installed_operators(){

  if [ -f "config/installplans.json" ];
  then
    installed_operator_count=$(jq -r .stats.TOTAL_COUNT config/installplans.json)
    if [[ $installed_operator_count != "0" ]];
    then
      printf "Installed Operators:\n"
      printf "\n"
      for i in $(jq -r '.items[].csv' config/installplans.json | sort -u); do
        printf "%s$i\n"
      done
      printf '\n'
    fi
  fi

}

olm_operators(){

  if [ -f "config/olm_operators.json" ];
  then
    olm_length=$(jq length config/olm_operators.json)
    olm_count=$(( $olm_length - 1 ))

    for i in $(seq 0 ${olm_count}); do
      olm_results_arr+=("$(jq -r "[select(.[$i].displayName != \"\" and .[$i].version != \"\") | .[$i].displayName, .[$i].version, .[$i].name] | join(\"|\")" config/olm_operators.json)");
    done

    olm_arr=("DISPLAY NAME|VERSION|NAME")

    for i in $(seq 0 ${olm_count}); do
      if [ "${#olm_results_arr[$i]}" != 0 ];
      then
        olm_arr+=("$(echo ${olm_results_arr[$i]})")
      fi
    done

    if [ "${#olm_arr[1]}" != 0 ];
    then
      printf "Installed OLM Operators:\n\n"
      printf '%s\n' "${olm_arr[@]}" | column -t -s '|'
      printf "\n"
    fi

    unset olm_length
    unset olm_count
    unset olm_results_arr
    unset olm_arr

  fi

}

namespace_events(){

  # Get events with data
  if [ -d "events/" ];
  then
    for i in events/*.json; do
      if grep namespace "$i" >/dev/null 2>&1;
      then
        namespace_arr+=($(echo "$i" | cut -f 1 -d '.'))
      fi
    done

    printf "Last message from each namespace with events:\n\n"

    for i in "${namespace_arr[@]}";
    do
      printf "To see all events for ${i#*events/} run: jq -r . ${extracted_dir}${cluster}/$i.json\n"
      printf "\n"
      echo "Namespace: $(jq -r '.items[-1].namespace' $i.json)"
      echo "Last Timestamp: $(jq -r '.items[-1].lastTimestamp' "$i".json)"
      echo "Reason: $(jq -r '.items[-1].reason' $i.json)"
      echo "Message: $(jq -r '.items[-1].message' $i.json)"
      printf "\n"
    done
  fi

  unset namespace_arr

}

cluster_version(){

  if [ -f config/version.json ]; then
    cluster_ver=$(jq -r '.status.desired.version' config/version.json)
    cluster_channel=$(jq -r '.spec.channel' config/version.json)
    last_completed=$(jq -r '[(.status.history[] | select(.state == "Completed") | .version)] | join(", ")' config/version.json)

    echo "Cluster Version: $cluster_ver"
    echo "Channel: $cluster_channel"
    echo "Previous Version(s): $last_completed"

    cluster_up_fail=$(jq -r '.status.conditions[] | select(.type == "Failing" and .status == "True") | .status' config/version.json)

    if [[ "$cluster_up_fail" == "True" ]]; then
      printf "\n"
      echo "Cluster Status: Failing"
      echo "Reason: $(jq -r '.status.conditions[] | select(.type == "Failing" and .status == "True") | .reason' config/version.json)"
      echo "Message: $(jq -r '.status.conditions[] | select(.type == "Failing" and .status == "True") | .message' config/version.json)"
    fi
  else
    echo "Cluster Version: Information Missing"
    echo "Channel: Information Missing"
    echo "Previous Version(s): Information Missing"
  fi

}

machineconfigpool_info(){

  if [ -d "config/machineconfigpools/" ];
  then
    printf "MachineConfigPools:\n\n"
    machineconfigpool_arr=("NAME|CONFIG|PAUSED|UPDATED|UPDATING|DEGRADED|MACHINECOUNT|READYMACHINECOUNT|UPDATEDMACHINECOUNT|DEGRADEDMACHINECOUNT")
    for i in config/machineconfigpools/*.json; do machineconfigpool_arr+=("$(jq -r '[.metadata.name, .spec.configuration.name, (if .spec.paused == false then "False" else "True" end), (.status.conditions[] | select(.type == "Updated") | .status), (.status.conditions[] | select(.type == "Updating") | .status), (.status.conditions[] | select(.type == "Degraded") | .status), .status.machineCount, .status.readyMachineCount, .status.updatedMachineCount, .status.degradedMachineCount ] | join("|")' $i)") ; done
    printf '%s\n' "${machineconfigpool_arr[@]}" | column -t -s '|'
    printf "\n"
  fi

  unset machineconfigpool_arr

}

machineset_info(){

  machineset_arr=("NAME|DESIRED|CURRENT|READY|AVAILABLE")
  if [ -d "machinesets/openshift-machine-api" ];
  then
    for i in machinesets/openshift-machine-api/*.json;
    do machineset_arr+=("$(jq -r '[.metadata.name, .spec.replicas, .status.replicas, .status.readyReplicas, .status.availableReplicas ] | join("|")' "$i")") ; done
    printf "MachineSets:\n\n"
    printf '%s\n' "${machineset_arr[@]}" | column -t -s '|'
    printf "\n"
  fi

  if compgen -G "machinesets/*.json" >/dev/null 2>&1;
  then
    for i in machinesets/*.json;
    do machineset_arr+=("$(jq -r '[.metadata.name, .spec.replicas, .status.replicas, .status.readyReplicas, .status.availableReplicas ] | join("|")' "$i")") ; done
    printf "MachineSets:\n\n"
    printf '%s\n' "${machineset_arr[@]}" | column -t -s '|'
    printf "\n"
  fi

}

failing_pods(){

  if [ -d config/pod ]; then
    if [[ "$(ls -A config/pod/*/*.json | wc -l 2>/dev/null)" -ne 0 ]]; then
      failing_pods_arr=("NAMESPACE|POD NAME|REASON")
      for i in config/pod/*/*.json; do
        pods_arr+=("$(jq -r '[(select(.status.conditions[] | select(.type == "Ready" and .status == "False")) | .metadata.namespace), (select(.status.conditions[] | select(.type == "Ready" and .status == "False")) | .metadata.name), (.status.conditions[] | select(.type == "Ready" and .status == "False").message)] | join("|")' $i 2>/dev/null)")
      done

      for i in "${pods_arr[@]}"
      do
        if [ "$i" != "" ]
        then
          failing_pods_arr+=("$i")
        fi
      done

      unset pods_arr

      if [ "${#failing_pods_arr[1]}" != 0 ];
      then
        printf "Pods with errors:\n"
        printf '%s\n' "${failing_pods_arr[@]}" | column -t -s '|'
        printf "\n"
      fi

      unscheduled_pods_arr=("NAMESPACE|POD NAME|REASON")
      for i in config/pod/*/*.json; do
        pods_arr+=("$(jq -r '[(select(.status.conditions[] | select(.type == "PodScheduled" and .status == "False")) | .metadata.namespace), (select(.status.conditions[] | select(.type == "PodScheduled" and .status == "False")) | .metadata.name),  (.status.conditions[] | select(.type == "PodScheduled" and .status == "False").message)] | join("|")' $i 2>/dev/null)");
      done

      for i in "${pods_arr[@]}"
      do
        if [ "$i" != "" ]
        then
          unscheduled_pods_arr+=("$i")
        fi
      done

      if [ "${#unscheduled_pods_arr[1]}" != 0 ];
      then
        printf "Pods failing to Schedule:\n"
        printf '%s\n' "${unscheduled_pods_arr[@]}" | column -t -s '|'
        printf "\n"
      fi

      unset pods_arr

      restarting_pods_arr=("NAMESPACE|POD NAME|CONTAINER|RESTARTS")
      for i in $(ls -d config/pod/*/*.json); do
          for x in $(jq -r '.status.containerStatuses[] | select(.restartCount > 3) | .name' "$i" 2>/dev/null); do
              pods_arr+=("$(jq -r "[.metadata.namespace, .metadata.name, (.status.containerStatuses[] | select(select(.name == \"$x\" and .restartCount > 3)) | .name, .restartCount)] | join(\"|\")" "$i" 2>/dev/null)")
          done
      done

      for i in "${pods_arr[@]}"
      do
        if [ "$i" != "" ]
        then
          restarting_pods_arr+=("$i")
        fi
      done

      unset pods_arr

      if [ "${#restarting_pods_arr[1]}" != 0 ];
      then
        printf "Containers with more than 3 restarts:\n\n"
        printf '%s\n' "${restarting_pods_arr[@]}" | column -t -s '|'
        printf "\n"
      fi
    fi
  fi

  unset pods_arr
  unset failing_pods_arr
  unset unscheduled_pods_arr
  unset restarting_pods_arr

}

uid_overlap(){

  if [ -f config/namespaces_with_overlapping_uids.json ];
  then

    ns_length=$(jq length config/namespaces_with_overlapping_uids.json)
    ns_count=$(( $ns_length - 1 ))

    uid_conflict_arr=("NAMESPACE|NAMESPACE")
    for i in $(seq 0 ${ns_count}); do
      uid_conflict_arr+=("$(jq -r ".[$i] | to_entries | [(select(.[].key == 0) | .[].value)] | join(\"|\")" config/namespaces_with_overlapping_uids.json)")
    done

    if [ "${#uid_conflict_arr[1]}" != 0 ];
    then
      printf "Namespaces with overlapping UIDs:\n\n"
      printf '%s\n' "${uid_conflict_arr[@]}" | column -t -s '|'
      printf "\n"
    fi

    unset ns_length
    unset ns_count
    unset uid_conflict_arr

  fi

}

podnetcheck(){

  if [ -f config/podnetworkconnectivitychecks.json ];
  then

    podnetcheck_length=$(jq -r '. | to_entries | length' config/podnetworkconnectivitychecks.json)
    podnetcheck_count=$(( $podnetcheck_length - 1 ))

    podnetcheck_arr=("ERROR|COUNT")
    for i in $(seq 0 ${podnetcheck_count}); do
      podnetcheck_arr+=("$(jq -r ". | to_entries | [.[$i].key, (.[$i].value | length)] |  join(\"|\")" config/podnetworkconnectivitychecks.json)")
    done

    if [ "${#podnetcheck_arr[1]}" != 0 ];
    then
      printf "Pod Network Connectivity Checks:\n\n"
      printf '%s\n' "${podnetcheck_arr[@]}" | column -t -s '|'
      printf "\n"

      printf "To see all PodNetworkConnectivityCheck Errors run: jq -r . ${extract_dir}/config/podnetworkconnectivitychecks.json\n"
  fi

    unset podnetcheck_length
    unset podnetcheck_count
    unset podnetcheck_arr

  fi

}

ocp_ns_memory(){

  if [ -f config/metrics ];
  then

    ocp_ns_memory_usage=0
    ns_mem_arr=("NAMESPACE|MEMORY")
    namespaces=$(grep '^namespace:container_memory_usage_bytes:sum' config/metrics| awk -F, '{ print $1 }' | sed -e 's/namespace:container_memory_usage_bytes:sum{namespace=//' | sed -e 's/"//g' | sort -n | grep -E '^openshift|^default|^kube-[snp]')
    for i in $namespaces; do
      ns_mem_usage=$(grep '^namespace:container_memory_usage_bytes:sum' config/metrics| grep "namespace=\"$i\"" | sed -e 's/prometheus="openshift-monitoring//g' | sed -e 's/"//g' | awk '{ print $(NF-1)}' | xargs printf "%.0f\n")
      ns_mem_arr+=("$(echo "$i")|$(echo $ns_mem_usage | numfmt --to iec --format '%6.4f' --round down)")
      ocp_ns_memory_usage=$(( $ocp_ns_memory_usage + $ns_mem_usage ))
    done

    if [ "${#ns_mem_arr[1]}" != 0 ]; then
      printf "Cluster Namespace Memory Usage.\n\n"
      printf '%s\n' "${ns_mem_arr[@]}" | column -t -s '|'
      printf "\n"
      printf "Total Cluster Namespace Memory Usage: $( echo $ocp_ns_memory_usage | numfmt --to iec --format '%6.4f' --round down )"
      printf "\n\n"
    fi

    unset ns_mem_arr
    unset ocp_ns_memory_usage
    unset ns_mem_usage

  fi

}

customer_ns_memory(){

  if [ -f config/metrics ];
  then

    cus_ns_memory_usage=0
    ns_mem_arr=("NAMESPACE|MEMORY")
    namespaces=$(grep '^namespace:container_memory_usage_bytes:sum' config/metrics| awk -F, '{ print $1 }' | sed -e 's/namespace:container_memory_usage_bytes:sum{namespace=//' | sed -e 's/"//g' | sort -n | grep -Ev '^openshift|^default|^kube-[snp]')
    for i in $namespaces; do
      ns_mem_usage=$(grep '^namespace:container_memory_usage_bytes:sum' config/metrics| grep "namespace=\"$i\"" | sed -e 's/prometheus="openshift-monitoring//g' | sed -e 's/"//g' | awk '{ print $(NF-1)}' | xargs printf "%.0f\n" )
      ns_mem_arr+=("$(echo "$i")|$(echo $ns_mem_usage | numfmt --to iec --format '%6.4f' --round down)")
      cus_ns_memory_usage=$(( $cus_ns_memory_usage + $ns_mem_usage ))
    done

    if [ "${#ns_mem_arr[1]}" != 0 ]; then
      printf "Customer Namespace Memory Usage.\n\n"
      printf '%s\n' "${ns_mem_arr[@]}" | column -t -s '|'
      printf "\n"
      printf "Total Customer Namespace Memory Usage: $( echo $cus_ns_memory_usage | numfmt --to iec --format '%6.4f' --round down )"
      printf "\n\n"
    fi

    unset ns_mem_arr
    unset cus_ns_memory_usage
    unset ns_mem_usage

  fi

}

alerts(){

  if [ -f config/alerts.json ];
  then

    alerts_length=$(jq length config/alerts.json)
    alerts_count=$(( $alerts_length - 1 ))


    for i in $(seq 0 ${alerts_count}); do
      alerts_results_arr+=("$(jq -r "[(select(.[$i].labels.alertname != \"Watchdog\" and .[$i].status.state != \"suppressed\") | .[$i].labels.alertname, (.[$i].status.state | ascii_upcase), .[$i].startsAt)] | join(\"|\")" config/alerts.json)");
    done

    alerts_arr=("ALERT NAME|STATE|START TIME")

    for i in $(seq 0 ${alerts_count}); do
      if [ "${#alerts_results_arr[$i]}" != 0 ];
      then
        alerts_arr+=("$(echo ${alerts_results_arr[$i]})")
      fi
    done

    if [ "${#alerts_arr[1]}" != 0 ];
    then
      printf '%s\n' "${alerts_arr[@]}" | column -t -s '|'
      printf "\n"
      printf "To see all Alerts run: jq -r . ${extract_dir}${cluster}/config/alerts.json\n"
    fi

    unset alerts_length
    unset alerts_count
    unset alerts_results_arr
    unset alerts_arr

  fi

}

storageclasses(){

  if [ -d "config/storage/storageclasses/" ];
  then
    storageclass_arr=("NAME|PROVISIONER|RECLAIM POLICY|BINDING MODE|VOLUME EXPANSION")
    for i in config/storage/storageclasses/*.json; do
      storageclass_arr+=("$(jq -r '[.metadata.name, .provisioner, .reclaimPolicy, .volumeBindingMode, (if .allowVolumeExpansion != true then "False" else "True" end)] | join("|")' $i)")
    done

    if [ "${#storageclass_arr[1]}" != 0 ];
    then
      printf "StorageClass Information.\n\n"
      printf '%s\n' "${storageclass_arr[@]}" | column -t -s '|'
      printf "\n"
    fi
  fi

  unset storageclass_arr

}

etcd_metrics(){

  if grep etcd_server_slow_apply_total "config/metrics" > /dev/null; then
    printf "etcd server slow apply total\n\n"
    grep etcd_server_slow_apply_total "config/metrics" | grep etcd-metrics | grep -Ev '^#' | while read -r line; do
        pod=$(echo "$line" | grep -o "\{.*\}" | awk -F, '{ print $5 }' | grep -Po "etcd-.*(?=[\"])")
        count=$(echo "$line" | awk '{ print $2 }')

        echo "$pod,$count"
    done
    printf "\n"
  fi



  if grep etcd_server_slow_read_indexes_total "config/metrics" > /dev/null; then
    printf "etcd server slow read indexex total\n\n"
    grep etcd_server_slow_read_indexes_total "config/metrics" | grep etcd-metrics | grep -Ev '^#' | while read -r line; do
        pod=$(echo "$line" | grep -o "\{.*\}" | awk -F, '{ print $5 }' | grep -Po "etcd-.*(?=[\"])")
        count=$(echo "$line" | awk '{ print $2 }')

        echo "$pod,$count"
    done
  fi

}

output(){

  if [ "$all" = "true" ]; then
    sc_info=true
    customer_memory=true
    uids=true
  fi

  printf "\n"
  cluster_version
  printf "\n"

  echo "Platform: $1"
  if [ ! -z "$3" ]; then
      echo "Provider: $3"
  fi
  if grep assisted-installer config/configmaps/openshift-config/openshift-install-manifests/invoker >/dev/null 2>&1; then
      echo "Install Type: Assisted Installer"
  else
      echo "Install Type: $2"
  fi

  if [ -f config/network.json ]; then
    echo "NetworkType: $(jq -r '.spec.networkType' config/network.json)"
  else
    echo "NetworkType: Information Missing"
  fi

  if [ -f config/proxy.json ]; then
    echo "Proxy Configured:"
    echo "  HTTP: $(jq -r '.spec | has("httpProxy")' config/proxy.json)"
    echo "  HTTPS: $(jq -r '.spec | has("httpsProxy")' config/proxy.json)"
  fi

  ipi_info

  if [ -f config/apiserver.json ];
  then
    if $(jq -r '.spec | has("encryption.type")' config/apiserver.json)
    then
      if $(jq -r '.spec.encryption.type | contains("aescbc")' config/apiserver.json)
      then
        echo "etcd Encryption: AES-CBC"
      else $(jq -r '.spec.encryption.type | contains("aesgcm")' config/apiserver.json)
        echo "etcd Encryption: AES-GCM"
      fi
    else
      echo "etcd Encryption: None"
    fi

    echo "Audit Profile: $(jq -r '.spec.audit.profile' config/apiserver.json)"
    printf "\n"

  fi

  node_status

  clusteroperator_status

  installed_operators

  olm_operators

  machineconfigpool_info

  machineset_info

  if [ "$sc_info" = "true" ]; then
    storageclasses
  fi

  ocp_ns_memory

  if [ "$customer_memory" = "true" ]; then
    customer_ns_memory
  fi

  failing_pods

  namespace_events

  alerts

  if [ "$uids" = "true" ]; then
    uid_overlap
  fi

  podnetcheck

  exit 0

}

show_help(){

  cat  << ENDHELP
USAGE: $(basename "$0")

Displays information obtained from the latest Insights data for the cluster ID provided.

Options:
      --all                       Lists all of the following options
        --customer_memory         Lists memory usage for non-OpenShift Cluster Namespaces
        --uid                     Lists Namespaces with overlapping UIDs
        --storage_classes         Lists Storage Class information
      --file                      Run the script against a specific insights file
                                    E.g.: $(basename "$0") --file ~/insights_archive.tar.gz
      --etcd_metrics              Returns metrics from Insights Metrics Data
  -h, --help                      Shows this help message.

ENDHELP

}

main(){

  parse_args "$@"
  run

}

is_local=false
force_update=false
run_clean=false
cluster_id=""
work_dir=""
data_src_path=/ocp

main "$@"
