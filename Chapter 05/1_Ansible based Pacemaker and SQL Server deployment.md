# Deploy Always On avaialbility groups for SQL Server with Pacemaker using Ansible

In this demo, we will create three Red Hat Enterprise Linux 8 based Azure VM, then deploy a Pacemaker cluster with SQL Server Always On availability group providing you the automatic failover for High availability.

## Prerequisite
1. An Azure account with active subscription to create an Azure Kubernetes Service (AKS) based cluster
2. A Client machine, in this example I am using a Windows client machine (my laptop) and I will install Azure CLI on Windows as documented [here](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli-windows?tabs=azure-cli). 
3. Log in to the Azure account using the Az login command from the command prompt.

## Deploying the Azure VMs, configuring STONITH (Shoot the Other Node in the Head) to ensure there are no split brian sceanrios and creating the Load balancer service

1. Lets create the Azure VMs, as you can see I am using the Azure Marketplace images as shown below:

```
#To list all the SQL based RHEL offers, you can run the following command
az vm image list --all --offer "sql2019-rhel8"

# Run the following commands to create the VMs, using the SQL Server PAYG(Pay-as-you-go) # images pre-configured on RHEL 8 base OS image, thus avoiding the steps to install and # configure SQL Server deployments. We are using the Standard_B4ms as an example 

az vm create --resource-group testgroup --name sqlrhel1 --size "Standard_B4ms" --location "west india" --image "MicrosoftSQLServer:sql2022-rhel8:sqldev:16.0.240723" --vnet-name amvindomain-vnet --subnet default --admin-username "adminuser" --admin-password "StrongPa$$w0rd" --authentication-type all --generate-ssh-keys

az vm create --resource-group testgroup --name sqlrhel2 --size "Standard_B4ms" --location "west india" --image "MicrosoftSQLServer:sql2022-rhel8:sqldev:16.0.240723" --vnet-name amvindomain-vnet --subnet default --admin-username "adminuser" --admin-password "StrongPa$$w0rd" --authentication-type all --generate-ssh-keys

az vm create --resource-group testgroup --name sqlrhel3 --size "Standard_B4ms" --location "west india" --image "MicrosoftSQLServer:sql2022-rhel8:sqldev:16.0.240723" --vnet-name amvindomain-vnet --subnet default --admin-username "adminuser" --admin-password "StrongPa$$w0rd" --authentication-type all --generate-ssh-keys​
```
2. Register a [new application in Microsoft Entra ID](https://docs.microsoft.com/en-us/azure/azure-sql/virtual-machines/linux/rhel-high-availability-stonith-tutorial?view=azuresql#register-a-new-application-in-azure-active-directory), [create custom role for the fence agent](https://docs.microsoft.com/en-us/azure/azure-sql/virtual-machines/linux/rhel-high-availability-stonith-tutorial?view=azuresql#create-a-custom-role-for-the-fence-agent) & [Assign the custom role to the Service Principal](https://docs.microsoft.com/en-us/azure/azure-sql/virtual-machines/linux/rhel-high-availability-stonith-tutorial?view=azuresql#assign-the-custom-role-to-the-service-principal). You must have guessed this is required to configure the STONITH devices. Please note, if you already have a pre-created application and custom role in your subscription you can also use that.
3. Lastly, create and configure the Azure load balancer, required to setup the Listener service.

## Preparing the VMs and scripts:

Now, that we have the VMs deployed we will install Ansible-core on one of the nodes that will act as controller and deploy SQL Server and pacemaker on the target nodes using the Ansible playbook. I also need to configure passwordless ssh between the controller node and all the targets. 

### Install Ansible core and configure VMs
Here are the commands to install the Ansible core and update the VMs

```
# My controller node is sqlrhel1, that is why on this node I am installing the 
# ansible-core package and also updating the RHEL to the latest version, please note that # my controller node is also a target node.
az vm run-command invoke -g testgroup -n sqlrhel1 --command-id RunShellScript --scripts "sudo yum update -y && sudo yum install ansible-core -y"

# On my other target nodes sqlrhel2 and sqlrhel3 I am just updating the RHEL to latest 
# version
az vm run-command invoke -g testgroup -n sqlrhel2 --command-id RunShellScript --scripts "sudo yum update -y"
az vm run-command invoke -g testgroup -n sqlrhel3 --command-id RunShellScript --scripts "sudo yum update -y"
```
SQLrhel1 is the controller node and the ansible-core packate is installed. I am now going to install the microsoft.sql role on the same node. Login to the sqlrhel1 VM and run the below command:

```
[root@sqlrhel1 sql]# ansible-galaxy collection install microsoft.sql
```
### Setup the passwordless SSH access between the controller node and all the targets

To configure passwordless SSH between the controller and all target nodes, see the section:”[Setup passwordless ssh access between the Control node and the managed nodes” in the blog post Deploy SQL Server – The Ansible way! - Microsoft Tech Community](https://techcommunity.microsoft.com/t5/sql-server-blog/deploy-sql-server-the-ansible-way/ba-p/2593284). For more information on troubleshooting SSH access errors, please see this [Red Hat article](https://access.redhat.com/solutions/9194)

### Creating the inventory and playbok for deployment

In Ansible, the inventory file defines the target hosts that you want to configure with the Ansible playbook; in this case, my controller node (sqlrhel1) is also a target node. I create a file on the controller node called inventory and then paste the following content:


```
all:
  hosts:
    sqlrhel1:
      mssql_ha_replica_type: primary
    sqlrhel2:
      mssql_ha_replica_type: synchronous
    sqlrhel3:
      mssql_ha_replica_type: synchronous
```
Now, finally create the playbook as shown below, I am creating a file called playbook.yaml on the controller node with the following content:
```
- hosts: all
  vars:
    mssql_accept_microsoft_odbc_driver_17_for_sql_server_eula: true
    mssql_accept_microsoft_cli_utilities_for_sql_server_eula: true
    mssql_accept_microsoft_sql_server_standard_eula: true
    mssql_version: 2022
    mssql_manage_firewall: true
    mssql_password: "SQLp@55w0rD1"
    mssql_edition: Developer
    mssql_ha_configure: true
    mssql_ha_listener_port: 5022
    mssql_ha_cert_name: ExampleCert
    mssql_ha_master_key_password: "p@55w0rD1"
    mssql_ha_private_key_password: "p@55w0rD2"
    mssql_ha_reset_cert: true
    mssql_ha_endpoint_name: ag_endpoint
    mssql_ha_ag_name: ag_test
    mssql_ha_db_names:
      - test
    mssql_ha_login: pacemakerLogin
    mssql_ha_login_password: "Pacemakerp@55w0rD1"
    # Set mssql_ha_virtual_ip to the frontend IP address configured in the Azure
    # load balancer
    mssql_ha_virtual_ip: 172.22.0.22
    mssql_ha_cluster_run_role: true
    ha_cluster_cluster_name: "{{ mssql_ha_ag_name }}"
    ha_cluster_hacluster_password: "p@55w0rD4"
    ha_cluster_extra_packages:
      - fence-agents-azure-arm
    ha_cluster_cluster_properties:
      - attrs:
          - name: cluster-recheck-interval
            value: 2min
          - name: start-failure-is-fatal
            value: true
          - name: stonith-enabled
            value: true
          - name: stonith-timeout
            value: 900
    ha_cluster_resource_primitives:
      - id: rsc_st_azure
        agent: stonith:fence_azure_arm
        instance_attrs:
          - attrs:
              - name: login
                value: <ApplicationID> for your application registration in Azure
              - name: passwd
                value: <ServiceprincipalPassword> value from the client secret
              - name: resourceGroup
                value: <resourcegroupname> in Azure
              - name: tenantId
                value: <tenantID> in Azure
              - name: subscriptionId
                value: <subscriptionID> in Azure
              - name: power_timeout
                value: 240
              - name: pcmk_reboot_timeout
                value: 900
      - id: azure_load_balancer
        agent: azure-lb
        instance_attrs:
          - attrs:
            # probe port configured in Azure
            - name: port
              value: 59999
      - id: ag_cluster
        agent: ocf:mssql:ag
        instance_attrs:
          - attrs:
            - name: ag_name
              value: "{{ mssql_ha_ag_name }}"
        meta_attrs:
          - attrs:
            - name: failure-timeout
              value: 60s
      - id: virtualip
        agent: ocf:heartbeat:IPaddr2
        instance_attrs:
          - attrs:
            - name: ip
              value: "{{ mssql_ha_virtual_ip }}"
        operations:
          - action: monitor
            attrs:
              - name: interval
                value: 30s
    ha_cluster_resource_groups:
      - id: virtualip_group
        resource_ids:
          - azure_load_balancer
          - virtualip
    ha_cluster_resource_clones:
      - resource_id: ag_cluster
        promotable: yes
        meta_attrs:
          - attrs:
            - name: notify
              value: true
    ha_cluster_constraints_colocation:
      - resource_leader:
          id: ag_cluster-clone
          role: Promoted
        resource_follower:
          id: azure_load_balancer
        options:
          - name: score
            value: INFINITY
    ha_cluster_constraints_order:
      - resource_first:
          id: ag_cluster-clone
          action: promote
        resource_then:
          id: azure_load_balancer
          action: start
    # Variables to open the probe port configured in Azure in firewall
    firewall:
      - port: 59999/tcp
        state: enabled
        permanent: true
        runtime: true
  roles:
    - fedora.linux_system_roles.firewall
    - microsoft.sql.server
```
Here is what the above script does:

    1. Verifies that the SQL Server and tools are properly configured.
    2. Creates the necessary endpoints and certificates, as well as copies the certificates across replicas, for Always On availability groups (AG) endpoint authentication.Pacemaker login is  created in all the SQL Server replicas.
    3. The Pacemaker login is created in all SQL Server replicas.
    4. Installs the STONITH "fence-agents-azure-arm" on all nodes, which provides a fencing agent.
    5. Creates cluster resources : rsc st azure, ag cluster-clone, virtualip, and azure load balancer. The latter two resources are also added to the virtualip group resource group.
    6. It opens the firewall ports for the health check probe (59999 in this case, as defined in the Azure load balancer configuration), the AG endpoint (5022), and the SQL Server (1433).
    7. Finally, it creates an AG listener service for the AG.
    
On the controller node, when I list the files, I see the inventory and the playbook.yaml file as shown below:

```
[root@sqlrhel1 sql]# ll
total 48
-rw-r--r-- 1 root root  6431 Aug 29 21:30 CHANGELOG.md
-rw-r--r-- 1 root root 17218 Aug 29 21:30 FILES.json
-rw-r--r-- 1 root root   175 Aug 29 21:31 inventory
-rw-r--r-- 1 root root  1053 Aug 29 21:30 LICENSE-server
-rw-r--r-- 1 root root   892 Aug 29 21:30 MANIFEST.json
drwxr-xr-x 2 root root    25 Aug 29 21:30 meta
-rw-r--r-- 1 root root  3839 Aug 29 21:34 playbook.yaml
-rw-r--r-- 1 root root  1278 Aug 29 21:30 README.md
drwxr-xr-x 3 root root    20 Aug 29 21:30 roles
drwxr-xr-x 3 root root    20 Aug 29 21:30 tests​
```

## Deploy SQL Server with AGs using Pacemaker as the cluster stack 

From the controller node, run the below command and go get a coffee for your self, the deployment may take about 10 minutes to complete to deploy SQL Server on all nodes, then configure SQL Server cluster, with pacemaker deployments and cluster creation. 

```
[root@sqlrhel1 sql]# ansible-playbook -i inventory playbook.yaml
```
Once the installation completes this is how the cluster looks :
```
[root@sqlrhel1 sql]# sudo pcs status
Cluster name: ag_test1
Cluster Summary:
  * Stack: corosync
  * Current DC: sqlrhel2 (version 2.1.2-4.el8_6.2-ada5c3b36e2) - partition with quorum
  * Last updated: Mon Aug 29 21:36:10 2022
  * Last change:  Mon Aug 29 20:50:36 2022 by root via cibadmin on sqlrhel1
  * 3 nodes configured
  * 6 resource instances configured
 
Node List:
  * Online: [ sqlrhel1 sqlrhel2 sqlrhel3 ]
 
Full List of Resources:
  * rsc_st_azure        (stonith:fence_azure_arm):       Started sqlrhel1
  * Resource Group: virtualip_group:
    * azure_load_balancer       (ocf::heartbeat:azure-lb):       Started sqlrhel1
    * virtualip (ocf::heartbeat:IPaddr2):        Started sqlrhel1
  * Clone Set: ag_cluster-clone [ag_cluster] (promotable):
    * Masters: [ sqlrhel1 ]
    * Slaves: [ sqlrhel2 sqlrhel3 ]
all:
  hosts:
    sqlrhel1:
      mssql_ha_replica_type: primary
    sqlrhel2:
      mssql_ha_replica_type: synchronous
    sqlrhel3:
      mssql_ha_replica_type: synchronous
```

You can now connect to the primary node using SQL Server management studio and open the AG dashboard to view the Always On availability group created. 