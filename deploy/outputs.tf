output "learn_rg" {
  value       = azurerm_resource_group.learn.name
  description = "Main resource group"
  depends_on  = []
}

output "learn_user" {
  value       = azuread_user.learn.user_principal_name
  description = "description"
  depends_on  = []
}