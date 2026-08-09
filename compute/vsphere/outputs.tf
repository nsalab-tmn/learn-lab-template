# Same output KEYS as the other targets (the target-invariant tf-dynamic-params.json contract)
# so one SSH marking scheme grades the lab on any target. learn-lab-deploy exports each value as
# an env var (dashes -> underscores) that the assessment testbed reads via %ENV{...}.

output "lab_host" {
  description = "VM address on the pilot network (no DNS on VLAN_2310 — same as lab_ip)."
  value       = vsphere_virtual_machine.lab.default_ip_address
}

output "lab_ip" {
  description = "VM IP reported by VMware Tools (DHCP on VLAN_2310)."
  value       = vsphere_virtual_machine.lab.default_ip_address
}

output "ssh_port" {
  description = "Standard sshd on the Ubuntu VM (unlike the Docker target's 2222)."
  value       = 22
}

output "ssh_user" {
  value = "learner"
}

output "ssh_password" {
  value     = random_password.ssh.result
  sensitive = true
}
