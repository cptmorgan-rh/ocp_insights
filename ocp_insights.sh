#!/bin/bash

extract_data(){

insights_operator_pod=$(oc get pods --namespace=openshift-insights -o custom-columns=:metadata.name --no-headers --field-selector=status.phase=Running)

if [ -n "$insights_operator_pod" ]
then

 for i in insights-data extracted-data; do
   mkdir -p ./$i
 done
 oc cp openshift-insights/${insights_operator_pod}:var/lib/insights-operator/ ./insights-data
else
 printf "Insights Operator Pod Not Found or Not Running\n"
 exit 127
fi

archive=$(ls -A ./insights-data | tail -n1)
extract_dir=./extracted-data/${archive:0:-7}
mkdir -p ${extract_dir}
tar xzf ./insights-data/${archive} -C ${extract_dir}

ocp_platform

}

ocp_platform(){

  platform=$(jq -r '.status.platformStatus.type' ${extract_dir}/config/infrastructure.json)

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

    IBMCloud)
      pltf_ibmcloud "$platform"
      ;;

    None)
      pltf_none
      ;;
      
    *)
      echo "Unknown Platform."
      pltf_none
  esac

}

pltf_ovirt() {

  if $(jq -r '.status.platformStatus | has("ovirt")' ${extract_dir}/config/infrastructure.json);
  then
    install_type="IPI"
    api_internal_ip=$(jq -r '.status.platformStatus.ovirt.apiServerInternalIP' ${extract_dir}/config/infrastructure.json)
    ingressip=$(jq -r '.status.platformStatus.ovirt.ingressIP' ${extract_dir}/config/infrastructure.json)
  else
    install_type="UPI"
  fi

  network_info
  output "$1" "${install_type}"
  printf "\n"

}

pltf_aws() {

  if $(jq -r '.status.platformStatus | has("aws")' ${extract_dir}/config/infrastructure.json);
  then
    install_type="IPI"
    aws_region=$(jq -r '.status.platformStatus.aws.region' ${extract_dir}/config/infrastructure.json )
  else
    install_type="UPI"
  fi

  network_info
  output "$1" "${install_type}"
  printf "\n"

}

pltf_azure() {

  if $(jq -r '.status.platformStatus | has("azure")' ${extract_dir}/config/infrastructure.json);
  then
    install_type="IPI"
    azure_resourcegroupname=$(jq -r '.status.platformStatus.azure.resourceGroupName' ${extract_dir}/config/infrastructure.json)
    azure_networkresourcegroupname=$(jq -r '.status.platformStatus.azure.networkResourceGroupName' ${extract_dir}/config/infrastructure.json)
    azure_cloudname=$(jq -r '.status.platformStatus.azure.cloudName' ${extract_dir}/config/infrastructure.json)
  else
    install_type="UPI"
  fi

  network_info
  output "$1" "${install_type}"
  printf "\n"

}

pltf_baremetal() {

  if $(jq -r '.status.platformStatus | has("baremetal")' ${extract_dir}/config/infrastructure.json);
  then
    install_type="IPI"
    api_internal_ip=$(jq -r '.status.platformStatus.baremetal.apiServerInternalIP' ${extract_dir}/config/infrastructure.json)
    ingressip=$(jq -r '.status.platformStatus.baremetal.ingressIP' ${extract_dir}/config/infrastructure.json)
  else
    install_type="UPI"
  fi

  network_info
  output "$1" "${install_type}"
  printf "\n"

}

pltf_gcp() {

  if $(jq -r '.status.platformStatus | has("gcp")' ${extract_dir}/config/infrastructure.json);
  then
    install_type="IPI"
    gcp_projectid=$(jq -r '.status.platformStatus.gcp.projectID' ${extract_dir}/config/infrastructure.json)
    gcp_region=$(jq -r '.status.platformStatus.gcp.region' ${extract_dir}/config/infrastructure.json)
  else
    install_type="UPI"
  fi

  network_info
  output "$1" "${install_type}"
  printf "\n"

}

