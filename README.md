# Enterprise Hub-and-Spoke Infrastructure as Code (Azure - Bicep & Terraform)

Dit project demonstreert een productie-waardige, enterprise-grade **Hub-and-Spoke netwerkarchitectuur** in Microsoft Azure, volledig geautomatiseerd via Infrastructure as Code (IaC) met behulp van Microsoft Bicep en Terraform.

---

## 🏗️ Architectuur Overzicht

De infrastructuur is opgesplitst in logische, geïsoleerde lagen met elk een eigen `terraform.tfstate` bestand (remote backend opgeslagen in de centrale Azure Storage Account).

1. **Deel 1 - Bootstrap (Bicep):**
   * Creëert een centrale Resource Group en een Standard LRS Storage Account met Blob Container voor veilige remote state-beheer.
2. **Deel 2 - Hub Netwerk & Beveiliging (Terraform):**
   * Centraal VNet (`10.0.0.0/24`) met `frontend-sn`, `backend-sn` en `AzureBastionSubnet`.
   * **Azure Key Vault** (Standard SKU) met beveiligde Private Endpoint koppeling.
   * **Azure Bastion** (Developer SKU) voor veilige management-toegang.
   * **Azure Container Registry (ACR)** (Basic SKU) voor container images.
3. **Deel 3 - Spoke 1 (Terraform):**
   * VNet (`10.0.1.0/24`) gekoppeld aan de Hub via VNet Peering.
   * Linux VM (`Standard_B1ls`) zonder publiek IP-adres.
   * Automatisch gegenereerd administratief wachtwoord (`random_password`) veilig opgeslagen in de Key Vault.
   * Azure Container Instance (ACI) die een Nginx webserver draait.
4. **Deel 4 - Spoke 2 (Terraform):**
   * VNet (`10.0.2.0/24`) gekoppeld aan de Hub via VNet Peering.
   * **Azure Database for MySQL Flexible Server** (`B_Standard_B1ms`).
   * Azure Container Instance (ACI) met `phpmyadmin` voor grafisch databasebeheer.

---

## 🚀 Deployment Stappenplan

Voer de volgende commando's sequentieel uit in je terminal per map:

### Stap 1: Bootstrap (Bicep)
```bash
cd bicep/bootstrap
az deployment sub create -f main.bicep -l francecentral

cd terraform/hub
terraform init
terraform apply

cd terraform/spoke1
terraform init
terraform apply

cd terraform/spoke2
terraform init
terraform apply
```
🔍 Outputs Opvragen
Om specifieke eindpunten of login-gegevens op te vragen per laag:

terraform output

Of voor specifieke outputs zoals de phpMyAdmin URL of ACR login server:

terraform output -raw phpmyadmin_url
terraform output -raw acr_login_server