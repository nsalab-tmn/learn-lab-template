terraform {
  required_providers {
    vsphere = {
      source  = "hashicorp/vsphere"
      version = "~> 2.4" # matches the set mirrored in the learn-lab-deploy image (lab-deploy#58)
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }
}

# Auth is read from the AMBIENT env by the provider (passthrough, lab-deploy#58 / KB#107):
# VSPHERE_SERVER / VSPHERE_USER / VSPHERE_PASSWORD / VSPHERE_ALLOW_UNVERIFIED_SSL — learn-infra
# wires them onto the worker service (infra#76). Nothing vCenter-specific is hardcoded here;
# every inventory value is a variable fed via TF_VAR_VSPHERE_* (lab-compute-and-variants#120).
provider "vsphere" {}

data "vsphere_datacenter" "dc" {
  name = var.VSPHERE_DATACENTER
}
data "vsphere_compute_cluster" "cluster" {
  name          = var.VSPHERE_CLUSTER
  datacenter_id = data.vsphere_datacenter.dc.id
}
data "vsphere_datastore" "ds" {
  name          = var.VSPHERE_DATASTORE
  datacenter_id = data.vsphere_datacenter.dc.id
}
data "vsphere_network" "net" {
  name          = var.VSPHERE_NETWORK
  datacenter_id = data.vsphere_datacenter.dc.id
}
data "vsphere_virtual_machine" "template" {
  name          = var.VSPHERE_TEMPLATE
  datacenter_id = data.vsphere_datacenter.dc.id
}

resource "random_password" "ssh" {
  length  = 20
  special = false
}

# SSH provisioning via cloud-init delivered over guestinfo (the VMware datasource) — no vCenter
# guest-customization spec, cloud-init owns the user + network. Creates `learner` with the
# generated password and enables password SSH; VLAN_2310's DHCP+internet supply the address and
# any cloud-init fetch. If template-ubuntu-24 lacks cloud-init/VMware-Tools, the first
# deploy -> SSH-grade surfaces it (fail-forward; rebuild the template + re-run, pre-authorized).
locals {
  userdata = base64encode(<<-EOT
    #cloud-config
    users:
      - name: learner
        sudo: ALL=(ALL) NOPASSWD:ALL
        shell: /bin/bash
        lock_passwd: false
    ssh_pwauth: true
    chpasswd:
      expire: false
      list: |
        learner:${random_password.ssh.result}
    runcmd:
      - [ systemctl, enable, --now, ssh ]
  EOT
  )
  metadata = base64encode(<<-EOT
    instance-id: lab-${var.instance_id}
    local-hostname: lab-${var.instance_id}
    network:
      version: 2
      ethernets:
        ens192:
          dhcp4: true
  EOT
  )
}

resource "vsphere_virtual_machine" "lab" {
  name             = "lab-${var.instance_id}"
  resource_pool_id = data.vsphere_compute_cluster.cluster.resource_pool_id
  datastore_id     = data.vsphere_datastore.ds.id
  folder           = var.VSPHERE_FOLDER

  num_cpus  = 2
  memory    = 2048
  guest_id  = data.vsphere_virtual_machine.template.guest_id
  scsi_type = data.vsphere_virtual_machine.template.scsi_type

  # template-ubuntu-24 is an EFI template; the clone must match its firmware or power-on fails
  # with "ACPI motherboard layout requires EFI" (the default is bios). Secure Boot is left off
  # (the template doesn't require it); add efi_secure_boot_enabled = true if a template ever does.
  firmware = "efi"

  # Keep the lab discoverable by instance/variant for an orphan-reaper.
  annotation = "learn.instance_id=${var.instance_id} learn.variant_seed=${var.variant_seed}"

  network_interface {
    network_id   = data.vsphere_network.net.id
    adapter_type = try(data.vsphere_virtual_machine.template.network_interface_types[0], "vmxnet3")
  }

  disk {
    label            = "disk0"
    size             = data.vsphere_virtual_machine.template.disks[0].size
    thin_provisioned = data.vsphere_virtual_machine.template.disks[0].thin_provisioned
    eagerly_scrub    = data.vsphere_virtual_machine.template.disks[0].eagerly_scrub
  }

  clone {
    template_uuid = data.vsphere_virtual_machine.template.id
  }

  # Deliver cloud-init via guestinfo (cloud-init owns user/network; no customize{} spec).
  extra_config = {
    "guestinfo.userdata"          = local.userdata
    "guestinfo.userdata.encoding" = "base64"
    "guestinfo.metadata"          = local.metadata
    "guestinfo.metadata.encoding" = "base64"
  }

  # Wait for VMware Tools to report an IP so lab_ip is populated for the assessment testbed.
  wait_for_guest_net_timeout = 5
}
