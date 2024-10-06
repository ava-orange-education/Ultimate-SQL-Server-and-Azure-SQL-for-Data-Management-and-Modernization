# Building a near real time monitoring for SQL Server across Windows, Linux and containers

In this demo, we will be using the Telegraf, Influx and Grafana stack to build a monitoring solution capable of collecting data from SQL Server on Windows, Containers and Linux environments. The data is collected from various targets by the Telegraf agent, the collected data is stored in the InfluxDB and finally viewed in the Grafana using dashboards.

You can learn more about this stack [here](https://www.influxdata.com/blog/infrastructure-monitoring-basics-telegraf-influxdb-grafana/)

A quick rundown of all the tasks we'll be carrying out to complete the setup:

1. **Install the Containers**:
    - Install the Telegraf, InfluxDB, and Grafana containers on the monitoring host machine.
    - Containers are used because they are simple to set up and provide isolation.

2. **Prepare Target SQL Server Instances**:
    - Create the login on all of the target SQL Server instances (SQL Server on Linux/containers/Windows).
    - Telegraf will use this login to connect to SQL Server instances for data collection.

3. **Demo Setup**:
    - For this demo, run all three containers on a single host machine.
    - Depending on the instances you monitor and data collected, you may decide to run the containers on different nodes.

4. **Configure Data Retention Policies for InfluxDB**:
    - Set data retention policies to ensure InfluxDB does not grow out of bounds.

5. **Set Up Grafana**:
    - Configure Grafana to create a dashboard with graphs and charts.

## Prerequisite
1. An Azure account with active subscription to create an Azure Kubernetes Service (AKS) based cluster
2. A Client machine, in this example I am using a Windows client machine (my laptop) and I will install Azure CLI on Windows as documented [here](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli-windows?tabs=azure-cli). 
3. Log in to the Azure account using the Az login command from the command prompt.
4. A SQL Server instance running on RHEL. You can follow this document to [install SQL Server on RHEL](https://learn.microsoft.com/en-us/sql/linux/quickstart-install-connect-red-hat?view=sql-server-ver16&tabs=rhel9)
5. A SQL Server container instance deployed using docker, follow [this](https://learn.microsoft.com/en-us/sql/linux/quickstart-install-connect-docker?view=sql-server-ver16&tabs=cli&pivots=cs1-bash) document for more information
6. Another VM running Windows with SQL Server installed, follow [this](https://learn.microsoft.com/en-us/azure/azure-sql/virtual-machines/windows/create-sql-vm-portal?view=azuresql) document 
for details.


## Deploy docker and the entire stack

1. Install docker on the Ubuntu 22.04 host, which is our monitoring VM. To install Docker on Ubuntu 22.04 VM, refer to [this](https://docs.docker.com/engine/install/ubuntu/) article.
2. Run the command below to create a docker network. This is the common network on which all three containers (Telegraf, InfluxDB, and Grafana) will be deployed

```
docker network create --driver bridge influxdb-telegraf-net 
#You can change the name of the network from “influxdb-telegraf-net” to whatever you want.​
```

3. We will now create the SQL Server login that telegraf will use to connect to the target SQL Server instances. This login must be created on all target SQL Server instances that you intend to monitor. You can change the login name from telegraf to any other name of your choice, but the same also needs to be changed in the telegraf.conf file as well.

```
USE master; 
CREATE LOGIN telegraf WITH PASSWORD = N'StrongPassword1!', CHECK_POLICY = ON; 
GO 
GRANT VIEW SERVER STATE TO telegraf; 
GO 
GRANT VIEW ANY DEFINITION TO telegraf; 
GO 
```

4. Run the following command to deploy the telegraf container.
```
docker run -d --name=telegraf -v /home/amvin/monitor/sqltelegraf/telegraf.conf:/etc/telegraf/telegraf.conf --net=influxdb-telegraf-net telegraf 
# where:/home/amvin/monitor/sqltelegraf/telegraf.conf is a telegraf configuration file placed on my host machine, please update the path as per your environment.
# please ensure that you change the IP addresses and port numbers to your target SQL Server instances in the telegraf.conf file that you create in your environment. 
```
Note: You can download the sample telegraf.conf from [here](https://github.com/microsoft/mssql-docker/blob/master/linux/monitor/telegraf.conf). Please remember to change the IP address to your target SQL Server instance IP addresses.

5.  Run the following command to deploy the InfluxDB container

```
docker run --detach --net=influxdb-telegraf-net -v /home/amvin/monitor/data/influx:/var/lib/influxdb:rw --hostname influxdb --restart=always -p 8086:8086 --name influxdb influxdb:1.8 

# where: /home/amvin/monitor/data/influx is a folder on the host that I am mounting inside the container, you can create this folder in any location.
# please ensure you set the right permissions so files can be written inside this folder by the container.  ​
```
6. Deploy the Grafana container using the following command

```
docker run --detach -p 3001:3000 --net=influxdb-telegraf-net --restart=always -v /home/amvin/monitor/data/grafana:/var/lib/grafana -e "GF_INSTALL_PLUGINS=grafana-piechart-panel,savantly-heatmap-panel" --name grafana grafana/grafana:8.1.1

# where: home/amvin/monitor/data/grafana is a folder on the host that I am mounting inside the container, you can create this folder in any location.
# please ensure you set the right permissions so files can be written inside this folder. 
# grafana-azure-monitor-datasource is already included with grafana, so removing it from the list of plugins to install.
```

7. With the containers now deployed, use "docker ps -a" to list all the three

8. Let's now setup retention policy on InfluxDB to ensure that there is limited growth of the database. I am setting this for 30 days, you can configure it as per your requirement.

```
sudo docker exec -it influxdb bash
#then run beow commands inside the container
influx
create database telegraf;
use telegraf; 
show retention policies; 
create retention policy retain30days on telegraf duration 30d replication 1 default; 
quit
```

## Setting up Grafana: 

We are now ready to create the dashboard. Before that, we need to set up Grafana. Follow these steps:

1. **Browse to Your Grafana Instance**:
   - Go to http://[GRAFANA_IP_ADDRESS_OR_SERVERNAME]:3000.

2. **First Time Login**:
   - Use `admin` for both the login and password.
   - Check the Getting Started Grafana documentation.

3. **Add a Data Source for InfluxDB**:
   - Refer to the detailed instructions in the Grafana data source docs.
   - **Type**: InfluxDB.
   - **Name**: InfluxDB (default).
   - **URL**: http://[INFLUXDB_HOSTNAME_OR_IP_ADDRESS]:8086 (use http://localhost:8086 if Grafana and InfluxDB are on the same machine).
   - **Database**: telegraf.
   - Click "Save & Test". You should see the message "Data source is working".

4. **Import Grafana Dashboard JSON Definitions**:
   - Download the JSON [definitions from the repo](https://github.com/microsoft/mssql-docker/blob/master/linux/monitor/dashboard/dashboard.json).
   - [Import](http://docs.grafana.org/reference/export_import/#importing-a-dashboard) them into Grafana.

You are ready and this is how the dashboard should look, feel free to modify the graphs as per your requirement.

<p align="center">
  <img src="./Figure 1 Monitoring Dashboard as seen in Grafana for SQL Server.png" alt="Monitoring Dashboard as seen in Grafana for SQL Server">
   <p style="text-align:center;"><em>Figure 1</em></p>
</p>
