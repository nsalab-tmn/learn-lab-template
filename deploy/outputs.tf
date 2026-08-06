output "lab_host" {
  value = azurerm_public_ip.pip.ip_address
}

output "ssh_user" {
  value = "learner"
}

output "ssh_password" {
  value     = random_password.ssh.result
  sensitive = true
}

output "variant_seed" {
  value = var.variant_seed
}
