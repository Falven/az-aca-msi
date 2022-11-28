# az-aca-msi

Proof of concept for a scalable Dotnet application running on Azure Container Apps and pulling secrets from a KeyVault using a Managed Service Identitiy.

## deploy.ps1
This powershell script contains the az commands necessary to create a resource group, Azure Container Registry, and to build and push the Dotnet container to the registry before creating a bicep deployment.
I would reocmmend running the commands one at a time.
