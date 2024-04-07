# Install the powershell-yaml module
Install-Module -Name powershell-yaml

# Read the YAML file
$infra_details = ConvertFrom-Yaml (Get-Content -Raw -Path test.yml) | Select-Object -ExpandProperty infra_details

# Iterate over the infra details
foreach ($infra_detail in $infra_details) {
  $resource_group_name = $infra_detail.resource_group_name
  $virtual_machines = $infra_detail.virtual_machines

  # Iterate over the virtual machines
  foreach ($virtual_machine in $virtual_machines) {
    $vm_name = $virtual_machine.name

    # Get the network interface associated with the VM
    $nic_name = az vm show --resource-group $resource_group_name --name $vm_name --query 'networkProfile.networkInterfaces[0].id' --output tsv | Split-Path -Leaf

    # Dissociate the public IP address from the network interface
    az network nic ip-config update --name ipconfig1 --nic-name $nic_name --resource-group $resource_group_name --remove PublicIPAddress
  }
}