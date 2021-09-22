output "bridgeline" {
  value = replace(
            replace(
              replace(module.bridgeline.stdout,
                "<IP ADDRESS>", openstack_compute_instance_v2.this.access_ip_v4),
              "<PORT>", tostring(random_integer.obfs_port.result)),
            "<FINGERPRINT>", module.fingerprint_rsa.stdout)
  sensitive = true
}

output "fingerprint_ed25519" {
  value = module.fingerprint_ed25519.stdout
  sensitive = true
}

output "fingerprint_rsa" {
  value = module.fingerprint_rsa.stdout
  sensitive = true
}

output "hashed_fingerprint" {
  value = module.hashed_fingerprint.stdout
}

output "ip_address" {
  value = openstack_compute_instance_v2.this.access_ip_v4
  sensitive = true
}

output "id" {
  value = module.this.id
}

output "nickname" {
  value = replace(title(module.this.id), module.this.delimiter, "")
}

output "or_port" {
  value = random_integer.or_port.result
  sensitive = true
}

output "obfs_port" {
  value = random_integer.obfs_port.result
  sensitive = true
}