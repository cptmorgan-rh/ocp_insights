#!/usr/bin/env python3
"""OCP Insights script."""

import argparse
import json
import re
import sys
import tarfile
import uuid
from datetime import datetime
from pathlib import Path
from typing import Optional

# Constants
OCP_BASE_PATH = "/ocp"
DEFAULT_MEMORY_THRESHOLD = 1024**3  # 1GB in bytes
MEMORY_CONVERSION_MB = 1024**2
MEMORY_CONVERSION_GB = 1024**3
RESTART_THRESHOLD = 3
OPENSHIFT_NAMESPACES_PATTERN = r"^(openshift|default|kube-[snp])"


def validate_clusterid(clusterid: str) -> bool:
    """Validates that the clusterid is a valid UUID.

    Args:
        clusterid (str): UUID of the OpenShift Cluster

    Returns:
        bool: True or False based on validity of the UUID
    """
    try:
        _ = uuid.UUID(clusterid)
        return True
    except ValueError:
        return False


def find_cluster_path(clusterid: str) -> Optional[str]:
    """Finds the path of the Cluster.

    Args:
        clusterid (str): UUID of the OpenShift Cluster

    Returns:
        Optional[str]: Path of the Cluster or None if not found
    """
    try:
        # Use pathlib to find cluster directories
        ocp_path = Path(OCP_BASE_PATH)
        if not ocp_path.exists():
            return None

        for subdirectory in ocp_path.iterdir():
            if subdirectory.is_dir() and subdirectory.name != "None":
                cluster_path = subdirectory / clusterid
                if cluster_path.exists():
                    return str(cluster_path)

    except (OSError, PermissionError):
        return None  # Return None if the command fails

    return None  # Return None if no valid path is found


def find_newest_file(directory: str) -> Optional[str]:
    """Finds the newest file in the specified directory.

    Args:
        directory (str): Directory to search for files.

    Returns:
        Optional[str]: The path of the newest file, or None if no files are found.
    """
    dir_path = Path(directory)

    try:
        newest_file = max(
            (file for file in dir_path.rglob("*") if file.is_file()),
            key=lambda f: f.stat().st_mtime,
            default=None,
        )
        return str(newest_file) if newest_file else None
    except (OSError, PermissionError):
        return None



def list_cluster_archives(cluster_id: str) -> list:
    """Lists all available archives for a specific cluster.

    Args:
        cluster_id (str): UUID of the OpenShift Cluster

    Returns:
        list: List of dictionaries containing archive information with keys:
              'file_path', 'checkin_time', 'file_size'
    """
    archives = []
    cluster_path = find_cluster_path(cluster_id)

    if not cluster_path:
        return archives

    try:
        cluster_dir = Path(cluster_path)
        if not cluster_dir.exists():
            return archives

        # Find all files in the cluster directory
        for file_path in cluster_dir.rglob("*"):
            if file_path.is_file():
                try:
                    # Get both the formatted time and the datetime object for sorting
                    file_name = file_path.name
                    check_in_string = file_name.split("-")[0]
                    check_in_date = datetime.strptime(check_in_string, "%Y%m%d%H%M%S")
                    checkin_time = check_in_date.strftime("%a %b %d %I:%M:%S %p UTC %Y")

                    archives.append({
                        'file_path': str(file_path),
                        'checkin_time': checkin_time,
                        'checkin_datetime': check_in_date,  # For sorting
                        'file_name': file_path.name
                    })
                except Exception:
                    # Skip files with invalid formats
                    continue

    except (OSError, PermissionError) as e:
        print(f"Error accessing cluster directory: {e}")
        return archives

    # Sort by checkin datetime (newest first)
    archives.sort(key=lambda x: x['checkin_datetime'], reverse=True)
    return archives


def extract_cluster_archive(cluster_id: str, cluster_path: str, specific_file: str = None) -> bool:
    """Extracts an archive for a cluster to the user's home directory.

    Args:
        cluster_id (str): UUID of the OpenShift Cluster
        cluster_path (str): Path to the cluster directory
        specific_file (str, optional): Specific archive file to extract. If None, uses newest file.

    Returns:
        bool: True if extraction was successful, False otherwise
    """
    try:
        # Use specific file if provided, otherwise find the newest file
        if specific_file:
            archive_file = specific_file
        else:
            archive_file = find_newest_file(cluster_path)
            if not archive_file:
                print(f"No archive files found for cluster {cluster_id}.")
                return False

        # Get user's home directory
        home_dir = Path.home()

        # Get the archive name without extension
        archive_name = Path(archive_file).stem  # Gets filename without .tar.gz
        if archive_name.endswith('.tar'):  # Handle .tar.gz case
            archive_name = archive_name[:-4]  # Remove .tar part

        # Strip the first '/' from cluster_path and create the extraction path
        # cluster_path is something like "/ocp/subdirectory/cluster_id"
        # We want to create "~/subdirectory/cluster_id/archive_name"
        relative_path = cluster_path.lstrip('/')  # Remove leading '/'
        extract_path = home_dir / relative_path / archive_name

        # Create the directory structure if it doesn't exist
        extract_path.mkdir(parents=True, exist_ok=True)

        # Open and extract the tar file
        print(f"Destination: {extract_path}")

        with tarfile.open(archive_file, "r:gz") as tar:
            # Extract all files to the destination directory safely
            # This addresses the CVE-2007-4559 security warning
            def safe_extract(tar, path):
                for member in tar.getmembers():
                    # Ensure the member path is safe
                    if member.isfile() or member.isdir():
                        # Normalize the path and ensure it's within the extraction directory
                        member_path = Path(path) / member.name
                        if str(member_path.resolve()).startswith(str(Path(path).resolve())):
                            tar.extract(member, path, filter='fully_trusted')

            safe_extract(tar, extract_path)

        return True

    except (tarfile.TarError, OSError, PermissionError) as e:
        print(f"Error extracting archive: {e}")
        return False
    except Exception as e:
        print(f"Unexpected error during extraction: {e}")
        return False


