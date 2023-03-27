---
page_type: sample
languages:
- azdeveloper
- java
- bicep
products:
- azure
- azure-container-apps
- azure-container-registry
- azure-monitor
- ms-build-openjdk
urlFragment: aca-windup
name: Windup on Azure Container Apps
description: Uses Azure Developer CLI (azd) to build, deploy, and monitor Windup on ACA
---
<!-- YAML front-matter schema: https://review.learn.microsoft.com/en-us/help/contribute/samples/process/onboarding?branch=main#supported-metadata-fields-for-readmemd -->

# Windup on Azure Container Apps

A complete ToDo application that includes everything you need to build, deploy, and monitor an Azure solution. This application uses the Azure Developer CLI (azd) to get you up and running on Azure quickly, React.js for the Web application, Java for the API, Azure Cosmos DB API for MongoDB for storage, and Azure Monitor for monitoring and logging. It includes application code, tools, and pipelines that serve as a foundation from which you can build upon and customize when creating your own solutions.

Let's jump in and get the Windup App up and running in Azure. When you are finished, you will have a fully functional web app deployed on Azure. In later steps, you'll see how to setup a pipeline and monitor the application.

<img src="assets/web.png" width="75%" alt="Screenshot of deployed ToDo app">

<sup>Screenshot of the deployed ToDo app</sup>

## Prerequisites

The following prerequisites are required to use this application. Please ensure that you have them all installed locally.

