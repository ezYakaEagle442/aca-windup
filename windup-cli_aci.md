

```sh

subId=$(az account show --query id)
echo "subscription ID :" $subId

tenantId=$(az account show --query tenantId -o tsv)
UNIQUEID=$(openssl rand -hex 3)
rg_name="rg-aca-windup"
location="westeurope"
appName="Windup$UNIQUEID"
echo "appName=$appName"

# Create an Azure File
str_name="sta""${appName,,}"
az storage account create --name $str_name --kind FileStorage --sku Premium_ZRS --location $location -g $rg_name 
az storage account list -g $rg_name

fs_share_name=winshare
az storage share create --name $fs_share_name --account-name $str_name
az storage share list --account-name $str_name
az storage share show --name $fs_share_name --account-name $str_name

# https://docs.microsoft.com/en-us/azure/storage/files/storage-how-to-use-files-linux
httpEndpoint=$(az storage account show --name $str_name -g $rg_name --query "primaryEndpoints.file" | tr -d '\r' | tr -d '"')
#smbPath=$(echo $httpEndpoint | cut -c7-$(expr length $httpEndpoint))$fs_share_name
smbPath=$httpEndpoint"$fs_share_name"
storageAccountKey=$(az storage account keys list --account-name $str_name -g $rg_name --query "[0].value" | tr -d '\r' | tr -d '"')

echo "httpEndpoint" $httpEndpoint
echo "smbPath" $smbPath
echo "storageAccountKey" $storageAccountKey

export RESOURCE_GROUP=$rg_name
export STORAGE_ACCOUNT_NAME=$str_name
export SHARE_NAME=$fs_share_name

imageName="quay.io/windupeng/windup-cli-openshift:latest"
windupBinaryPath="/opt/migrationtoolkit/bin/windup-cli"
windupInput="spring-petclinic-3.0.0-SNAPSHOT.jar"
windupTarget="azure-appservice"

analytics_workspace_name="law-${appName}"
echo "Analytics Workspace Name :" $analytics_workspace_name

az monitor log-analytics workspace create -n $analytics_workspace_name --location $location -g $rg_name --verbose
az monitor log-analytics workspace list
az monitor log-analytics workspace show -n $analytics_workspace_name -g $rg_name --verbose

# -o tsv to manage quotes issues
analytics_workspace_id=$(az monitor log-analytics workspace show -n $analytics_workspace_name -g $rg_name --query id -o tsv | tr -d '\r' | tr -d '"')
echo "analytics_workspace_id:" $analytics_workspace_id

customerId=$(az monitor log-analytics workspace show -n $analytics_workspace_name -g $rg_name --query customerId -o tsv | tr -d '\r' | tr -d '"')
echo "analytics_workspace_id:" $customerId

container_name=windup-cli
aci_sku=???

 az container create --name $container_name -g $rg_name --location $location \
 --image quay.io/windupeng/windup-cli-openshift:latest \
 --cpu 1 --memory 1.5 --ports 8042 8080 \
 --azure-file-volume-account-key $storageAccountKey \
 --azure-file-volume-account-name $str_name \
 --azure-file-volume-mount-path /winshare \
 --azure-file-volume-share-name $fs_share_name \
 --command-line "${windupBinaryPath} --input /winshare/input/${windupInput} --target ${windupTarget} --output /winshare/output/ -b" \
 --log-analytics-workspace "$analytics_workspace_id" \
 --log-analytics-workspace-key "$customerId" \
 --dns-name-label $appName
 # --sku $aci_sku

 az container show -n $container_name  -g $rg_name -query "{FQDN:ipAddress.fqdn,ProvisioningState:provisioningState}" --out table
 
 container_url=$(az container show -n $container_name  -g $rg_name --query ipAddress.fqdn -o tsv | tr -d '\r' | tr -d '"')
 echo "Check ACI container at " $container_url

```