def display_archive_menu(cluster_id: str, archives: list) -> Optional[str]:
    """Displays an interactive menu for archive selection for a specific cluster.

    Args:
        cluster_id (str): The cluster ID
        archives (list): List of archive dictionaries from list_cluster_archives()

    Returns:
        Optional[str]: Selected archive file path, or None if cancelled
    """
    if not archives:
        print(f"No archives found for cluster {cluster_id}.")
        return None

    print(f"\nAvailable Archives for Cluster: {cluster_id}")
    print("=" * 80)
    print(f"{'#':<3} {'Check-in Time':<30} {'File Name'}")
    print("-" * 80)

    for i, archive in enumerate(archives, 1):
        print(f"{i:<3} {archive['checkin_time']:<30} {archive['file_name']}")

    print("-" * 80)
    print("0   Exit")
    print()

    while True:
        try:
            choice = input("Select an archive to analyze (enter number): ").strip()

            if choice == '0':
                print("Exiting...")
                return None

            choice_num = int(choice)
            if 1 <= choice_num <= len(archives):
                selected_archive = archives[choice_num - 1]
                print(f"\nSelected archive: {selected_archive['file_name']}")
                return selected_archive['file_path']
            else:
                print(f"Please enter a number between 0 and {len(archives)}")

        except ValueError:
            print("Please enter a valid number")
        except KeyboardInterrupt:
            print("\nExiting...")
            return None


def read_insights_file(file_path: str) -> tarfile.TarFile:
    """Reads the insights tar file.

    Args:
        file_path (str): Path to the file.

    Returns:
        tarfile.TarFile: Returns Insights Archive as a tarfile.
    """
    try:
        # Open the tar file in read mode
        return tarfile.open(file_path, "r:gz")
    except (tarfile.TarError, FileNotFoundError) as e:
        print(f"Unable to open {file_path}: {e}")
        sys.exit(1)


def check_in_time(file_path: str) -> str:
    """Get Check-in Time based on File Name.

    Args:
        file_path (str): Path to the file.

    Returns:
        str: Check-in time in "%a %b %d %I:%M:%S %p UTC %Y" format.
    """
    file_name = Path(file_path).name
    check_in_string = file_name.split("-")[0]

    # Parse the check-in date from the filename
    check_in_date = datetime.strptime(check_in_string, "%Y%m%d%H%M%S")

    # Format the date to the desired string format
    return check_in_date.strftime("%a %b %d %I:%M:%S %p UTC %Y")


def parse_version_file(
    tar: tarfile.TarFile,
) -> tuple:
    """Parses the version file for Version, Channel, Install History, and Failing Reason.

    Args:
        tar (tarfile.TarFile): Insights Archive.

    Returns:
        tuple: Cluster ID, Version, Channel, Install History, Partial Install History,
            Failing Reason, and Failing Message.
    """
    with tar.extractfile("config/version.json") as version_file:
        version_json = json.load(version_file)

    cluster_id = version_json["spec"]["clusterID"]
    version = version_json["status"]["desired"]["version"]
    # Get Update Channel, if not present set to N/A
    channel = version_json["spec"].get("channel", "N/A")

    install_history = version_json.get("status", {}).get("history", [])
    all_installs = [entry.get("version") for entry in install_history if entry.get("version")]
    partial_installs = [
        entry.get("version")
        for entry in install_history
        if entry.get("state") == "Partial" and entry.get("version")
    ]

    failing_reason: str = ""
    failing_message: str = ""
    for condition in version_json["status"].get("conditions", []):
        if condition["type"] == "Failing" and condition["status"] == "True":
            failing_reason = condition.get("reason", "")
            failing_message = condition.get("message", "")

    return (
        cluster_id,
        version,
        channel,
        all_installs,
        partial_installs,
        failing_reason,
        failing_message,
    )


def parse_infra_file(tar: tarfile.TarFile, tar_files: list) -> tuple:
    """Parses Infrastructure file for Platform and Install Type

    Args:
        tar (tarfile.TarFile): Insights Archive

    Returns:
        Tuple[str, str]: Platform and Version
    """
    install_method: str = "Unknown"
    infra_file = tar.extractfile("config/infrastructure.json")
    infra_json = json.loads(infra_file.read().decode("utf-8"))
    platform = infra_json["status"]["platform"]
    # Get cluster name - use etcdDiscoveryDomain if available, otherwise use apiServerURL
    etcd_domain = infra_json["status"].get("etcdDiscoveryDomain", "")
    if etcd_domain:
        cluster_name = etcd_domain
    else:
        api_server_url = infra_json["status"]["apiServerURL"]
        # Remove https://api. prefix and :6443 suffix from apiServerURL
        cluster_name = api_server_url.replace("https://api.", "").replace(":6443", "")
    install_method = "UPI"  # Default installation method
    for file in tar_files:
        if "invoker" in file:
            invoker_content = tar.extractfile(file).read().decode("utf-8")
            # Define a mapping of keywords to installation methods
            install_method_map = {
                "assisted-installer": "Assisted Installer",
                "ROKS": "ROKS",
                "hypershift": "HyperShift",
            }
            # Check for known installation methods in the invoker content
            for installer, method in install_method_map.items():
                if installer in invoker_content:
                    install_method = method
                    break
            else:
                # Check platform status if no keyword matched
                if platform.lower() in infra_json["status"]["platformStatus"]:
                    install_method = "IPI"
            break  # Exit the loop after processing the invoker file

    return platform, cluster_name, install_method


