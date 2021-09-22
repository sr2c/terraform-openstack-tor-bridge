resource "random_integer" "obfs_port" {
  min = 1025
  max = 65535
}

resource "random_integer" "or_port" {
  min = 1025
  max = 65535
}

resource "openstack_compute_instance_v2" "this" {
  name        = module.this.id
  provider    = openstack
  image_name  = var.image_name
  flavor_name = var.flavor_name
  key_pair    = var.ssh_keypair_name
  network {
    name      = var.external_network_name
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt update",
      "sudo apt install -y apt-transport-https",
      "echo 'deb     [signed-by=/usr/share/keyrings/tor-archive-keyring.gpg] https://deb.torproject.org/torproject.org buster main' | sudo tee /etc/apt/sources.list.d/tor.list",
      "echo 'deb-src [signed-by=/usr/share/keyrings/tor-archive-keyring.gpg] https://deb.torproject.org/torproject.org buster main' | sudo tee -a /etc/apt/sources.list.d/tor.list",
      "wget -O- https://deb.torproject.org/torproject.org/A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89.asc | gpg --dearmor | sudo tee /usr/share/keyrings/tor-archive-keyring.gpg >/dev/null",
      "sudo apt update",
      "sudo apt install -y tor deb.torproject.org-keyring obfs4proxy"
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
    Nickname ${module.this.id}
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