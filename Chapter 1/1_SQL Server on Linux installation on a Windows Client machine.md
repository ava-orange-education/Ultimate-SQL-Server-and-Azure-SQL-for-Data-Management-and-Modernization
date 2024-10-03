# SQL Server installation on Linux on a Windows Machine

## Installing WSL2 on Windows to run Linux distributions:

 In this excerise, we will configure WSL2 on a Windows machine, then configure Ubuntu 22.04 and finally install SQL Server 2022 on Ubuntu 22.04 running in Windows :) 

 To install WSL 2 on your Windows machine please run the following command in a powershell window:

```
wsl --install -d Ubuntu-22.04 
```
List the distributions that are available via the store :

```
Wsl -l -o

-- here is how the output looks
PS C:\Users\amvin> wsl -l -o
The following is a list of valid distributions that can be installed.
Install using 'wsl.exe --install <Distro>'.

NAME                            FRIENDLY NAME
Ubuntu                          Ubuntu
Debian                          Debian GNU/Linux
kali-linux                      Kali Linux Rolling
Ubuntu-18.04                    Ubuntu 18.04 LTS
Ubuntu-20.04                    Ubuntu 20.04 LTS
Ubuntu-22.04                    Ubuntu 22.04 LTS
Ubuntu-24.04                    Ubuntu 24.04 LTS
OracleLinux_7_9                 Oracle Linux 7.9
OracleLinux_8_7                 Oracle Linux 8.7
OracleLinux_9_1                 Oracle Linux 9.1
openSUSE-Leap-15.6              openSUSE Leap 15.6
SUSE-Linux-Enterprise-15-SP5    SUSE Linux Enterprise 15 SP5
SUSE-Linux-Enterprise-15-SP6    SUSE Linux Enterprise 15 SP6
openSUSE-Tumbleweed             openSUSE Tumbleweed
```
Install your choice of distribution that is supported for SQL Server Distributions, please refer [Microsoft offficial documentation](https://learn.microsoft.com/en-us/sql/linux/sql-server-linux-setup?view=sql-server-ver16#supportedplatforms)

In this sample, I am going to install Ubuntu 22.04 as shown below
```
wsl.exe --install Ubuntu-22.04

```

Now open Microsoft Terminal using the steps Click on Windows button-> Type "terminal"-> Once the Terminal window opens you can then choose Ubuntu 22.04 from the dropdown this will start the Ubuntu 22.04 terminal and you can now run commands like you would do on a linux machine.

## Install SQL Server 

Once you have the terminal with Ubuntu 22.04 running, install SQL Server by following the steps as documented [here](https://learn.microsoft.com/en-us/sql/linux/quickstart-install-connect-ubuntu?view=sql-server-ver16&tabs=ubuntu2204) also shared below for reference:

1. Download the Public key, convert to GPG format:

```
curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | sudo gpg --dearmor -o /usr/share/keyrings/microsoft-prod.gpg
```
1. Download and register the SQL Server repository

```
curl -fsSL https://packages.microsoft.com/config/ubuntu/22.04/mssql-server-2022.list | sudo tee /etc/apt/sources.list.d/mssql-server-2022.list
```
1. Install SQL Server using the following command:

```
sudo apt-get update
sudo apt-get install -y mssql-server
```
1. Verify that the SQL Server installation is successful, by checking the status of the service

```
sudo systemctl status mssql-server
```

1. Finally configure SQL Server using the following mssql-conf command:

```
sudo /opt/mssql/bin/mssql-conf setup
```
Ensure you provide a strong SA password as this will be the password you will use to login for the first time to SQL Server after installation. 
You can choose the Developer SKU if you are not going to run any production workload and will use for learning & Development only.