def parse_network_file(tar: tarfile.TarFile) -> str:
    """Parses Network file for Network Type

    Args:
        tar (tarfile.TarFile): Insights Archive

    Returns:
        str: Network Type (OVNKubernetes, OpenShiftSDN, Calico)
    """
    network_file = tar.extractfile("config/network.json")
    network_json = json.loads(network_file.read().decode("utf-8"))
    network_type = network_json["spec"]["networkType"]

    return network_type


def parse_proxy_file(tar: tarfile.TarFile) -> tuple:
    """Parses Proxy file for HTTP/HTTPS Proxy information

    Args:
        tar (tarfile.TarFile): Insights Archive

    Returns:
        Tuple: HTTP, HTTP Proxy status
    """
    proxy_file = tar.extractfile("config/proxy.json")
    proxy_json = json.loads(proxy_file.read().decode("utf-8"))

    httpproxy = False
    if "httpProxy" in proxy_json["spec"]:
        httpproxy = True

    httpsproxy = False
    if "httpsProxy" in proxy_json["spec"]:
        httpsproxy = True

    return httpproxy, httpsproxy


def parse_apiserver_file(tar: tarfile.TarFile) -> tuple:
    """Parses the apiserver file.

    Args:
        tar (tarfile.TarFile): Insights Archive.

    Returns:
        tuple: Etcd Encryption Method (or None) and Audit Profile.
    """
    api_file = tar.extractfile("config/apiserver.json")
    api_json = json.loads(api_file.read().decode("utf-8"))

    # Use a dictionary to map encryption types for better readability
    encryption_map = {"aescbc": "AES-CBC", "aesgcm": "AES-GCM"}

    # Get the encryption type, defaulting to None if not found
    encryption_type = api_json["spec"]["encryption"].get("type", "None")
    etcd_encryption = encryption_map.get(encryption_type, "None")

    audit_profile = api_json["spec"]["audit"]["profile"]

    return etcd_encryption, audit_profile


def parse_node_files(tar: tarfile.TarFile, file_list: list) -> list:
    """Parses Node Files and returns information about nodes

    Args:
        tar (tarfile.TarFile): Insights Archive
        file_list (List): List of files the match regex from file_files function

    Returns:
        List: Sorted List of dictionaries containing Node Name, Status, Role,
        Creation Date, Kubelet Version, OS Image, CPU Count, and Memory Capacity in GB.
    """
    node_info: list = []
    for file in file_list:
        node = tar.extractfile(file)
        node_json = json.loads(node.read().decode("utf-8"))
        node_name = node_json["metadata"]["name"]
        node_status = next(
            (
                condition["status"]
                for condition in node_json["status"]["conditions"]
                if condition["type"] == "Ready"
            ),
            "",
        )
        node_roles = ",".join(
            [
                key.split("/")[1]
                for key in node_json["metadata"]["labels"]
                if "node-role.kubernetes.io/" in key
            ]
        )
        node_creation_date = node_json["metadata"]["creationTimestamp"]
        node_kubelet_version = node_json["status"]["nodeInfo"]["kubeletVersion"]
        node_os_image = node_json["status"]["nodeInfo"]["osImage"]
        node_cpu_count = node_json["status"]["capacity"]["cpu"]
        node_mem_capacity_raw = node_json["status"]["capacity"]["memory"]
        node_mem_capacity = round(int(node_mem_capacity_raw[:-2]) / MEMORY_CONVERSION_MB)
        node_info.append(
            {
                "NAME": node_name,
                "READY": node_status,
                "ROLE": node_roles,
                "CREATED ON": node_creation_date,
                "VERSION": node_kubelet_version,
                "OS": node_os_image,
                "CPU": node_cpu_count,
                "MEMORY": f"{node_mem_capacity} GB",
            }
        )

    if not node_info:
        return []

    # Set priority of Node Roles
    role_priority = {
        "master": 1,
        "control-plane": 1,
        "control-plane,master": 1,
        "infra": 2,
        "infra,worker": 3,
        "storage": 4,
        "compute": 5,
        "worker": 5,
    }

    # Sort based on Role for cleaner output to ensure master/control plane is first
    return sorted(
        reversed(node_info), key=lambda x: role_priority.get(x["ROLE"], 6)
    )


def parse_cluster_operator_files(tar: tarfile.TarFile, file_list: list) -> Optional[list]:
    """Parses Cluster Operator Files and returns information about them.

    Args:
        tar (tarfile.TarFile): Insights Archive.
        file_list (List[str]): List of files that match regex from file_files function.

    Returns:
        Optional[List[Dict[str, Optional[str]]]]: Information about cluster operators or None
        if no Cluster Operators found.
    """
    cluster_operator_info: list = []

    for file in file_list:
        with tar.extractfile(file) as cluster_operator:
            co_json = json.load(cluster_operator)

        co_name = co_json["metadata"]["name"]
        co_version = next(
            (
                version["version"]
                for version in co_json["status"]["versions"]
                if version["name"] == "operator"
            ),
            None,
        )
        conditions = {
            condition["type"]: condition["status"]
            for condition in co_json["status"]["conditions"]
        }

        cluster_operator_info.append(
            {
                "NAME": co_name,
                "VERSION": co_version,
                "AVAILABLE": conditions.get("Available"),
                "PROGRESSING": conditions.get("Progressing"),
                "DEGRADED": conditions.get("Degraded"),
            }
        )

    if not cluster_operator_info:
        return None

    print("\nCluster Operators:")
    return sorted(cluster_operator_info, key=lambda x: x["NAME"])


