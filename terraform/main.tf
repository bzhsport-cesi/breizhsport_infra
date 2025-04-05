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
# 4) Génération d’un inventaire Ansible
###############################################################################

resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/inventory.tmpl", {
    public_ips = warren_floating_ip.denvr_ip.*.address
    user       = var.username
  })
  filename = "${path.module}/rendered_inventory"
}

###############################################################################
# 5) Provisioning Ansible
###############################################################################

resource "null_resource" "ansible_provision" {
  depends_on = [
    warren_floating_ip.denvr_ip,
    warren_virtual_machine.denvr_vm,
  ]

  connection {
    type        = "ssh"
    user        = var.username
    private_key = var.ssh_private_key
    host        = warren_floating_ip.denvr_ip[0].address
  }

  # Copie de l’inventaire généré
  provisioner "file" {
    source      = local_file.ansible_inventory.filename
    destination = "/tmp/inventory"
  }

  # Copie du playbook et du template Docker Compose
  provisioner "file" {
    source      = "${path.module}/../playbook.yml"
    destination = "/tmp/playbook.yml"
  }

  provisioner "file" {
    source      = "${path.module}/../templates/docker-compose.yml.j2"
    destination = "/tmp/docker-compose.yml.j2"
  }

  # Exécution du playbook Ansible
  provisioner "remote-exec" {
    inline = [
      # Supprimer les prompts interactifs
      "echo '* libraries/restart-without-asking boolean true' | sudo debconf-set-selections",

      # Mise à jour + installation d'Ansible
      "sudo apt-get update -yq && sudo apt-get install -yq ansible python3-pip",

      # Installer les collections Ansible nécessaires
      "ansible-galaxy collection install community.docker",

      # Lancer le playbook
      "ansible-playbook -i /tmp/inventory /tmp/playbook.yml -vvv --extra-vars 'image_name=${var.front_image_tag} registry_username=${var.registry_username} registry_token=${var.registry_token}'"
    ]
  }
}