# AIO - Validate Pull Request pipeline

To run **AIO - Validate Pull Request** pipeline some secrets and variable should be configured. In order to do so in GitHub repo settings search for **Secrets and variables->Actions** section.

1. Under **Variables** tab add a new variable `DEVTEST_SUBSCRIPTION_ID`. This would be the subscription you would like to deploy your resources to. You can run the next script to define this variable:

    ```bash
    DEVTEST_SUBSCRIPTION_ID=$(az account show --query id --output tsv)
    ```

1. Under **Secrets** tab add a new secret `AZURE_CREDENTIALS`. This would be the Service Principal resource details for the repository to use when performing GitHub actions.

    1. Create a Service Principal resource for the repository to use when performing GitHub actions.

        ```bash
        # Set Service Principal name
        SP_NAME=<name-provided>
        # Create a Service Principal to perform operations on the provided subscription.
        az ad sp create-for-rbac --name $SP_NAME --role owner --scopes /subscriptions/$DEVTEST_SUBSCRIPTION_ID --json-auth  
        ```

    1. The JSON output from the Service Principal creation command would be the value to copy to `AZURE_CREDENTIALS` secret.
       
1. Under **Secrets** tab add a new secret `CUSTOM_LOCATION_OBJECT_ID`. This is to enable custom locations feature on your Arc Enabled cluster.

   1. Retrieve the value for CUSTOM_LOCATION_OBJECT_ID.
      ```bash
          # If you're using an Azure CLI version lower than 2.37.0, use the following command:
          az ad sp show --id bc313c14-388c-4e7d-a58e-70017303ee3b --query objectId -o tsv

          # If you're using Azure CLI version 2.37.0 or higher, use the following command instead:
          az ad sp show --id bc313c14-388c-4e7d-a58e-70017303ee3b --query id -o tsv
      ```
