$ProjectName = "msiacapoc"
$Environment = "prod"
$Location = "eastus"
$ResourceGroupName = "rg-${ProjectName}-${Environment}-001"
$RegistryName = "cr${ProjectName}${Environment}001"
$SecretName = "mySecret"
$SecretValue = "Zeiss"
$MCRLogin = "mcr.microsoft.com"
$ACRLogin = "${RegistryName}.azurecr.io"
$AzCliImage = "azure-cli:latest"
$DotnetImage = "msidotnet:latest"
$MCRAzCliContainer = "${MCRLogin}/${AzCliImage}"
$ACRAzCliContainer = "${ACRLogin}/${AzCliImage}"
$ACRDotnetContainer = "${ACRLogin}/${DotnetImage}"

az group create -n $ResourceGroupName -l $Location
az acr create -g $ResourceGroupName -n $RegistryName --sku Basic --admin-enabled true
az acr login -n $RegistryName
docker pull $MCRAzCliContainer
docker tag $MCRAzCliContainer $ACRAzCliContainer
docker push $ACRAzCliContainer
docker build kv -f kv\Dockerfile -t $ACRDotnetContainer
docker push $ACRDotnetContainer
az deployment group create `
    -g $ResourceGroupName `
    -n "${ProjectName}-deployment" `
    -f ./infra/main.bicep `
    -p projectName=$ProjectName `
    environment=$Environment `
    secretName=$SecretName `
    secretValue=$SecretValue `
    registryName=$RegistryName `
    azCliContainer=$ACRAzCliContainer `
    dotnetContainer=$ACRDotnetContainer