def parse_install_plans(tar: tarfile.TarFile) -> Optional[list]:
    """Parses Install Plans File.

    Args:
        tar (tarfile.TarFile): Insights Archive.

    Returns:
        Optional[List[Dict[str, str]]]: List containing Operator Name and Namespace,
        or None if no install plans are found.
    """
    try:
        with tar.extractfile("config/installplans.json") as installplans_file:
            installplan_json = json.load(installplans_file)

        # Check if there are any install plans before continuing
        if installplan_json["stats"]["TOTAL_COUNT"] == 0:
            return None

        install_plans_info = [
            {"CSV": item["csv"], "NAMESPACE": item["ns"]}
            for item in installplan_json["items"]
        ]

        print("\nInstall Plans:")
        return sorted(install_plans_info, key=lambda x: x["CSV"])

    except KeyError:
        # Some clusters do not have this file resulting in a KeyError
        return None


def parse_olm_operators(tar: tarfile.TarFile) -> Optional[list]:
    """Parses OLM Operators file for Name, DisplayName, Version, and Namespace.

    Args:
        tar (tarfile.TarFile): Insights Archive.

    Returns:
        Optional[List[Dict[str, str]]]: List of dictionaries containing Name, DisplayName,
        Version, and Namespace, or None if no operators are found.
    """
    with tar.extractfile("config/olm_operators.json") as olm_file:
        olm_json = json.load(olm_file)

    # Return None if olm_json is empty
    if not olm_json:
        return None

    olm_operators_info: list = [
        {
            "NAME": full_name.split(".")[0],
            "DISPLAY NAME": item["displayName"],
            "VERSION": item["version"],
            "NAMESPACE": full_name.split(".")[1],
        }
        for item in olm_json
        for full_name in [item["name"]]
    ]

    print("\nInstalled OLM Operators:")
    return sorted(olm_operators_info, key=lambda x: x["NAME"])


def parse_machineconfigpools(tar: tarfile.TarFile, file_list: list) -> list:
    """Parses MachineconfigPools to return information matching oc cli output

    Args:
        tar (tarfile.TarFile): Insights Archive
        file_list (List[str]): List of files the match regex from file_files function

    Returns:
        List[Dict[str, Any]]: List including Name, Config, Updated, Updating, Degraded
        MachineCount, ReadyMachineCount, and UpdatedMachineCount of MachineConfigPool
    """
    mcp_info: list = [
        {
            "NAME": mcp_json["metadata"]["name"],
            "CONFIG": mcp_json["spec"]["configuration"]["name"],
            "UPDATED": next(
                (
                    condition["status"]
                    for condition in mcp_json["status"]["conditions"]
                    if condition["type"] == "Updated"
                ),
                "0",
            ),
            "UPDATING": next(
                (
                    condition["status"]
                    for condition in mcp_json["status"]["conditions"]
                    if condition["type"] == "Updating"
                ),
                "0",
            ),
            "DEGRADED": next(
                (
                    condition["status"]
                    for condition in mcp_json["status"]["conditions"]
                    if condition["type"] == "Degraded"
                ),
                "0",
            ),
            "MACHINECOUNT": mcp_json["status"]["machineCount"],
            "READYMACHINECOUNT": mcp_json["status"]["readyMachineCount"],
            "UPDATEDMACHINECOUNT": mcp_json["status"]["updatedMachineCount"],
            "DEGRADEDMACHINECOUNT": mcp_json["status"]["degradedMachineCount"],
        }
        for file in file_list
        if (machineconfigpool := tar.extractfile(file))
        and (mcp_json := json.loads(machineconfigpool.read().decode("utf-8")))
    ]

    if mcp_info:
        print("\nMachineConfigPools:")
        return list(reversed(mcp_info))

    return mcp_info


def parse_machinesets(tar: tarfile.TarFile, file_list: list) -> list:
    """If MachineSet files exist, print out name, desired, current, ready, and available.

    Args:
        tar (tarfile.TarFile): Insights Archive
        file_list (List[str]): List of files that match regex from file_files function

    Returns:
        List[Dict[str, Any]]: List of MachineSet information.
    """
    machinesets_info: list = [
        {
            "NAME": machineset_json["metadata"]["name"],
            "DESIRED": machineset_json["spec"]["replicas"],
            "CURRENT": machineset_json["status"]["replicas"],
            "READY": machineset_json["status"].get("readyReplicas", "0"),
            "AVAILABLE": machineset_json["status"].get("availableReplicas", "0"),
        }
        for file in file_list
        if (machineset := tar.extractfile(file))
        and (machineset_json := json.loads(machineset.read().decode("utf-8")))
    ]

    if machinesets_info:
        print("\nMachineSets:")

    return machinesets_info


def parse_storageclasses(tar: tarfile.TarFile, file_list: list) -> list:
    """Parses StorageClasses if they exist in the Insights Archive

    Args:
        tar (tarfile.TarFile): Insights Archive
        file_list (List[str]): List of files that match regex from file_files function

    Returns:
        Optional[List[Dict[str, str]]]: A List of dictionaries containing name, provisioner,
        reclaim policy, binding mode, and volume expansion settings for storage class.
    """
    storageclass_info: list = [
        {
            "NAME": storageclass_json["metadata"]["name"],
            "PROVISIONER": storageclass_json["provisioner"],
            "RECLAIM POLICY": storageclass_json["reclaimPolicy"],
            "BINDING MODE": storageclass_json["volumeBindingMode"],
            "VOLUME EXPANSION": storageclass_json.get("allowVolumeExpansion", None),
        }
        for file in file_list
        if (storageclass := tar.extractfile(file))
        and (storageclass_json := json.loads(storageclass.read().decode("utf-8")))
    ]

    if storageclass_info:
        print("\nStorageClasses:")

    return storageclass_info


