az network vnet create --resource-group FlameGraphTest --name FlameGraphVNet --address-prefix 10.0.0.0/16  --subnet-name FlameGraphSubnet --subnet-prefix 10.0.0.0/24

az network nsg create --resource-group FlameGraphTest --name FlameGraphNSG

# Add SSH rule to NSG
az network nsg rule create --resource-group FlameGraphTest --nsg-name FlameGraphNSG --name AllowSSH  --priority 1000 --destination-port-ranges 22 --source-address-prefixes '*' --protocol Tcp --access Allow

# Add PostgreSQL rule to NSG
az network nsg rule create --resource-group FlameGraphTest --nsg-name FlameGraphNSG --name AllowPostgreSQL --priority 1010 --destination-port-ranges 5432 --source-address-prefixes '*' --protocol Tcp --access Allow

# Add HTTP rule to NSG for FlameGraph visualization
az network nsg rule create --resource-group FlameGraphTest --nsg-name FlameGraphNSG --name AllowHTTP --priority 1020 --destination-port-ranges 8000 --source-address-prefixes '76.37.145.146/32' --protocol Tcp --access Allow

# Create the three VMs
# 1. DB Server VM
az vm create --resource-group FlameGraphTest --name db-server-vm --image Ubuntu2204 --size Standard_D2s_v3 --admin-username azureuser --ssh-key-values C:\Users\nikhi\Documents\.ssh\vmpub.pem --nsg FlameGraphNSG --vnet-name FlameGraphVNet --subnet FlameGraphSubnet --public-ip-address-allocation static

# 2. Application VM
az vm create --resource-group FlameGraphTest --name app-vm --image Ubuntu2204 --size Standard_D2s_v3 --admin-username azureuser --ssh-key-values C:\Users\nikhi\Documents\.ssh\vmpub.pem --nsg FlameGraphNSG --vnet-name FlameGraphVNet --subnet FlameGraphSubnet  --public-ip-address-allocation static

# Get the public IP addresses
DB_SERVER_IP=$(az vm show --resource-group FlameGraphTest --name db-server-vm --show-details --query publicIps -o tsv)
APP_VM_IP=$(az vm show --resource-group FlameGraphTest --name app-vm --show-details --query publicIps -o tsv)

# Get the private IP addresses
DB_SERVER_PRIVATE_IP=$(az vm show --resource-group FlameGraphTest --name db-server-vm --show-details --query privateIps -o tsv)
APP_VM_PRIVATE_IP=$(az vm show --resource-group FlameGraphTest --name app-vm --show-details --query privateIps -o tsv)

# Display the IPs
echo "DB Server Public IP: $DB_SERVER_IP, Private IP: $DB_SERVER_PRIVATE_IP"
echo "App VM Public IP: $APP_VM_IP, Private IP: $APP_VM_PRIVATE_IP"