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

This concludes the demo