pltf_openstack() {

  if $(jq -r '.status.platformStatus | has("openstack")' ${extract_dir}/config/infrastructure.json);
  then
    install_type="IPI"
    api_internal_ip=$(jq -r '.status.platformStatus.openstack.apiServerInternalIP' ${extract_dir}/config/infrastructure.json)
    ingressip=$(jq -r '.status.platformStatus.openstack.ingressIP' ${extract_dir}/config/infrastructure.json)
    nodeDNSIP=$(jq -r '.status.platformStatus.openstack.nodeDNSIP' ${extract_dir}/config/infrastructure.json)
  else
    install_type="UPI"
  fi

  network_info
  output "$1" "${install_type}"
  printf "\n"

}

pltf_vsphere() {

  if $(jq -r '.status.platformStatus | has("vsphere")' ${extract_dir}/config/infrastructure.json);
  then
    install_type="IPI"
    api_internal_ip=$(jq -r '.status.platformStatus.vsphere.apiServerInternalIP' ${extract_dir}/config/infrastructure.json)
    ingressip=$(jq -r '.status.platformStatus.vsphere.ingressIP' ${extract_dir}/config/infrastructure.json)
  else
    install_type="UPI"
  fi

  network_info
  output "$1" "${install_type}"
  printf "\n"

}

pltf_nutanix() {

  if $(jq -r '.status.platformStatus | has("nutanix")' ${extract_dir}/config/infrastructure.json);
  then
    install_type="IPI"
    api_internal_ip=$(jq -r '.status.platformStatus.nutanix.apiServerInternalIP' ${extract_dir}/config/infrastructure.json)
    ingressip=$(jq -r '.status.platformStatus.nutanix.ingressIP' ${extract_dir}/config/infrastructure.json)
  else
    install_type="UPI"
  fi

  network_info
  output "$1" "${install_type}"
  printf "\n"

}

pltf_ibmcloud() {

  if $(jq -r '.status.platformStatus | has("ibmcloud")' config/infrastructure.json);
  then
    install_type="IPI"
    api_internal_ip=$(jq -r '.status.platformStatus.ibmcloud.apiServerInternalIP' config/infrastructure.json)
    ingressip=$(jq -r '.status.platformStatus.ibmcloud.ingressIP' config/infrastructure.json)
  else
    if $(grep ROKS config/configmaps/openshift-config/openshift-install/invoker >/dev/null 2>&1)
    then
      install_type="HyperShift"
    else
      install_type="UPI"
    fi
  fi

  network_info
  output "$1" "${install_type}"
  printf "\n"

}

pltf_none() {

  network_info
  output "No Platform Provided" "UPI"
  printf "\n"

}

