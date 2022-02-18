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
}

data "openstack_images_image_v2" "block_device" {
  count       = var.require_block_device_creation ? 1 : 0
  name        = var.image_name
  most_recent = true
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
    ignore_changes = [image_name]
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt update",
      "sudo apt upgrade -y",
      "sudo apt install -y apt-transport-https gnupg2",
      "echo 'deb     [signed-by=/usr/share/keyrings/tor-archive-keyring.gpg] https://deb.torproject.org/torproject.org bullseye main' | sudo tee /etc/apt/sources.list.d/tor.list",
      "echo 'deb-src [signed-by=/usr/share/keyrings/tor-archive-keyring.gpg] https://deb.torproject.org/torproject.org bullseye main' | sudo tee -a /etc/apt/sources.list.d/tor.list",
      "wget -O- https://deb.torproject.org/torproject.org/A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89.asc | gpg --dearmor | sudo tee /usr/share/keyrings/tor-archive-keyring.gpg >/dev/null",
      "sudo apt update",
      "sudo apt install -y tor tor-geoipdb deb.torproject.org-keyring obfs4proxy"
    ]
  }

  provisioner "file" {
    content = <<-EOT
    BridgeRelay 1
    ORPort ${random_integer.or_port.result}
    ServerTransportPlugin obfs4 exec /usr/bin/obfs4proxy
    ServerTransportListenAddr obfs4 0.0.0.0:${random_integer.obfs_port.result}
    ExtORPort auto
    ContactInfo ${var.contact_info}
    Nickname ${replace(title(module.this.id), module.this.delimiter, "")}
    BridgeDistribution ${var.distribution_method}
    EOT
    destination = "/home/debian/torrc"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mv /home/debian/torrc /etc/tor/torrc",
      "sudo chown root:root /etc/tor/torrc",
      "sudo chmod 644 /etc/tor/torrc",
      "sudo systemctl restart tor"
    ]
  }

  connection {
    host = self.access_ip_v4
    type = "ssh"
    user = var.ssh_username
  }
}

module "bridgeline" {
  source  = "matti/resource/shell"
  version = "1.5.0"
  command = "ssh -o StrictHostKeyChecking=no ${var.ssh_username}@${openstack_compute_instance_v2.this.access_ip_v4} sudo cat /var/lib/tor/pt_state/obfs4_bridgeline.txt | tail -n 1"
}

module "fingerprint_ed25519" {
  source  = "matti/resource/shell"
  version = "1.5.0"
  command = "ssh -o StrictHostKeyChecking=no ${var.ssh_username}@${openstack_compute_instance_v2.this.access_ip_v4} sudo cat /var/lib/tor/fingerprint-ed25519"
}

module "fingerprint_rsa" {
  source  = "matti/resource/shell"
  version = "1.5.0"
  command = "ssh -o StrictHostKeyChecking=no ${var.ssh_username}@${openstack_compute_instance_v2.this.access_ip_v4} sudo cat /var/lib/tor/fingerprint"
}

module "hashed_fingerprint" {
  source  = "matti/resource/shell"
  version = "1.5.0"
  command = "ssh -o StrictHostKeyChecking=no ${var.ssh_username}@${openstack_compute_instance_v2.this.access_ip_v4} sudo cat /var/lib/tor/hashed-fingerprint"
}