- [Azure Developer CLI](https://aka.ms/azd-install)
- [Java 17 or later](https://learn.microsoft.com/en-us/java/openjdk/install) - for API backend
- [Docker](https://docs.docker.com/get-docker/)

Read : 
- [azd CLI installation](https://learn.microsoft.com/en-us/azure/developer/azure-developer-cli/install-azd?tabs=localinstall%2Cwindows%2Cbrew)
- [Java Mongo ACA sample](https://github.com/Azure-Samples/todo-java-mongo-aca)
- []()

```sh
curl -fsSL https://aka.ms/install-azd.sh | bash
azd template list

LOCATION="westeurope"
RG_APP="rg-aca-windup"
az group create --name $RG_APP --location $LOCATION

```

## Build
```sh
WINDUP_VERSION="6.1.6"

wget https://repo1.maven.org/maven2/org/jboss/windup/windup-cli/${WINDUP_VERSION}.Final/windup-cli-${WINDUP_VERSION}.Final-offline.zip
gunzip windup-cli-${WINDUP_VERSION}.Final-offline.zip

DISTRIBUTION_DIR=dist
mkdir $DISTRIBUTION_DIR

wget https://repo1.maven.org/maven2/org/jboss/windup/web/windup-web-distribution/${WINDUP_VERSION}.Final/windup-web-distribution-${WINDUP_VERSION}.Final-with-authentication.zip -O $DISTRIBUTION_DIR

cd $DISTRIBUTION_DIR
unzip windup-web-distribution-${WINDUP_VERSION}.Final-with-authentication.zip
```

## Run

1. Open codespaces
2. Have a quick coffee (~5 minutes) while everything loads
3. Click on Debug: Run all and enjoy

```sh

```


## Quickstart: Deploy to Azure

### GitHub Action Workflow pre-req

A Service Principal is required for GitHub Action Runner, read [https://aka.ms/azadsp-cli](https://aka.ms/azadsp-cli)
```bash  
SPN_APP_NAME="gha_aca_windup_run"

# /!\ In CloudShell, the default subscription is not always the one you thought ...
subName="set here the name of your subscription"
subName=$(az account list --query "[?name=='${subName}'].{name:name}" --output tsv)
echo "subscription Name :" $subName

AZURE_SUBSCRIPTION_ID=$(az account list --query "[?name=='${subName}'].{id:id}" --output tsv | tr -d '\r' | tr -d '"')
AZURE_SUBSCRIPTION_ID=$(az account show --query id -o tsv | tr -d '\r' | tr -d '"')
AZURE_TENANT_ID=$(az account show --query tenantId -o tsv | tr -d '\r' | tr -d '"')
```

Read :
- [https://learn.microsoft.com/en-us/azure/developer/github/connect-from-azure](https://learn.microsoft.com/en-us/azure/developer/github/connect-from-azure?tabs=azure-cli%2Cwindows#create-a-service-principal-and-add-it-as-a-github-secret)
- [https://learn.microsoft.com/en-us/azure/developer/github/connect-from-azure?tabs=azure-cli%2Cwindows#use-the-azure-login-action-with-openid-connect](https://learn.microsoft.com/en-us/azure/developer/github/connect-from-azure?tabs=azure-cli%2Cwindows#use-the-azure-login-action-with-openid-connect)
- [https://learn.microsoft.com/en-us/azure/active-directory/develop/workload-identity-federation-create-trust?pivots=identity-wif-apps-methods-azp](https://learn.microsoft.com/en-us/azure/active-directory/develop/workload-identity-federation-create-trust?pivots=identity-wif-apps-methods-azp)


In the GitHub Action Runner, to allow the Service Principal used to access the Key Vault, execute the command below:
```sh
cd prv
az ad app create --display-name $SPN_APP_NAME > aad_app.json

# Enterprise Application

# This is the unique ID of the Service Principal object associated with this application.
SPN_OBJECT_ID=$(az ad app list --show-mine --query "[?displayName=='${SPN_APP_NAME}'].{objectId:id}" -o tsv | tr -d '\r' | tr -d '"')
APPLICATION_ID=$(az ad app list --show-mine --query "[?displayName=='${SPN_APP_NAME}'].{appId:appId}" -o tsv | tr -d '\r' | tr -d '"')
```

Troubleshoot:
If you hit _["Error: : No subscriptions found for ***."](https://learn.microsoft.com/en-us/answers/questions/738782/no-subscription-found-for-function-during-azure-cl.html)_ , this is related to an IAM privilege in the subscription.


```sh
az ad sp create --id $APPLICATION_ID


SPN_APP_ID=$(az ad sp list --all --query "[?appDisplayName=='${SPN_APP_NAME}'].{appId:appId}" -o tsv | tr -d '\r' | tr -d '"')
#SPN_APP_ID=$(az ad sp list --show-mine --query "[?appDisplayName=='${SPN_APP_NAME}'].{appId:appId}" --output tsv)
# TENANT_ID=$(az ad sp list --show-mine --query "[?appDisplayName=='${SPN_APP_NAME}'].{t:appOwnerOrganizationId}" --output tsv)

az ad sp show --id $SPN_APP_ID

# Network-contributor: https://learn.microsoft.com/en-us/azure/role-based-access-control/resource-provider-operations#microsoftnetwork
az role assignment create --assignee $SPN_APP_ID --scope /subscriptions/${AZURE_SUBSCRIPTION_ID} --role 4d97b98b-1d4f-4787-a291-c67834d212e7

# https://learn.microsoft.com/en-us/azure/role-based-access-control/role-assignments-portal#prerequisites
# /!\ To assign Azure roles, you must have: requires to have Microsoft.Authorization/roleAssignments/write and Microsoft.Authorization/roleAssignments/delete permissions, 
# such as User Access Administrator or Owner.
az role assignment create --assignee $SPN_APP_ID --scope /subscriptions/${AZURE_SUBSCRIPTION_ID}/resourceGroups/${RG_APP} --role Owner

az role assignment create --role contributor --subscription ${AZURE_SUBSCRIPTION_ID} --assignee $SPN_APP_ID --scope /subscriptions/${AZURE_SUBSCRIPTION_ID}/resourceGroups/${RG_APP}
```


```sh
export CREDENTIAL_NAME="gha_aca_windup_run"
export GH_USER_NAME="yourGitHubAccount"
export SUBJECT="repo:$GH_USER_NAME/aca-windup:ref:refs/heads/main" # "repo:organization/repository:environment:Production"
export DESCRIPTION="GitHub Action Runner for Windup on ACA demo"

# https://github.com/Azure/azure-cli/issues/25291
az rest --method POST --uri 'https://graph.microsoft.com/beta/applications/$SPN_OBJECT_ID/federatedIdentityCredentials' --body '{"name":"$CREDENTIAL_NAME","issuer":"https://token.actions.githubusercontent.com","subject":"$SUBJECT","description":"$DESCRIPTION","audiences":["api://AzureADTokenExchange"]}'
```

Workaround if CLI command above fails: create it from the Azure portal from the URL below :
```sh
echo "https://portal.azure.com/#view/Microsoft_AAD_RegisteredApps/ApplicationMenuBlade/~/Credentials/appId/$APPLICATION_ID/isMSAApp~/false"
```

Add your AZURE_SUBSCRIPTION_ID, AZURE_TENANT_ID, AZURE_CLIENT_ID (Application (client) ID), to your GH repo secrets / Actions secrets / Repository secrets
Check at https://github.com/<yourGitHubAccount>/aca-windup/settings/secrets/actions



The fastest way for you to get this application up and running on Azure is to use the `azd up` command. 
Login to az cli and azd cli - azd login

1. Open a terminal, create a new empty folder, and change into it.
1. Run the following command to initialize the project, provision Azure resources, and deploy the application code.

```bash
azd up
```

You will be prompted for the following information:

- `Environment Name`: This will be used as a prefix for the resource group that will be created to hold all Azure resources. This name should be unique within your Azure subscription.
- `Azure Location`: The Azure location where your resources will be deployed.
- `Azure Subscription`: The Azure Subscription where your resources will be deployed.

> NOTE: This template may only be used with the following Azure locations:
>
> - Australia East
> - Brazil South
> - Canada Central
> - Central US
> - East Asia
> - East US
> - East US 2
> - Germany West Central
> - Japan East
> - Korea Central
> - North Central US
> - North Europe
> - South Central US
> - UK South
> - West Europe
> - West US
>
> If you attempt to use the template with an unsupported region, the provision step will fail.

> NOTE: This may take a while to complete as it executes three commands: `azd init` (initializes environment), `azd provision` (provisions Azure resources), and `azd deploy` (deploys application code). You will see a progress indicator as it provisions and deploys your application.

When `azd up` is complete it will output the following URLs:

- Azure Portal link to view resources
- Windup Web application UI

!["azd up output"](assets/urls.png)

Click the web application URL to launch the ToDo app. Create a new collection and add some items. This will create monitoring activity in the application that you will be able to see later when you run `azd monitor`.

> NOTE:
>
> - The `azd up` command will create Azure resources that will incur costs to your Azure subscription. You can clean up those resources manually via the Azure portal or with the `azd down` command.
> - You can call `azd up` as many times as you like to both provision and deploy your solution, but you only need to provide the `--template` parameter the first time you call it to get the code locally. Subsequent `azd up` calls do not require the template parameter. If you do provide the parameter, all your local source code will be overwritten if you agree to overwrite when prompted.
> - You can always create a new environment with `azd env new`.

### Application Architecture

This application utilizes the following Azure resources:

- [**Azure Container Apps**](https://docs.microsoft.com/azure/container-apps/) to host the UI and API backend
- [**Azure Monitor**](https://docs.microsoft.com/azure/azure-monitor/) for monitoring and logging
- [**Azure Key Vault**](https://docs.microsoft.com/azure/key-vault/) for securing secrets

Here's a high level architecture diagram that illustrates these components. Notice that these are all contained within a single [resource group](https://docs.microsoft.com/azure/azure-resource-manager/management/manage-resource-groups-portal), that will be created for you when you create the resources.

<img src="assets/resources.png" width="60%" alt="Application architecture diagram"/>

> This template provisions resources to an Azure subscription that you will select upon provisioning them. Please refer to the [Pricing calculator for Microsoft Azure](https://azure.microsoft.com/pricing/calculator/) and, if needed, update the included Azure resource definitions found in `infra/main.bicep` to suit your needs.

### Application Code

The repo is structured to follow the [Azure Developer CLI](https://aka.ms/azure-dev/overview) conventions including:

- **Source Code**: All application source code is located in the `src` folder.
- **Infrastructure as Code**: All application "infrastructure as code" files are located in the `infra` folder.
- **Azure Developer Configuration**: An `azure.yaml` file located in the root that ties the application source code to the Azure services defined in your "infrastructure as code" files.
- **GitHub Actions**: A sample GitHub action file is located in the `.github/workflows` folder.
- **VS Code Configuration**: All VS Code configuration to run and debug the application is located in the `.vscode` folder.

### Azure Subscription

This template will create infrastructure and deploy code to Azure. If you don't have an Azure Subscription, you can sign up for a [free account here](https://azure.microsoft.com/free/). Make sure you have contributor role to the Azure subscription.

### Azure Developer CLI - VS Code Extension

The Azure Developer experience includes an Azure Developer CLI VS Code Extension that mirrors all of the Azure Developer CLI commands into the `azure.yaml` context menu and command palette options. If you are a VS Code user, then we highly recommend installing this extension for the best experience.

Here's how to install it:

#### VS Code

1. Click on the "Extensions" tab in VS Code
1. Search for "Azure Developer CLI" - authored by Microsoft
1. Click "Install"

#### Marketplace

1. Go to the [Azure Developer CLI - VS Code Extension](https://marketplace.visualstudio.com/items?itemName=ms-azuretools.azure-dev) page
1. Click "Install"

Once the extension is installed, you can press `F1`, and type "Azure Developer CLI" to see all of your available options. You can also right click on your project's `azure.yaml` file for a list of commands.

### Next Steps

At this point, you have a complete application deployed on Azure. But there is much more that the Azure Developer CLI can do. These next steps will introduce you to additional commands that will make creating applications on Azure much easier. Using the Azure Developer CLI, you can setup your pipelines, monitor your application, test and debug locally.

#### Set up a pipeline using `azd pipeline`

This template includes a GitHub Actions pipeline configuration file that will deploy your application whenever code is pushed to the main branch. You can find that pipeline file here: `.github/workflows`.

Setting up this pipeline requires you to give GitHub permission to deploy to Azure on your behalf, which is done via a Service Principal stored in a GitHub secret named `AZURE_CREDENTIALS`. The `azd pipeline config` command will automatically create a service principal for you. The command also helps to create a private GitHub repository and pushes code to the newly created repo.

Run the following command to set up a GitHub Action:

```bash
azd pipeline config
```

> Support for Azure DevOps Pipelines is coming soon to `azd pipeline config`. In the meantime, you can follow the instructions found here: [.azdo/pipelines/README.md](./.azdo/pipelines/README.md) to set it up manually.

#### Monitor the application using `azd monitor`

To help with monitoring applications, the Azure Dev CLI provides a `monitor` command to help you get to the various Application Insights dashboards.

- Run the following command to open the "Overview" dashboard:

  ```bash
  azd monitor --overview
  ```

- Live Metrics Dashboard

  Run the following command to open the "Live Metrics" dashboard:

  ```bash
  azd monitor --live
  ```

- Logs Dashboard

  Run the following command to open the "Logs" dashboard:

  ```bash
  azd monitor --logs
  ```

#### Run and Debug Locally

The easiest way to run and debug is to leverage the Azure Developer CLI Visual Studio Code Extension. Refer to this [walk-through](https://aka.ms/azure-dev/vscode) for more details.

#### Clean up resources

When you are done, you can delete all the Azure resources created with this template by running the following command:

```bash
azd down
```



### Additional azd commands

The Azure Developer CLI includes many other commands to help with your Azure development experience. You can view these commands at the terminal by running `azd help`. You can also view the full list of commands on our [Azure Developer CLI command](https://aka.ms/azure-dev/ref) page.

## Troubleshooting/Known issues

Sometimes, things go awry. If you happen to run into issues, then please review our ["Known Issues"](https://aka.ms/azure-dev/knownissues) page for help. If you continue to have issues, then please file an issue in our main [Azure Dev](https://aka.ms/azure-dev/issues) repository.

## Security

### Roles

This template creates a [managed identity](https://docs.microsoft.com/azure/active-directory/managed-identities-azure-resources/overview) for your app inside your Azure Active Directory tenant, and it is used to authenticate your app with Azure and other services that support Azure AD authentication like Key Vault via access policies. You will see principalId referenced in the infrastructure as code files, that refers to the id of the currently logged in Azure Developer CLI user, which will be granted access policies and permissions to run the application locally. To view your managed identity in the Azure Portal, follow these [steps](https://docs.microsoft.com/azure/active-directory/managed-identities-azure-resources/how-to-view-managed-identity-service-principal-portal).


## Uninstall

To remove the Azure Developer CLI, refer to [uninstall Azure Developer CLI](https://aka.ms/azd-install?tabs=baremetal%2Cwindows#uninstall-azd).

## Reporting Issues and Feedback

If you have any feature requests, issues, or areas for improvement, please [file an issue](https://aka.ms/azure-dev/issues). To keep up-to-date, ask questions, or share suggestions, join our [GitHub Discussions](https://aka.ms/azure-dev/discussions). You may also contact us via AzDevTeam@microsoft.com.
