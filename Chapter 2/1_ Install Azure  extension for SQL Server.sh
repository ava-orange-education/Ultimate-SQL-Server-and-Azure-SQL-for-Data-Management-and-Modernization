# An example of the script that was downloaded from Microsoft Azure Portal to install the Azure Extension for SQL Server to enable Azure Arc.
# This script is used to enroll a SQL Server on Linux environment. The subscription ID has been obfuscated.
# This script is provided as is and under the Microsoft Corporation copyright. I am re-sharing this here for reference only. Please download the script for your configuration from the Azure Portal. 
# !/bin/bash
#
# Copyright (c) Microsoft Corporation.
#
# Note that this script is for Linux only

subId='xxxxxxxx-xxxx-xxxx-xxxx-e7daf7540158'
resourceGroup='azurearc_test'
location='centralindia'
proxy=''
licenseType='PAYG'
tags=
machineName='linuxvmtest'

# These optional variables can be replaced with valid service principal details
# if you would like to use this script for a registration at scale scenario, i.e. run it on multiple machines remotely
# For more information, see https://docs.microsoft.com/sql/sql-server/azure-arc/connect-at-scale
#
servicePrincipalAppId=''
servicePrincipalTenantId=''
servicePrincipalSecret=''

[[ -n "$servicePrincipalAppId" ]] && [[ -n "$servicePrincipalSecret" ]] && [[ -n "$servicePrincipalTenantId" ]]
unattended=$?

# Check if script is running as root
#
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root"
    exit
fi

# Check if az cli is installed
#
# Microsoft provided url for yum repos for azure-cli and location for gpgkey
#
azure_cli_repo="[azure-cli]
name=Azure CLI
baseurl=https://packages.microsoft.com/yumrepos/azure-cli
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc"

if ! command -v az &>/dev/null; then
    # Prompt for user input if running unattended
    #
    if [[ 0 -ne $unattended ]] ; then
        read -rp "Do you wish to install the Azure CLI? (y/N) "  answer
        case ${answer:0:1} in
            y|Y )
                echo "Installing Azure CLI"
            ;;
            * )
                echo "Azure CLI installation declined. Please verify that you have the Azure CLI installed to complete registration. \
                See https://docs.microsoft.com/en-us/cli/azure/install-azure-cli for more information.\n"
                exit 1
            ;;
        esac
    fi

    if command -v apt-get >/dev/null; then
        curl -sL https://aka.ms/InstallAzureCLIDeb | bash
    elif command -v yum >/dev/null; then
        rpm --import https://packages.microsoft.com/keys/microsoft.asc
        sh -c 'echo -e "$1" > /etc/yum.repos.d/azure-cli.repo' -- "$azure_cli_repo"
        yum install azure-cli
    elif command -v zypper > /dev/null; then
        curl -sL https://azurecliprod.blob.core.windows.net/sles12_install_v2.sh | sudo bash
        source ~/.bashrc
    else
        echo "Could not identify package manager, Azure CLI install failed"
        exit 1
    fi
fi

if ! az account set --subscription $subId >/dev/null; then
    if [[ -n "$servicePrincipalAppId" ]] && [[ -n "$servicePrincipalSecret" ]] && [[ -n "$servicePrincipalTenantId" ]]; then
        az login --service-principal --username "$servicePrincipalAppId" --tenant "$servicePrincipalTenantId" --password "$servicePrincipalSecret"
    else
        az login --use-device-code
    fi
fi

if ! az account set --subscription $subId; then
    echo "Unable to set context to $subId. It is possible that given subscription not found in logged in context."
fi