def parse_ns_memory(tar: tarfile.TarFile, use_case: str) -> None:
    """Parses metric file for OpenShift Cluster or Customer Namespace memory usage.

    Args:
        tar (tarfile.TarFile): Insights Archive
        use_case (str): Cluster or Customer

    Returns:
        None: This function prints the results directly to the console.
    """
    ns_memory_info: list = []
    ocp_ns_memory_total: int = 0

    try:
        metrics_file = tar.extractfile("config/metrics")
        metrics_data = metrics_file.read().decode("utf-8").splitlines()

        # Include or exclude namespaces based on use case
        namespaces = {
            match.group(1)
            for line in metrics_data
            if (
                match := re.match(
                    r'^namespace:container_memory_usage_bytes:sum\{namespace="([^"]+)",.*\} (\d+\.?\d*)',
                    line,
                )
            )
            and (
                (
                    use_case == "Cluster"
                    and re.match(OPENSHIFT_NAMESPACES_PATTERN, match.group(1))
                )
                or (
                    use_case == "Customer"
                    and not re.match(OPENSHIFT_NAMESPACES_PATTERN, match.group(1))
                )
            )
        }

        # Calculate memory usage for each namespace
        for namespace in sorted(namespaces):
            ns_mem_usage = 0
            for line in metrics_data:
                if f'namespace="{namespace}"' in line:
                    parts = line.split()
                    # The memory usage is the second part of the line
                    try:
                        # Grabs the value after the namespace
                        mem_value = float(parts[1])
                        ns_mem_usage += mem_value
                    except (IndexError, ValueError):
                        continue

            if ns_mem_usage > 0:
                formatted_mem_usage = (
                    f"{ns_mem_usage / MEMORY_CONVERSION_GB:.2f} GB"
                    if ns_mem_usage > DEFAULT_MEMORY_THRESHOLD
                    else f"{ns_mem_usage / MEMORY_CONVERSION_MB:.2f} MB"
                )

                ocp_ns_memory_total += ns_mem_usage

                ns_memory_info.append(
                    {
                        "NAMESPACE": namespace,
                        "MEMORY": formatted_mem_usage,
                    }
                )

        print(f"\n{use_case} Namespace Memory Usage:")
        print_output(ns_memory_info)
        print(
            f"\nTotal {use_case} Namespace Memory Usage: {ocp_ns_memory_total / MEMORY_CONVERSION_GB:.2f} GB"
        )

    except KeyError:
        print(f"\n{use_case} Metrics do not exist in Insights Archive.")


def parse_failing_pods(tar: tarfile.TarFile, file_list: list) -> list:
    """Returns pods that are failing and the reason if Listed.

    Args:
        tar (tarfile.TarFile): Insights Archive
        file_list (List[str]): List of files that match regex from file_files function

    Returns:
        List[Dict[str, Any]]: List containing Namespace, Pod Name, and Reason pod is failing.
    """
    failing_pods_info: list = [
        {
            "NAMESPACE": pod_json["metadata"]["namespace"],
            "POD NAME": pod_json["metadata"]["name"],
            "REASON": condition.get("reason", ""),
        }
        for file in file_list
        if (pod := tar.extractfile(file))
        and (pod_json := json.loads(pod.read().decode("utf-8")))
        for condition in pod_json.get("status", {}).get("conditions", [])
        if condition.get("type") == "Ready" and condition.get("status") == "False"
    ]

    if failing_pods_info:
        print("\nFailing Pods:")

    return failing_pods_info


def parse_unschedulable_pods(tar: tarfile.TarFile, file_list: list) -> list:
    """Returns unschedulable pods and the reason if Listed.

    Args:
        tar (tarfile.TarFile): Insights Archive
        file_list (List[str]): List of files that match regex from file_files function

    Returns:
        List[Dict[str, Any]]: Returns unschedulable pod's namespace, name, and reason.
    """
    unschedulable_pods_info: list = [
        {
            "NAMESPACE": pod_json["metadata"]["namespace"],
            "POD NAME": pod_json["metadata"]["name"],
            "REASON": condition.get("message", ""),
        }
        for file in file_list
        if (pod := tar.extractfile(file))
        and (pod_json := json.loads(pod.read().decode("utf-8")))
        for condition in pod_json.get("status", {}).get("conditions", [])
        if condition.get("type") == "PodScheduled"
        and condition.get("status") == "False"
    ]

    if unschedulable_pods_info:
        print("\nUnschedulable Pods:")

    return unschedulable_pods_info


def parse_restarting_pods(tar: tarfile.TarFile, file_list: list) -> list:
    """Returns pods that have more than the configured restart threshold.

    Args:
        tar (tarfile.TarFile): Insights Archive
        file_list (List[str]): List of files that match regex from file_files function

    Returns:
        List[Dict[str, Any]]: Returns pod's namespace, name, container name, and restarts if over threshold.
    """
    restarting_pods_info: list = []

    for file in file_list:
        pod = tar.extractfile(file)
        if pod:
            pod_json = json.loads(pod.read().decode("utf-8"))
            for container in pod_json.get("status", {}).get("containerStatuses", []):
                if container.get("restartCount", 0) > RESTART_THRESHOLD:
                    restart_time = (
                        container.get("state", {}).get("running", {}).get("startedAt")
                    )
                    if restart_time is not None:
                        restart_time = restart_time.replace("T", " ").rstrip("Z")
                    else:
                        restart_time = "N/A"
                    restarting_pods_info.append(
                        {
                            "NAMESPACE": pod_json["metadata"]["namespace"],
                            "POD NAME": pod_json["metadata"]["name"],
                            "CONTAINER NAME": container["name"],
                            "RESTARTS": container["restartCount"],
                            "RESTART TIME": restart_time,
                        }
                    )

    if restarting_pods_info:
        print(f"\nContainers with more than {RESTART_THRESHOLD} restarts:")

    return sorted(restarting_pods_info, key=lambda x: (x["NAMESPACE"], x["POD NAME"]))


