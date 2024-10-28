# Install SQL Server Management Studio on the Windows Client machine and connect to the SQL Server

## Installing SQL Server Management Studio on the Windows Client:

Please download the latest SQL Server Management Studio (SSMS) exe from official [Microsoft page](https://learn.microsoft.com/en-us/sql/ssms/download-sql-server-management-studio-ssms?view=sql-server-ver16)

Run the SSMS-Setup-ENU.exe that you downloaded in the previous step, follow the on-screen instructions and you should have a successful SSMS client installed on your Windows Machine.

Click on the Windows(start) button -> type "SQL Server Management Studio" and start the client

## Connect to the SQL Server instance deployed in previous script using SSMS

To connect you need the IP Address for the WSL2 service that runs SQL Server, you can identify that using the command ```wsl hostname -I``` on a powershell terminal

Now, connect to the IP Address in my case the output of the previous command was 172.19.50.241

<p align="center">
  <img src="./figure 1 SSMS connection to SQL Server.jpg" alt="Figure 1: SSMS connection to SQL Server">
   <p style="text-align:center;"><em>Figure 1</em></p>
</p>

## Create your first database

Now, that you've connected to SQL Server you can click on new query and then run the following T-SQL (Transact SQL) to create your first database

``` 
create database myfirstdb
```
Create objects like your first table inside the database using the following T-SQL command

```
use myfirstdb
go
create table myfirsttable (i int , name char(10))
```

Insert values in your myfirsttable 

```
insert into myfirsttable values (1, 'Amit') 
insert into myfirsttable values (1, 'Shivi') 
insert into myfirsttable values (1, 'Praavi') 
insert into myfirsttable values (1, 'Krishvi') 
```

Here is how the database and object looks in SSMS

<p align="center">
  <img src="./Table as seen in SSMS.png" alt="Figure 2: Table as seen in SSMS">
   <p style="text-align:center;"><em>Figure 2</em></p>
</p>

This concludes the demo