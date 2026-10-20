# These output names are the tf-dynamic-params.json keys the marking scheme and the
# learn-metadata.json credentialsSchema reference. Keep them stable and identical across
# targets so one marking scheme grades the lab on any target (see the KB multi-target decision).

output "lab_host" {
  description = "Container name — resolvable by learn-assessment via Docker DNS on learn-labs."
  value       = docker_container.lab.name
}

output "lab_ip" {
  description = "Container IP on the learn-labs network (never localhost)."
  value       = one([for n in docker_container.lab.network_data : n.ip_address if n.network_name == "learn-labs"])
}

output "ssh_port" {
  description = "linuxserver/openssh-server listens on 2222."
  value       = 2222
}

output "ssh_user" {
  value = "learner"
}

output "ssh_password" {
  value     = random_password.ssh.result
  sensitive = true
}