def parse_event_files(
    tar: tarfile.TarFile,
    file_list: list,
    all_events: bool,
) -> Optional[list]:
    """Parses Warnings from namespace events if they exist.

    Args:
        tar (tarfile.TarFile): Insights Archive
        file_list (List[str]): List of files that match regex from file_files function
        all_events (bool): Prints all events if true
        clusterid (str): Used to output clusterid if all events not printed

    Returns:
        List[Dict[str, str]]: Returns a List of unique dictionaries containing namespace,
        type of message, reason, and timestamp or none if List is empty
    """
    event_list: list = []

    for file in file_list:
        with tar.extractfile(file) as event_file:
            event_json = json.load(event_file)
            warnings = [
                {
                    "NAMESPACE": event["namespace"],
                    "TYPE": event["type"],
                    "REASON": event["reason"],
                    "TIME": event["lastTimestamp"].replace("T", " ").rstrip("Z"),
                }
                for event in event_json.get("items", [])
                if event.get("type") == "Warning"
            ]
            event_list.extend(warnings)

    if all_events:
        if event_list:
            print("\nNamespace Errors:")
            return event_list

    if event_list:
        # Create a list of unique entries based on NAMESPACE
        seen_namespaces = set()
        unique_entries = []

        for entry in event_list:
            namespace = entry["NAMESPACE"]
            if namespace not in seen_namespaces:
                seen_namespaces.add(namespace)
                unique_entries.append(entry)

        print("\nNamespace Errors:")

        return unique_entries

    return None  # Return None if List is empty


def parse_alerts(tar: tarfile.TarFile, filters: dict) -> Optional[list]:
    """Parses alerts file for Active Alerts that aren't suppressed

    Args:
        tar (tarfile.TarFile): The tar file for the Insights Archive.

    Returns:
        Optional[List[Dict[str, str]]]: A List of dictionaries containing active
        alerts and the corresponding state and start time.
    """
    alerts_info: list = []
    try:
        with tar.extractfile("config/alerts.json") as alerts:
            alerts_json = json.load(alerts)

            if filters.get("alerts"):
                print(json.dumps(alerts_json, indent=4))
                sys.exit(0)
            # Filter alerts based on conditions
            alerts_info: list = [
                {
                    "ALERT NAME": alert["labels"]["alertname"],
                    "STATE": alert["status"]["state"].upper(),
                    "START TIME": alert["startsAt"].replace("T", " ").rstrip("Z"),
                }
                for alert in alerts_json
                if alert["labels"]["alertname"] != "Watchdog"
                and alert["status"]["state"] != "suppressed"
            ]

        return alerts_info or None

    except KeyError:
        return None


def parse_podnetchecks(tar: tarfile.TarFile) -> Optional[list]:
    """Parse pod network connectivity checks from a tar file.

    Args:
        tar (tarfile.TarFile): The tar file for the Insights Archive.

    Returns:
        Optional[List[Tuple[str, str]]]: A List of tuples containing error messages
        and their corresponding date and time, or None if the JSON structure is invalid.
    """
    with tar.extractfile("config/podnetworkconnectivitychecks.json") as podnetcheck:
        podnetcheck_json = json.load(podnetcheck)

    if not isinstance(podnetcheck_json, dict):
        return None

    tcp_connect_errors = podnetcheck_json.get("TCPConnectError", {})

    # Use a list comprehension to create the list of tuples
    podnetcheck_info = [
        {
            "ERROR": error_message.split(":")[0],
            "TIMESTAMP": timestamp.replace("T", " "),
        }
        for error_message, timestamp in tcp_connect_errors.items()
    ]

    if podnetcheck_info:
        print("\nPodNetworkConnectivitChecks: ")
        return podnetcheck_info

    return None


def print_etcd_metrics(dir_path: str, cluster_id: str) -> None:
    """Extracts and prints pod names and etcd_server_slow_apply_total count.

    Args:
        directory (str): The path to the directory containing tar files
        with etcd metrics.

    Returns:
        None: This function prints the results directly to the console.
    """

    # List all files in the directory
    files = list(file for file in Path(dir_path).rglob("*") if file.is_file())
    # Sort based on modified time
    files.sort(key=lambda f: f.stat().st_mtime)

    if not files:
        print(f"No Insights Data found for Cluster {cluster_id}.")
        sys.exit(1)

    # Regular expression to match the pod name and the count
    pattern = r'etcd_server_slow_apply_total\{.*?pod="([^"]+)",.*?(\d+)\s+\d+$'

    for file in files:
        with tarfile.open(file, "r:gz") as tar:
            # Check if 'config/metrics' exists in the tar file
            if "config/metrics" not in tar.getnames():
                print(f"Cluster {cluster_id} does not contain metrics.")
                sys.exit(1)

            with tar.extractfile("config/metrics") as metrics_file:
                for line in metrics_file:
                    line = line.decode("utf-8").strip()
                    if match := re.search(pattern, line):
                        # Extract both values
                        pod_name, count = match.groups()
                        # Print in CSV format
                        print(f"{pod_name},{check_in_time(file)},{count}")


