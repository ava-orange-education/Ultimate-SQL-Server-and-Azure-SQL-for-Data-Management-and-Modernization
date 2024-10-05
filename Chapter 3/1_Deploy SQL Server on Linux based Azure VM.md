# Deploying SQL Server on Linux based Azure Virtual Machine 

## Pre-requistes:
You will need an Azure Account, for learning and development purpose you can create your free Azure Account by following steps as described in this [official Microsoft Article](https://azure.microsoft.com/en-in/free/search/?ef_id=_k_e6701fd3a5cb134b5b2278d20d42a933_k_&OCID=AIDcmmf1elj9v5_SEM__k_e6701fd3a5cb134b5b2278d20d42a933_k_&msclkid=e6701fd3a5cb134b5b2278d20d42a933).


### Deploy the Linux-based Azure Virtual machine and then manually install SQL Server

SQL Server on Linux is supported on Red Hat Enterprise  Linux(RHEL), SUSE Linux Enterprise Server (SLES) and Ubuntu. For the latest and complete list, please refer the [supported platform documentation](https://learn.microsoft.com/en-us/sql/linux/sql-server-linux-setup?view=sql-server-ver16#supportedplatforms) 

In this demonstration, we will install SQL Server 2022 on Ubuntu 22.04.

1. Login into the Azure Portal using the credentials you used to register you Free Azure Account.

1. Next, as shown in figure 1, in the search bar inside the portal, type virtual machine and click 'virtual machine

<p align="center">
  <img src="./Figure 1 Search and select virtual machine in Azure Portal.png" alt="Search and select virtual machine in Azure Portal">
   <p style="text-align:center;"><em>Figure 1</em></p>
</p>

3. Click on the create option and provide the basic details like the resource group name, Virtual Machine name, Linux Image details , Password and so on as shown in figure 2 & 3

<p align="center">
  <img src="./Figure 2 Basic Details required for the VM creation.png" alt="Basic Details required for the VM creation">
   <p style="text-align:center;"><em>Figure 2</em></p>
</p>

<p align="center">
  <img src="./Figure 3 Setting the Password to login.png" alt="Setting the Password to login">
   <p style="text-align:center;"><em>Figure 3</em></p>
</p>

4. Finally, after you have provided all the details, click on the "Review+create" button and within a few minutes you should have the VM ready and deployed as shown in figure 4.

<p align="center">
  <img src="./Figure 4 VM resource is created and ready to login.png" alt="VM resource is created and ready to login">
   <p style="text-align:center;"><em>Figure 4</em></p>
</p>

#### Deploy SQL Server on Linux.

1. Once the VM is deployed, login into the Azure Linux VM using your favourtie SSH putty tool, in my case I am using Visual Studio with the Remote Explorer Extention to connect to the Linux VM and then run the commands to deploy SQL Server on Linux as shown below

<p align="center">
  <img src="./Figure 5 Login to the Azure VM using VS code.png" alt="Login to the Azure VM using VS code">
   <p style="text-align:center;"><em>Figure 5</em></p>
</p>

2. Commands to install SQL Server 2022 on the Azure Ubuntu 22.04 

```
# Setup the public key and add the Microsoft SQL Server repo as shown below
curl https://packages.microsoft.com/keys/microsoft.asc | sudo tee /etc/apt/trusted.gpg.d/microsoft.asc
curl -fsSL https://packages.microsoft.com/config/ubuntu/22.04/mssql-server-2022.list | sudo tee /etc/apt/sources.list.d/mssql-server-2022.list

# install SQL Server
sudo apt-get update
sudo apt-get install -y mssql-server

```
3. Once the installation, completes its time to configure SQL Server where you provide the sa password that you will use to login to SQL Server, you will also configure the SQL Server edition that you intend to deploy, for developer purpose please use Developer edition as shown below in figure 6

```
sudo /opt/mssql/bin/mssql-conf setup
```
<p align="center">
  <img src="./Figure 6 Configuring SQL Server using the mssql-conf command.png" alt="Configuring SQL Server using the mssql-conf command">
   <p style="text-align:center;"><em>Figure 6</em></p>
</p>

4. Confirm SQL Server Service has started using the following command: 'sudo systemctl status mssql-server.service '

```
amvin@amvinlinux:~$ sudo systemctl status mssql-server.service 
● mssql-server.service - Microsoft SQL Server Database Engine
     Loaded: loaded (/lib/systemd/system/mssql-server.service; enabled; vendor preset: enabled)
     Active: active (running) since Sat 2024-10-05 21:47:38 UTC; 5min ago
       Docs: https://docs.microsoft.com/en-us/sql/linux
   Main PID: 5494 (sqlservr)
      Tasks: 179
     Memory: 801.6M
        CPU: 17.469s
     CGroup: /system.slice/mssql-server.service
             ├─5494 /opt/mssql/bin/sqlservr
             └─5544 /opt/mssql/bin/sqlservr

```
You can now connect to this SQL Server instance using SQL Server Management Studio, like we did in the earlier Chapter demos.

### Deploy SQL Server using the Azure Marketplace image

Another option you have is to deploy an Azure Linux-based Virtual Machine (VM) with SQL Server already pre-installed using Azure Marketplace images. This approach simplifies getting started with SQL Server on Linux VMs in Azure, as it bypasses the entire installation process.

1. Go the Azure Portal, create the VM option as we did earlier, for the image option please select "see all images" that takes you to the Azure Marketplace 

<p align="center">
  <img src="./Figure 7 Navigate to the Azure Marketplace for image selection.png" alt="Navigate to the Azure Marketplace for image selection">
   <p style="text-align:center;"><em>Figure 7</em></p>
</p>

2. In the Azure Marketplace, search for SQL Server on Linux and you can see the various SQL Server flavours on the different distributions as seen in Figure 8, I am going to choose the SQL Server 2022 on Ubuntu 22.04, and the rest of the steps remain the same as covered previously

<p align="center">
  <img src="./Figure 8 SQL Server on Linux Azure Marketplace images.png" alt="SQL Server on Linux Azure Marketplace images">
   <p style="text-align:center;"><em>Figure 8</em></p>
</p>

3. Once the VM is created now, you can run the configuration using the mssql-conf tool using the command 

```
sudo /opt/mssql/bin/mssql-conf setup
```

4. Finally, connect to the SQL Server using SQL Server Management Studio or any other client like Azure Data Studio.