# Check if Microsoft.AzureArcData resource provider is registered, register resource provider if not registered
#
resourceProviderName="Microsoft.AzureArcData"
resourceProviderRegState=$(az provider show --namespace $resourceProviderName --query "registrationState")
if [[ -z "$resourceProviderRegState" ]] || [ $resourceProviderRegState != '"Registered"' ]; then
    echo "Registering resource provider ${resourceProviderName} to subscription ${subId}"
    az provider register --namespace $resourceProviderName --wait

    resourceProviderRegState=$(az provider show --namespace $resourceProviderName --query "registrationState")

    if [[ $resourceProviderRegState != '"Registered"' ]]; then
        echo "Failed to register resource provider ${resourceProviderName} to subscription ${subId}"
        exit 1
    else
        echo "${resourceProviderName} is registered to subscription ${subId}."
    fi
fi

if [[ -z "$machineName" ]]; then
    machineName=$HOSTNAME
fi

# Check if current machine is Arc joined, and join if necessary
#
machineResource=$(az resource show --name $machineName -g $resourceGroup --resource-type "Microsoft.HybridCompute/machines" 2>/dev/null)
if [[ -z "$machineResource" ]]; then

    echo "Registering machine with Arc"
    wget https://aka.ms/azcmagent -O /tmp/install_linux_azcmagent.sh

    if [[ ! -z "$proxy" ]]; then
        bash /tmp/install_linux_azcmagent.sh --proxy $proxy
    else
        bash /tmp/install_linux_azcmagent.sh
    fi

    if [[ -n "$servicePrincipalAppId" ]] && [[ -n "$servicePrincipalSecret" ]] && [[ -n "$servicePrincipalTenantId" ]]; then
        azcmagent connect --service-principal-id $servicePrincipalAppId --service-principal-secret $servicePrincipalSecret --resource-group $resourceGroup --location $location --subscription-id $subId --tenant-id $servicePrincipalTenantId
    else
        tenantId=$(az account show --subscription $subId --query tenantId --output tsv)
        accessToken=$(az account get-access-token --subscription $subId --query accessToken --output tsv 2>/dev/null)

        if [[ -z $accessToken ]]; then
            echo "Failed to obtain access token for subscription $subId and tenant $tenantId."
            exit 1
        fi

        azcmagent connect --access-token $accessToken --resource-group $resourceGroup --location $location --subscription-id $subId --tenant-id $tenantId --resource-name $machineName
    fi

    # wait for azure resource to propagate
    #
    machineResource=$(az resource show --name $machineName -g $resourceGroup --resource-type "Microsoft.HybridCompute/machines" 2>/dev/null)
    retries=0
    while [[ $retries -le 3 ]] && [[ -z "$machineResource" ]]; do
        sleep 5
        machineResource=$(az resource show --name $machineName -g $resourceGroup --resource-type "Microsoft.HybridCompute/machines" 2>/dev/null)
        let retries=retries+1
    done
    
    if [[ -z "$machineResource" ]]; then
        echo "Error while registering machine with Arc for Servers."
        exit 1
    fi
fi


echo "Installing Azure extension for SQL Server. This may take 5+ minutes."
az config set extension.use_dynamic_install=yes_without_prompt

settings="{\"SqlManagement\":{\"IsEnabled\":true},\"LicenseType\":\"${licenseType}\"}"

result=$(az connectedmachine extension create --machine-name $machineName --location $location --name "LinuxAgent.SqlServer" --resource-group $resourceGroup --type "LinuxAgent.SqlServer" --publisher "Microsoft.AzureData" --settings $settings)
provisioningState=$(echo $result | grep -o '"properties": {[^}]*' | grep -o '[^{]*$' | grep -o '"provisioningState": "[^"]*' |  grep -o '[^"]*$')

if [[ $provisioningState == "Failed" ]]; then
    echo "Extension Installation Failed. SQL Server enabled by Azure Arc instances will not be created. Please find more information below."
    echo $result
    exit 1
fi

echo "Azure extension for SQL Server is successfully installed. If one or more SQL Server instances are up and running on the server, SQL Server enabled by Azure Arc instance resource(s) will be visible within a minute on the portal.
Newly installed instances or instances started now will show up within an hour."