ipi_info() {

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
  if [ -n "$azure_cloudname" ]; then
    echo "Azure Cloud: $azure_cloudname"
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

node_status() {

  nodes_arr=("NAME|READY|ROLE|CREATED_ON|VERSION|OS")
  for i in ${extract_dir}/config/node/*.json;
  do nodes_arr+=("$(jq -r '[.metadata.name, (.status.conditions[] | select(.type == "Ready") | .status), (.metadata.labels|with_entries(select(.key|match("node-role.kubernetes.io")))|keys|map(split("/")[1])|join(",")), .metadata.creationTimestamp, .status.nodeInfo.kubeletVersion, .status.nodeInfo.osImage] | join("|")' "$i")");
  done
  printf '%s\n' "${nodes_arr[@]}" | column -t -s '|'
  printf "\n"

  unset nodes_arr

}

clusteroperator_status() {

  clusteroperator_arr=("NAME|VERSION|AVAILABLE|PROGRESSING|DEGRADED")
  for i in ${extract_dir}/config/clusteroperator/*.json;
  do clusteroperator_arr+=("$(jq -r '[.metadata.name, (.status.versions[] | select(.name == "operator") | .version), (.status.conditions[] | select(.type == "Available") | .status), (.status.conditions[] | select(.type == "Degraded") | .status), (.status.conditions[] | select(.type == "Progressing") | .status)] | join("|")' "$i")");
  done
  printf '%s\n' "${clusteroperator_arr[@]}" | column -t -s '|'
  printf "\n"

  unset clusteroperator_arr

}

installed_operators() {

  if [ -f "${extract_dir}/config/installplans.json" ];
  then
    installed_operator_count=$(jq -r .stats.TOTAL_COUNT ${extract_dir}/config/installplans.json)
    if [[ $installed_operator_count != "0" ]];
    then
      echo -e "Installed Operators:"
      printf "\n"
      for i in $(jq -r '.items[].csv' ${extract_dir}/config/installplans.json | sort -u); do
        printf "%s$i\n"
      done
      printf '\n'
    fi
  fi

}

namespace_events() {

  # Get events with data
  if [ -d "${extract_dir}/events/" ];
  then
    for i in ${extract_dir}/events/*.json; do
      if grep namespace "$i" >/dev/null 2>&1;
      then
        namespace_arr+=($(echo "$i" | awk -F/ '{ print $NF }'  | cut -f 1 -d '.'))
      fi
    done

    printf "Last message from each namespace with events:\n\n"

    for i in "${namespace_arr[@]}";
    do
      printf "To see all events for ${i} run: jq -r . ${extract_dir}/events/$i.json\n"
      printf "\n"
      echo "Namespace: $(jq -r '.items[-1].namespace' ${extract_dir}/events/$i.json)"
      echo "Last Timestamp: $(jq -r '.items[-1].lastTimestamp' ${extract_dir}/events/$i.json)"
      echo "Reason: $(jq -r '.items[-1].reason' ${extract_dir}/events/$i.json)"
      echo "Message: $(jq -r '.items[-1].message' ${extract_dir}/events/$i.json)"
      printf "\n"
    done
  fi

  unset namespace_arr

}

network_info() {

  networktype=$(jq -r '.spec.networkType' ${extract_dir}/config/network.json)
  httpproxy=$(jq -r '.spec | has("httpProxy")' ${extract_dir}/config/proxy.json)
  httpsproxy=$(jq -r '.spec | has("httpsProxy")' ${extract_dir}/config/proxy.json)

}

cluster_version() {

  cluster_ver=$(jq -r '.status.desired.version' ${extract_dir}/config/version.json)
  cluster_channel=$(jq -r '.spec.channel' ${extract_dir}/config/version.json)
  last_completed=$(jq -r '(.status.history[] | select(.state == "Completed") | .version)' ${extract_dir}/config/version.json)

  echo "Cluster Version: $cluster_ver"
  echo "Channel: $cluster_channel"
  echo "Previous Version(s): $last_completed"

  cluster_up_fail=$(jq -r '.status.conditions[] | select(.type == "Failing" and .status == "True") | .status' ${extract_dir}/config/version.json)

  if [[ "$cluster_up_fail" == "True" ]]; then
    printf "\n"
    echo "Cluster Status: Failing"
    echo "Reason: $(jq -r '.status.conditions[] | select(.type == "Failing" and .status == "True") | .reason' ${extract_dir}/config/version.json)"
    echo "Message: $(jq -r '.status.conditions[] | select(.type == "Failing" and .status == "True") | .message' ${extract_dir}/config/version.json)"
  fi

}

machineconfigpool_info() {

  if [ -d "${extract_dir}/config/machineconfigpools/" ];
  then
    machineconfigpool_arr=("NAME|CONFIG|UPDATED|UPDATING|DEGRADED|MACHINECOUNT|READYMACHINECOUNT|UPDATEDMACHINECOUNT|DEGRADEDMACHINECOUNT")
    for i in ${extract_dir}/config/machineconfigpools/*.json; do machineconfigpool_arr+=("$(jq -r '[.metadata.name, .spec.configuration.name, (.status.conditions[] | select(.type == "Updated") | .status), (.status.conditions[] | select(.type == "Updating") | .status), (.status.conditions[] | select(.type == "Degraded") | .status), .status.machineCount, .status.readyMachineCount, .status.updatedMachineCount, .status.degradedMachineCount ] | join("|")' $i)") ; done
    printf '%s\n' "${machineconfigpool_arr[@]}" | column -t -s '|'
    printf "\n"
  fi

  unset machineconfigpool_arr

}

machineset_info() {

  machineset_arr=("NAME|DESIRED|CURRENT|READY|AVAILABLE")
  if [ -d "machinesets/openshift-machine-api" ];
  then
    for i in machinesets/openshift-machine-api/*.json;
    do machineset_arr+=("$(jq -r '[.metadata.name, .spec.replicas, .status.replicas, .status.readyReplicas, .status.availableReplicas ] | join("|")' "$i")") ; done
    printf '%s\n' "${machineset_arr[@]}" | column -t -s '|'
    printf "\n"
  fi

  if compgen -G "machinesets/*.json" >/dev/null 2>&1;
  then
    for i in machinesets/*.json;
    do machineset_arr+=("$(jq -r '[.metadata.name, .spec.replicas, .status.replicas, .status.readyReplicas, .status.availableReplicas ] | join("|")' "$i")") ; done
    printf '%s\n' "${machineset_arr[@]}" | column -t -s '|'
    printf "\n"
  fi

}

failing_pods() {

  if [ -d "${extract_dir}/config/pod/" ];
  then
    failing_pods_arr=("NAMESPACE|POD NAME|REASON")
    for i in ${extract_dir}/config/pod/*/*.json; do
      pods_arr+=("$(jq -r '[(select(.status.conditions[] | select(.type == "Ready" and .status == "False")) | .metadata.namespace), (select(.status.conditions[] | select(.type == "Ready" and .status == "False")) | .metadata.name), (.status.conditions[] | select(.type == "Ready" and .status == "False").message)] | join("|")' $i)")
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
      printf "Pods with errors.\n"
      printf '%s\n' "${failing_pods_arr[@]}" | column -t -s '|'
      printf "\n"
    fi

    unscheduled_pods_arr=("NAMESPACE|POD NAME|REASON")
    for i in ${extract_dir}/config/pod/*/*.json; do
      pods_arr+=("$(jq -r '[(select(.status.conditions[] | select(.type == "PodScheduled" and .status == "False")) | .metadata.namespace), (select(.status.conditions[] | select(.type == "PodScheduled" and .status == "False")) | .metadata.name),  (.status.conditions[] | select(.type == "PodScheduled" and .status == "False").message)] | join("|")' $i)");
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
      printf "Pods failing to Schedule.\n"
      printf '%s\n' "${unscheduled_pods_arr[@]}" | column -t -s '|'
      printf "\n"
    fi
  fi

    restarting_pods_arr=("NAMESPACE|POD NAME|CONTAINER|RESTARTS")
    for i in $(ls -d ${extract_dir}/config/pod/*/*.json); do
        for x in $(jq -r '.status.containerStatuses[] | select(.restartCount > 3) | .name' "$i"); do
            pods_arr+=("$(jq -r "[.metadata.namespace, .metadata.name, (.status.containerStatuses[] | select(select(.name == \"$x\" and .restartCount > 3)) | .name, .restartCount)] | join(\"|\")" "$i")")
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
      printf "Containers with more than 3 restarts.\n"
      printf '%s\n' "${restarting_pods_arr[@]}" | column -t -s '|'
      printf "\n"
    fi

  unset pods_arr
  unset failing_pods_arr
  unset unscheduled_pods_arr
  unset restarting_pods_arr

}

output() {

  printf "\n"
  cluster_version
  printf "\n"

  echo "Platform: $1"
  echo "Install Type: $2"
  echo "NetworkType: $networktype"
  echo "Proxy Configured:"
  echo "  HTTP: $httpproxy"
  echo "  HTTPS: $httpsproxy"

  ipi_info

  node_status

  clusteroperator_status

  installed_operators

  machineconfigpool_info

  machineset_info

  failing_pods

  namespace_events

  exit 0

}

extract_data