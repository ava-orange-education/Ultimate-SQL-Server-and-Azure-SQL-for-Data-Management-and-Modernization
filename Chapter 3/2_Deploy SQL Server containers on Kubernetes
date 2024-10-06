# Deploy SQL Server containers on Kubernetes platform
## Kubernetes
Kubernetes is a platform that helps you manage your container deployments. Containers are great for bundling and running apps, but managing many containers can get tricky. Imagine one of your app containers stops working—you'd have to start a new one yourself. Kubernetes automates this by handling tasks like starting new containers, scaling them up or down based on the overall load, and managing network access for applications inside containers. It makes using containers much easier and more efficient. To learn more please refer the [official Kubernetes documentation](https://kubernetes.io/docs/concepts/overview/)

## prerequisite
1. An Azure account with active subscription to create an Azure Kubernetes Service (AKS) based cluster
2. A Client machine, in this example I am using a Windows client machine (my laptop) and I will install Azure CLI on Windows as documented [here](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli-windows?tabs=azure-cli). When you install Azure CLI it also install the kubectl which is a Kubernetes CLI to help you connect and work with the Kubernetes cluster.

### Deploying and connecting to your Azure Kubernetes Service Cluster

1. Once, you have successfully installed Az CLI on your client machine, open a command prompt and run the Az login command as shown below:

```
C:\>az login
A web browser has been opened at https://login.microsoftonline.com/organizations/oauth2/v2.0/authorize. Please continue the login in the web browser. If no web browser is available or if the web browser fails to open, use device code flow with `az login --use-device-code`.
[
  {
    "cloudName": "AzureCloud",
    "homeTenantId": "xxxxxxxx-xxxx-xxxx-30f03f011a7c",
    "id": "xxxxxxxx-xxxx-xxxx-xxxx-e7daf7540158",
    "isDefault": true,
    "managedByTenants": [],
    "name": "Visual Studio Enterprise Subscription",
    "state": "Enabled",
    "tenantId": "xxxxxxxx-xxxx-xxxx-30f03f011a7c",
    "user": {
      "name": "myname@something.com",
      "type": "user"
    }
  }
]
```

2. Once you log in and connect to your subscription, run the following commands to create a resource group and then the Azure Kubernetes cluster with 2 nodes within that resource group.

```
##Create the resource group
az group create --name sqlk8s --location centralindia

##Create the AKS cluster within the resource group

az aks create --resource-group sqlk8s --name myAKSCluster --node-count 2 --generate-ssh-keys
```
3. Now, connect to your AKS cluster using the following command:

```
az aks get-credentials --resource-group sqlk8s --name myAKSCluster
```
4. Finally you are ready now to run the kubectl commands as shown below:

```
C:\Users\amitkh>kubectl get all
NAME                 TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
service/kubernetes   ClusterIP   10.0.0.1     <none>        443/TCP   3m5s
```

## Deploying SQL Server container on the AKS cluster

1. You should by now have a AKS cluster called myAKSCluster running and connected. Now, lets deploy SQL Server containers on this cluster and connect to it using the SQL Server Management Studio

2. First, lets create a secret object in the kubernetes cluster using the kubectl command, this secret will be used to save the sa password that will be used by us when we login for the first time to SQL Server.

```
kubectl create secret generic mssql --from-literal=MSSQL_SA_PASSWORD="MyC0m9l&xP@ssw0rd"
```

