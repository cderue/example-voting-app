# Deploying microservices with Waypoint and GitHub: A voting app example

A simple distributed application running across multiple microservices in Docker containers. This solution uses Python, Node.js, .NET, with Redis for messaging and Postgres for storage.

## Prerequisites

- An Azure subscription. If you do not have an Azure account, create one now. This tutorial can be completed using only the services included in an Azure free account.
- The Azure CLI installed
- [Docker Desktop for Mac or Windows](https://www.docker.com/products/docker-desktop) installed

## Architecture

![Architecture diagram](architecture.excalidraw.png)

* A front-end web app in [Python](/vote) which lets you vote between two options
* A [Redis](https://hub.docker.com/_/redis/) which collects new votes
* A [.NET](/worker/) worker which consumes votes and stores them in…
* A [Postgres](https://hub.docker.com/_/postgres/) database backed by a Docker volume
* A [Node.js](/result) web app which shows the results of the voting in real time

## Notes

The voting application only accepts one vote per client browser. It does not register additional votes if a vote has already been submitted from a client.

This isn't an example of a properly architected perfectly designed distributed app... it's just a simple
example of the various types of pieces and languages you might see (queues, persistent data, etc), and how to
deal with them in Docker at a basic level.

## Authenticate using the Azure CLI

Terraform must authenticate to Azure to create infrastructure.

```shell
$ az login
```

```code
You have logged in. Now let us find all the subscriptions to which you have access...

[
  {
    "cloudName": "AzureCloud",
    "homeTenantId": "0envbwi39-home-Tenant-Id",
    "id": "35akss-subscription-id",
    "isDefault": true,
    "managedByTenants": [],
    "name": "Subscription-Name",
    "state": "Enabled",
    "tenantId": "0envbwi39-TenantId",
    "user": {
      "name": "your-username@domain.com",
      "type": "user"
    }
  }
]
```

Find the id column for the subscription account you want to use.
Once you have chosen the account subscription ID, set the account with the Azure CLI.

```shell
$ az account set --subscription "35akss-subscription-id"
```

## Create an Azure Service Principal

Next, create a Service Principal. A Service Principal is an application within Azure Active Directory with the authentication tokens Terraform needs to perform actions on your behalf. Update the <SUBSCRIPTION_ID> with the subscription ID you specified in the previous step.

```shell
$ az ad sp create-for-rbac --role="Contributor" --scopes="/subscriptions/<SUBSCRIPTION_ID>"

Creating 'Contributor' role assignment under scope '/subscriptions/35akss-subscription-id'
The output includes credentials that you must protect. Be sure that you do not include these credentials in your code or check the credentials into your source control. For more information, see https://aka.ms/azadsp-cli
{
  "appId": "xxxxxx-xxx-xxxx-xxxx-xxxxxxxxxx",
  "displayName": "azure-cli-2022-xxxx",
  "password": "xxxxxx~xxxxxx~xxxxx",
  "tenant": "xxxxx-xxxx-xxxxx-xxxx-xxxxx"
}
```

## Set your environment variables

HashiCorp recommends setting these values as environment variables rather than saving them in your Terraform configuration.
In your terminal, set the following environment variables. Be sure to update the variable values with the values Azure returned in the previous command.

```shell
$ export ARM_CLIENT_ID="<APPID_VALUE>"
$ export ARM_CLIENT_SECRET="<PASSWORD_VALUE>"
$ export ARM_SUBSCRIPTION_ID="<SUBSCRIPTION_ID>"
$ export ARM_TENANT_ID="<TENANT_VALUE>"
```

Make note of the `appId`, `display_name`, `password`, and `tenant`.

## Create a Kubernetes cluster with Azure Kubernetes Service using Terraform

Azure Kubernetes Service (AKS) manages your hosted Kubernetes environment. AKS allows you to deploy and manage containerized applications without container orchestration expertise. AKS also enables you to do many common maintenance operations without taking your app offline. These operations include provisioning, upgrading, and scaling resources on demand.

### Setup the Terraform input variables


### Initialize the Terraform configuration

Initialize the voting-app-example directory in your terminal. The terraform commands will work with any operating system. Your output should look similar to the one below.

```shell
$ terraform init
Initializing the backend...

Initializing provider plugins...
- Finding hashicorp/azurerm versions matching "~> 3.0.2"...
- Installing hashicorp/azurerm v3.0.2...
- Installed hashicorp/azurerm v3.0.2 (signed by HashiCorp)

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
```

### Apply the Terraform configuration

Run the terraform apply command to apply your configuration.

This output shows the execution plan and will prompt you for approval before proceeding. If anything in the plan seems incorrect or dangerous, it is safe to abort here with no changes made to your infrastructure. Type yes at the confirmation prompt to proceed.





### Verify the results

1. Get the resource group name.

    ```shell
    $ echo "$(terraform output resource_group_name)"
    ```

1. Browse to the [Azure portal](https://portal.azure.com).

1. Under **Azure services**, select **Resource groups** and locate your new resource group to see the following resources created in this demo:

    - **Solution:** By default, the demo names this solution **ContainerInsights**. The portal will show the solution's workspace name in parenthesis.
    - **Kubernetes service:** By default, the demo names this service **k8stest**. (A Managed Kubernetes Cluster is also known as an AKS / Azure Kubernetes Service.)
    - **Log Analytics Workspace:** By default, the demo names this workspace with a prefix of **TestLogAnalyticsWorkspaceName-** followed by a random number.

1. Get the Kubernetes configuration from the Terraform state and store it in a file that kubectl can read.

    ```console
    echo "$(terraform output kube_config)" > ./azurek8s
    ```

1. Verify the previous command didn't add an ASCII EOT character.

    ```console
    cat ./azurek8s
    ```

   **Key points:**

    - If you see `<< EOT` at the beginning and `EOT` at the end, remove these characters from the file. Otherwise, you could receive the following error message: `error: error loading config file "./azurek8s": yaml: line 2: mapping values are not allowed in this context`

1. Set an environment variable so that kubectl picks up the correct config.

    ```console
    $ export KUBECONFIG=./azurek8s
    ```

1. Verify the health of the cluster.

    ```shell
    $ kubectl get nodes
    ```

    ![The kubectl tool allows you to verify the health of your Kubernetes cluster](./media/create-k8s-cluster-with-tf-and-aks/kubectl-get-nodes.png)

**Key points:**

- When the AKS cluster was created, monitoring was enabled to capture health metrics for both the cluster nodes and pods. These health metrics are available in the Azure portal. For more information on container health monitoring, see [Monitor Azure Kubernetes Service health](/azure/azure-monitor/insights/container-insights-overview).
- Several key values were output when you applied the Terraform execution plan. For example, the host address, AKS cluster user name, and AKS cluster password are output.
- To view all of the output values, run `terraform output`.
- To view a specific output value, run `echo "$(terraform output <output_value_name>)"`.

## Installing the Waypoint Server with Helm
The recommended process for installing Waypoint on Kubernetes is with Helm using the official Waypoint Helm chart. This documentation assumes you have helm installed and that your kubectl is already configured to talk to a Kubernetes cluster.

You can install Waypoint using the following commands:

```shell
$ helm repo add hashicorp https://helm.releases.hashicorp.com
"hashicorp" has been added to your repositories

helm install waypoint hashicorp/waypoint
```

The Helm chart has many configurable values but is designed to work out of the box with reasonable defaults.

Once you run helm install, it may take Waypoint up to 10 minutes to bootstrap itself. During this time, you may retry running the command below to log in to your Waypoint cluster. Once the command succeeds, Waypoint is ready for usage! If the command below fails, wait a few moments and try again; the Waypoint cluster is probably still bootstrapping.

```shell
$ waypoint login -from-kubernetes
```

## Setting GitHub secrets

## Run the app in Kubernetes


Run in this directory to build and run the app:

```shell
run.sh
```