def find_files(tar_files: list, regex_string: str) -> list:
    """Returns files in tar_files that meet the regex criteria.

    Args:
        tar_files (List[str]): List of files in the tar archive
        regex_string (str): Regex string used to return specific files

    Returns:
        List[str]: List of files found that match the regex
    """
    regex_pattern = re.compile(regex_string)
    return [file for file in tar_files if regex_pattern.search(file)]


def print_output(data: list) -> None:
    """Prints output from function in a evenly spaced format similar to the oc cli

    Args:
        data (List): Sorted List of dictionaries from various functions

    Returns:
        None: This function prints the results directly to the console.
    """

    if data:
        # Print new line
        print()

        # Define the headers
        headers = list(data[0].keys())

        # Find max lengths for each column
        max_lengths = {header: len(header) for header in headers}

        for entry in data:
            for key in entry:
                max_lengths[key] = max(max_lengths.get(key, 0), len(str(entry[key])))

        delimit = "  "

        # Print the header row
        header_row = delimit.join(
            [header.ljust(max_lengths[header]) for header in headers]
        )
        print(header_row)

        # Print the data rows
        for entry in data:
            row = delimit.join(
                [str(entry[header]).ljust(max_lengths[header]) for header in headers]
            )
            print(row)


def parse_arguments() -> dict:
    """Parse command-line arguments and return them as a dictionary.

    Returns:
        dict: Returns a dictionary of the results from the parser
    """
    parser = argparse.ArgumentParser(description="OpenShift InsightsCluster Report.")
    parser.add_argument(
        "--id",
        type=str,
        help="ClusterID of a connected cluster used to find all connected Clusters",
    )
    parser.add_argument(
        "--file",
        type=str,
        help="Use a specific Insights Archive File; must specify full path.",
    )
    parser.add_argument(
        "--alerts", action="store_true", help="Prints out Alerts in valid JSON"
    )
    parser.add_argument(
        "--customer_memory",
        action="store_true",
        help="Prints Customer Namespace memory usage.",
    )
    parser.add_argument(
        "--etcd_metrics",
        action="store_true",
        help="Prints etcd metrics for all Insights Archives for the cluster.",
    )
    parser.add_argument(
        "--events",
        action="store_true",
        help="Prints namespace events if they exist.",
    )
    parser.add_argument(
        "--list",
        action="store_true",
        help="List available archives for a specific cluster. Must be used with --id option. Can be combined with --extract.",
    )
    parser.add_argument(
        "--extract",
        action="store_true",
        help="Extract archive for a specific cluster to user's home directory. Must be used with --id option. Can be combined with --list to select which archive to extract.",
    )

    args = parser.parse_args()

    # Check --list and --extract specific validations first
    if args.list and args.id is None:
        print("Error: --list can only be used with --id option.")
        parser.print_help()
        sys.exit(1)

    if args.list and args.file is not None:
        print("Error: --list cannot be used with --file option.")
        parser.print_help()
        sys.exit(1)

    if args.extract and args.id is None:
        print("Error: --extract can only be used with --id option.")
        parser.print_help()
        sys.exit(1)

    if args.extract and args.file is not None:
        print("Error: --extract cannot be used with --file option.")
        parser.print_help()
        sys.exit(1)

    if args.id is None and args.file is None:
        parser.print_help()
        sys.exit(0)

    if args.id is not None and args.file is not None:
        parser.print_help()
        sys.exit(0)

    return vars(args)


def process_insights_data(
    directory: Optional[str], filters: dict, cluster_id: Optional[str]
) -> None:
    """Processes and prints out Insights Archive data

    Args:
        directory (str): Location of OpenShift Insights Archive for Cluster
        filters (Dict[str, Optional[str]]): Parse Args dict

    Returns:
        None: This function prints the results directly to the console.
    """

    newest_file: str = ""
    insights_archive = None

    if filters.get("id"):
        newest_file = find_newest_file(directory)
        if not newest_file:
            print(f"No Insights Data found for Cluster {cluster_id}.")
            return

        insights_archive = read_insights_file(newest_file)

    if filters.get("file"):
        insights_archive = read_insights_file(filters.get("file"))

    insights_archive_file = insights_archive.getnames()

    # Unpack version information
    (
        cluster_id,
        cluster_version,
        cluster_channel,
        previous_installs,
        partial_installs,
        cluster_status,
        cluster_message,
    ) = parse_version_file(insights_archive)

    # Print basic cluster information
    if filters.get("id"):
        print(f"Checkin: {check_in_time(newest_file)}\n")

    # Parse infrastructure.json
    platform, cluster_name, install_method = parse_infra_file(
        insights_archive, insights_archive_file
    )
    print(f"Cluster ID: {cluster_id}")
    print(f"Cluster Name: {cluster_name}")
    print(f"Cluster Version: {cluster_version}")
    print(f"Channel: {cluster_channel}")
    print(f"Previous Versions: {', '.join(previous_installs)}")

    if partial_installs:
        print(f"Partial Installs: {', '.join(partial_installs)}\n")

    if cluster_status:
        print(
            f"Cluster Status: Failing\nReason: {cluster_status}\nMessage: {cluster_message}"
        )

    print(f"Platform: {platform}\nInstall Type: {install_method}")
    # Parse network.json files
    print(f"Network Type: {parse_network_file(insights_archive)}")

    # Parse proxy.json file
    http_proxy, https_proxy = parse_proxy_file(insights_archive)
    print(f"Proxy Settings:\n   HTTP:  {http_proxy}\n   HTTPS: {https_proxy}\n")

    # Parse apiserver.json file
    etcd_encryption, audit_profile = parse_apiserver_file(insights_archive)
    print(f"etcd Encryption: {etcd_encryption}\nAudit Profile: {audit_profile}")

    # Define a helper function to print parsed output
    def print_parsed_output(parse_function, *args):
        print_output(parse_function(*args))

    # Process various configuration files
    file_patterns = {
        "node": "^config/node/[^/]+.json$",
        "co": "^config/clusteroperator/[^/]+.json$",
        "mcp": "^config/machineconfigpools/[^/]+.json$",
        "machineset": "^machinesets/openshift-machine-api/[^/]+.json$",
        "storage": "^config/storage/storageclasses/[^/]+.json$",
        "pod": "^config/pod/[^/]+/[^/]+.json",
        "events": "^events/[^/]+.json$",
    }

    for key, pattern in file_patterns.items():
        files = find_files(insights_archive_file, pattern)
        if key == "node":
            print_parsed_output(parse_node_files, insights_archive, files)
        elif key == "co":
            print_parsed_output(parse_cluster_operator_files, insights_archive, files)
            # Print Install Plans and OLM Operators after Cluster Operators
            print_parsed_output(parse_install_plans, insights_archive)
            print_parsed_output(parse_olm_operators, insights_archive)
        elif key == "mcp":
            print_parsed_output(parse_machineconfigpools, insights_archive, files)
        elif key == "machineset":
            print_parsed_output(parse_machinesets, insights_archive, files)
        elif key == "storage":
            print_parsed_output(parse_storageclasses, insights_archive, files)
        elif key == "pod":
            parse_ns_memory(insights_archive, "Cluster")
            if filters.get("customer_memory"):
                parse_ns_memory(insights_archive, "Customer")
            print_parsed_output(parse_failing_pods, insights_archive, files)
            print_parsed_output(parse_unschedulable_pods, insights_archive, files)
            print_parsed_output(parse_restarting_pods, insights_archive, files)
        elif key == "events":
            print_parsed_output(
                parse_event_files,
                insights_archive,
                files,
                filters["events"],
            )

    # Parse and print Alerts
    print_parsed_output(parse_alerts, insights_archive, filters)

    # Parse and print pod network checks
    print_parsed_output(parse_podnetchecks, insights_archive)