3. Now create a file called `sqldeployment.yml` and save the following content in the file. I am creating this file in `D:/Example/`. In this script, here are the objects that I create:

    1. **Storage Class**: 
    - Based on Azure Disk.
    - Creates a Persistent Volume called `mssql-data` to store SQL Server data, ensuring data is not lost when the container is deleted.

    2. **Persistent Volume Claim**:
    - Informs the Kubernetes cluster about the storage to be used for this claim, the size of the storage, and the access mode.

    3. **SQL Server Deployment**:
    - Deploys SQL Server in case the container goes down.
    - Deploys one container (replica is set to 1, different from Always On availability group Replica).

    4. **SQL Server Image**:
    - Deploys the latest SQL Server 2022 image.
    - Enables a few environment variables to enable SQL Server Agent and pass the password through the environment variable `MSSQL_SA_PASSWORD`.
    - Uses the secret `mssql` created earlier.
    - Sets the SQL Server port to default 1433.
    - Mounts the `mssql-data` storage to the folder `/var/opt/mssql`, so all data in `/var/opt/mssql` inside the container is saved in the mount `mssql-data`.

    5. **Service Creation**:
    - Enables access to the SQL Server inside the Kubernetes cluster.
    - Uses the External IP address to connect to the SQL Server.

```
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
     name: azure-disk
provisioner: kubernetes.io/azure-disk
parameters:
  storageaccounttype: Standard_LRS
  kind: Managed
---
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: mssql-data
  annotations:
    volume.beta.kubernetes.io/storage-class: azure-disk
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 8Gi
--- 
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mssql-deployment
  labels:
    app: mssql
spec:
  replicas: 1
  selector:
      matchLabels:
          app: mssql
  template:
    metadata:
      labels:
        app: mssql
    spec:
      terminationGracePeriodSeconds: 10
      hostname: mssqlinst1
      securityContext:
        fsGroup: 1000
      containers:
      - name: mssql
        image: mcr.microsoft.com/mssql/server:2022-latest
        ports:
        - containerPort: 1433
        env:
        - name: MSSQL_PID
          value: "Web"
        - name: ACCEPT_EULA
          value: "Y"
        - name: MSSQL_AGENT_ENABLED
          value: "true"
        - name: MSSQL_SA_PASSWORD
          valueFrom:
            secretKeyRef:
              name: mssql
              key: MSSQL_SA_PASSWORD
        volumeMounts:
        - name: mssqldb
          mountPath: /var/opt/mssql
      volumes:
      - name: mssqldb
        persistentVolumeClaim:
          claimName: mssql-data                  
---
apiVersion: v1
kind: Service
metadata:
  name: mssql-deployment
spec:
  selector:
    app: mssql
  ports:
    - protocol: TCP
      port: 1433
      targetPort: 1433
  type: LoadBalancer
  ```

  4. To deploy SQL Server, run the following commands. The first time might take a few minutes since the container image needs to be downloaded. However, once it's downloaded, you can have the SQL Server service up and running in just a few seconds.

 ```
 # Deploy SQL Server container
 C:\>kubectl apply -f "D:\Example\SQLdeployment.yml"
 storageclass.storage.k8s.io/azure-disk created
 persistentvolumeclaim/mssql-data created
 deployment.apps/mssql-deployment created
 service/mssql-deployment created

 # List the objects in the cluster
 C:\>kubectl get all
 NAME                                    READY   STATUS    RESTARTS   AGE
 pod/mssql-deployment-6cd4b4f6cb-kcxsb   1/1     Running   0          22s

 NAME                       TYPE           CLUSTER-IP     EXTERNAL-IP     PORT(S)          AGE
 service/kubernetes         ClusterIP      10.0.0.1       <none>          443/TCP          30m
 service/mssql-deployment   LoadBalancer   10.0.126.228   4.188.104.181   1433:32025/TCP   7m23s

 NAME                               READY   UP-TO-DATE   AVAILABLE   AGE
 deployment.apps/mssql-deployment   1/1     1            1           22s

 NAME                                          DESIRED   CURRENT   READY   AGE
 replicaset.apps/mssql-deployment-6cd4b4f6cb   1         1         1       22s
 
 ```

 5. Finally, connect to the SQL Server using the IP Address 4.188.104.181, this enables you to connect to the SQL Server outside of the kubernetes cluster, open SSMS and connect as shown below, us the sa password that you used to create the secret

 <p align="center">
   <img src="./Figure 9 Connecting to SQL Container on AKS using SSMS.png" alt="Connecting to SQL Container on AKS using SSMS">
    <p style="text-align:center;"><em>Figure 1</em></p>
 </p>

