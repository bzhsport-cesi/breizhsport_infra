###############################################################################
# 1) Réseau
###############################################################################

data "warren_network" "public" {
  name = var.network_name
}

###############################################################################
# 2) Création de la VM
###############################################################################

resource "warren_virtual_machine" "denvr_vm" {
  count             = var.vm_number
  disk_size_in_gb   = var.disk_size
  memory            = var.ram_number
  name              = "${var.vm_prefix}-${count.index}"
  username          = var.username
  os_name           = var.os_name
  os_version        = var.os_version
  vcpu              = var.cpu_number
  network_uuid      = data.warren_network.public.id
  reserve_public_ip = false
  public_key        = var.ssh_public_key
}

###############################################################################
# 3) Attribution d’IP publique
###############################################################################

resource "warren_floating_ip" "denvr_ip" {
  count       = var.vm_number
  name        = "ip-${var.vm_prefix}-${count.index}"
  assigned_to = warren_virtual_machine.denvr_vm[count.index].id
}

###############################################################################
# 4) Enregistrement DNS Cloudflare
###############################################################################

resource "cloudflare_record" "frontend_dns" {
  zone_id = var.cloudflare_zone_id
  name    = var.frontend_domain
  type    = "A"
  value   = warren_floating_ip.denvr_ip[0].address
  ttl     = 1
  proxied = true
}

###############################################################################
# 5) Génération d’un inventaire Ansible
###############################################################################

resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/inventory.tmpl", {
    public_ips = warren_floating_ip.denvr_ip.*.address
    user       = var.username
  })
  filename = "${path.module}/rendered_inventory"
}

###############################################################################
# 6) Provisioning Ansible
###############################################################################

resource "null_resource" "ansible_provision" {
  depends_on = [
    warren_floating_ip.denvr_ip,
    warren_virtual_machine.denvr_vm,
    cloudflare_record.frontend_dns,
  ]

  connection {
    type        = "ssh"
    user        = var.username
    private_key = var.ssh_private_key
    host        = warren_floating_ip.denvr_ip[0].address
  }

  provisioner "file" {
    source      = local_file.ansible_inventory.filename
    destination = "/tmp/inventory"
  }

  provisioner "file" {
    source      = "${path.module}/playbook.yml"
    destination = "/tmp/playbook.yml"
  }

  provisioner "file" {
    source      = "${path.module}/docker-compose.yml.j2"
    destination = "/tmp/docker-compose.yml.j2"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get remove -y needrestart",
      "echo 'DPkg::Options { \"--force-confdef\"; \"--force-confold\"; };' | sudo tee -a /etc/apt/apt.conf.d/99force-no-prompt",
      "echo '* libraries/restart-without-asking boolean true' | sudo debconf-set-selections",
      "sudo apt-get update -y",
      "sudo apt-get install -y python3-pip python3-dev build-essential",
      "pip3 install --user ansible",
      "export PATH=$HOME/.local/bin:$PATH && ansible-galaxy collection install community.docker",
      "export PATH=$HOME/.local/bin:$PATH && ansible-playbook -i /tmp/inventory /tmp/playbook.yml -vvv --extra-vars 'image_name=${var.front_image_tag} registry_username=${var.registry_username} registry_token=${var.registry_token} frontend_domain=${var.frontend_domain} letsencrypt_email=${var.letsencrypt_email}'"
    ]
  }
}