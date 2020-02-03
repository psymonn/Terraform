# Setup vSphere Provider and login
provider "vsphere" {
  user           = "administrator@vsphere.local"
  password       = "*****"
  vsphere_server = "172.17.5.20"

  # if you have a self-signed cert
  allow_unverified_ssl = true
}


# Data for Resources
data "vsphere_datacenter" "dc" {
  name = "Datacenter1"
}

data "vsphere_datastore" "datastore" {
  name          = "datastore2_SSD"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_datastore" "iso_datastore" {
  name          = "datastore2_SSD"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

# data "vsphere_compute_cluster" "cluster" {
#   name          = "Mgt3_Cluster"
#   datacenter_id = "${data.vsphere_datacenter.dc.id}"
# }
data "vsphere_resource_pool" "pool_id" {
  #name          = "${data.vsphere_compute_cluster.cluster.resource_pool_id}"
  name          = "Normal Resource Pool"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_network" "network" {
  name          = "DPG-Management Network"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_virtual_machine" "template" {
  name          = "Windows Server 2012 Template (converted)"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

/*
# Build a 2012 R2 VM from iso file
resource "vsphere_virtual_machine" "New-VM" {
  name             = "2012R2-VM-Terraform"
  resource_pool_id = "${data.vsphere_resource_pool.pool_id.id}"
  datastore_id     = "${data.vsphere_datastore.datastore.id}"

  num_cpus = 1
  memory   = 2048
  guest_id = "windows8Server64Guest"
  scsi_type = "lsilogic-sas"
  wait_for_guest_net_timeout = 0

  network_interface {
    network_id = "${data.vsphere_network.network.id}"
  }

  disk {
    name = "2012R2-VM-Terraform.vmdk"
    size = 25
    thin_provisioned = true
  }

  cdrom {
    datastore_id = "${data.vsphere_datastore.iso_datastore.id}"
    path         = "en_windows_server_2012_r2_x64_dvd_2707946.iso"
  }
}
*/

# Clone a 2012 R2 Template
# This create a new virtual machine from a template
resource "vsphere_virtual_machine" "New_VM_From_Template" {
  name             = "2012R2-Terraform-01"
  resource_pool_id = "${data.vsphere_resource_pool.pool_id.id}"
  datastore_id     = "${data.vsphere_datastore.datastore.id}"

  num_cpus = 4
  memory   = 8192
  guest_id = "${data.vsphere_virtual_machine.template.guest_id}"
  scsi_type = "${data.vsphere_virtual_machine.template.scsi_type}"

  network_interface {
    network_id   = "${data.vsphere_network.network.id}"
    adapter_type = "${data.vsphere_virtual_machine.template.network_interface_types[0]}"
  }

  disk {
    name             = "2012R2-Terraform-01.vmdk"
    size             = "${data.vsphere_virtual_machine.template.disks.0.size}"
    eagerly_scrub    = "${data.vsphere_virtual_machine.template.disks.0.eagerly_scrub}"
    thin_provisioned = "${data.vsphere_virtual_machine.template.disks.0.thin_provisioned}"
  }

  clone {
    template_uuid = "${data.vsphere_virtual_machine.template.id}"

  }
}
