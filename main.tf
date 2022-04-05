resource "random_integer" "obfs_port" {
  min = 1025
  max = 65535
}

resource "random_integer" "or_port" {
  min = 1025
  max = 65535
}

resource "openstack_compute_keypair_v2" "this" {
  provider   = openstack
  name       = module.this.id
  public_key = var.ssh_key
  region     = var.region

  lifecycle {
    ignore_changes = [public_key]
  }
}

data "openstack_images_image_v2" "block_device" {
  count       = var.require_block_device_creation ? 1 : 0
  name        = var.image_name
  most_recent = true
}

module "torrc" {
  source = "sr2c/torrc/null"
  version = "0.0.4"
  bridge_relay = 1
  or_port = random_integer.or_port.result
  server_transport_plugin = "obfs4 exec /usr/bin/obfs4proxy"
  server_transport_listen_addr = "obfs4 0.0.0.0:${random_integer.obfs_port.result}"
  ext_or_port = "auto"
  contact_info = var.contact_info
  nickname = replace(title(module.this.id), module.this.delimiter, "")
  bridge_distribution = var.distribution_method
}

module "user_data" {
  source = "sr2c/tor/cloudinit"
  version = "0.0.4"
  torrc = module.torrc.rendered
}

resource "openstack_compute_instance_v2" "this" {
  name        = module.this.id
  region      = var.region
  image_name  = var.image_name
  flavor_name = var.flavor_name
  key_pair    = openstack_compute_keypair_v2.this.name
  network {
    name      = var.external_network_name
  }

  user_data = module.user_data.rendered

  dynamic "block_device" {
    for_each = var.require_block_device_creation ? toset([0]) : toset([])
    content {
        uuid = data.openstack_images_image_v2.block_device[block_device.value].id
        source_type           = "image"
        volume_size           = 25
        boot_index            = 0
        destination_type      = "volume"
        delete_on_termination = true
    }
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes = [image_name,user_data]
  }

  provisioner "remote-exec" {
    inline = [
      "cloud-init status --wait"
    ]
  }

  connection {
    host = self.access_ip_v4
    type = "ssh"
    user = var.ssh_user
    timeout = "5m"
  }
}

module "bridgeline" {
  source  = "matti/resource/shell"
  version = "1.5.0"
  command = "ssh -o StrictHostKeyChecking=no ${var.ssh_user}@${openstack_compute_instance_v2.this.access_ip_v4} sudo cat /var/lib/tor/pt_state/obfs4_bridgeline.txt | tail -n 1"
}

module "fingerprint_ed25519" {
  source  = "matti/resource/shell"
  version = "1.5.0"
  command = "ssh -o StrictHostKeyChecking=no ${var.ssh_user}@${openstack_compute_instance_v2.this.access_ip_v4} sudo cat /var/lib/tor/fingerprint-ed25519"
}

module "fingerprint_rsa" {
  source  = "matti/resource/shell"
  version = "1.5.0"
  command = "ssh -o StrictHostKeyChecking=no ${var.ssh_user}@${openstack_compute_instance_v2.this.access_ip_v4} sudo cat /var/lib/tor/fingerprint"
}

module "hashed_fingerprint" {
  source  = "matti/resource/shell"
  version = "1.5.0"
  command = "ssh -o StrictHostKeyChecking=no ${var.ssh_user}@${openstack_compute_instance_v2.this.access_ip_v4} sudo cat /var/lib/tor/hashed-fingerprint"
}