targetScope = 'subscription'

param rgName string = 'rg-tfstate-backend'
param location string = 'francecentral'
param storageAccountName string = 'stgtfstateabdelkarim01'
param containerName string = 'tfstate'

// 1. Maak de Resource Group aan op abonnementsniveau
resource rg 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: rgName
  location: location
}

// 2. Module voor de Storage Account en Container (lost de scope-fout op)
module storageModule './storageModule.bicep' = {
  name: 'deployStorageAccount'
  scope: rg // Hier passen we de scope correct toe op moduul-niveau
  params: {
    storageAccountName: storageAccountName
    location: location
    containerName: containerName
  }
}

output storageAccountName string = storageAccountName
output containerName string = containerName