def main():
    """Main Function"""
    directory: str = ""
    cluster_id: str = ""
    args = parse_arguments()

    filters: dict = {key: value for key, value in args.items() if value is not None}

    if filters.get("id"):
        cluster_id: str = filters.get("id")

        if cluster_id and validate_clusterid(cluster_id):
            directory: str = find_cluster_path(cluster_id)
            if directory:
                # Handle --id --list --extract combination
                if filters.get("list") and filters.get("extract"):
                    archives = list_cluster_archives(cluster_id)
                    selected_file = display_archive_menu(cluster_id, archives)

                    if selected_file:
                        # Extract the selected file
                        success = extract_cluster_archive(cluster_id, directory, selected_file)
                        if success:
                            print("Archive extraction completed successfully.")
                            # Also process the selected file for evaluation
                            filters["file"] = selected_file
                            if filters.get("alerts"):
                                insights_archive = read_insights_file(selected_file)
                                parse_alerts(insights_archive, filters)
                            process_insights_data(directory, filters, cluster_id)
                            sys.exit(0)  # Exit after processing to prevent duplicate execution
                        else:
                            print("Archive extraction failed.")
                            sys.exit(1)
                    else:
                        sys.exit(0)

                # Handle --id --extract combination (without list)
                elif filters.get("extract"):
                    success = extract_cluster_archive(cluster_id, directory)
                    if success:
                        print("Archive extraction completed successfully.")
                        # Also process the latest file for evaluation
                        newest_file = find_newest_file(directory)
                        if newest_file:
                            filters["file"] = newest_file
                            if filters.get("alerts"):
                                insights_archive = read_insights_file(newest_file)
                                parse_alerts(insights_archive, filters)
                            process_insights_data(directory, filters, cluster_id)
                            sys.exit(0)  # Exit after processing to prevent duplicate execution
                        else:
                            print("No archive file found for analysis.")
                            sys.exit(1)
                    else:
                        print("Archive extraction failed.")
                        sys.exit(1)

                # Handle --id --list combination (without extract)
                elif filters.get("list"):
                    archives = list_cluster_archives(cluster_id)
                    selected_file = display_archive_menu(cluster_id, archives)

                    if selected_file:
                        # Process the selected file
                        filters["file"] = selected_file
                        if filters.get("alerts"):
                            insights_archive = read_insights_file(selected_file)
                            parse_alerts(insights_archive, filters)
                        process_insights_data(directory, filters, cluster_id)
                        sys.exit(0)  # Exit after processing to prevent duplicate execution
                    else:
                        sys.exit(0)
                else:
                    # Handle regular --id usage (existing functionality)
                    if filters.get("etcd_metrics"):
                        print_etcd_metrics(directory, cluster_id)
                        sys.exit(0)
                    if filters.get("alerts"):
                        newest_file = find_newest_file(directory)
                        if not newest_file:
                            print(f"No Insights Data found for Cluster {cluster_id}.")
                            sys.exit(1)
                        insights_archive = read_insights_file(newest_file)
                        parse_alerts(insights_archive, filters)
                    process_insights_data(directory, filters, cluster_id)
            else:
                print("No connected OpenShift Clusters found.")
                sys.exit(1)
        else:
            if cluster_id:
                print(f"ClusterID: {cluster_id} is not valid.")
            sys.exit(1)

    if filters.get("file"):
        file_path = Path(filters.get("file"))

        if file_path.is_file():
            if filters.get("alerts"):
                insights_archive = read_insights_file(file_path)
                parse_alerts(insights_archive, filters)
            process_insights_data(directory, filters, cluster_id)


if __name__ == "__main__":
    main()
