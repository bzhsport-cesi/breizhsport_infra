###############################################################################
# 1) Déclaration du réseau
###############################################################################
data "warren_network" "public" {
  name = var.network_name
}

###############################################################################
# 2) Création des VMs
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
# 3) Association d'IP publiques
###############################################################################
resource "warren_floating_ip" "denvr_ip" {
  count       = var.vm_number
  name        = "ip-${var.vm_prefix}-${count.index}"
  assigned_to = warren_virtual_machine.denvr_vm[count.index].id
}

###############################################################################
# 4) Génération de l'inventaire Ansible via templatefile()
###############################################################################
# Cette resource crée localement un fichier "rendered_inventory" en 
# injectant la liste d'adresses IP dans inventory.tmpl
resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/inventory.tmpl", {
    public_ips = warren_floating_ip.denvr_ip.*.address
    user       = var.username
  })
  filename = "${path.module}/rendered_inventory"
}

###############################################################################
# 5) Provisioning Ansible via un null_resource
###############################################################################
# On se connecte en SSH à la première VM (index 0) pour y copier l’inventaire,
# le playbook, puis exécuter Ansible localement sur la VM.
resource "null_resource" "ansible_provision" {

  # S'assure que la VM et l'IP sont créées avant
  depends_on = [
    warren_floating_ip.denvr_ip,
    warren_virtual_machine.denvr_vm,
  ]

  # On se connecte en SSH sur la VM [0]
  connection {
    type        = "ssh"
    user        = var.username
    private_key = var.ssh_private_key
    host        = warren_floating_ip.denvr_ip[0].address
  }

  # Copie de l'inventaire rendu (rendered_inventory) dans la VM
  provisioner "file" {
    source      = local_file.ansible_inventory.filename
    destination = "/tmp/inventory"
  }

  # Copie du playbook dans la VM
  provisioner "file" {
    source      = "../playbook.yml"
    destination = "/tmp/playbook.yml"
  }

  # Installation d'Ansible et exécution du playbook
  provisioner "remote-exec" {
    inline = [
      # Désinstalle "needrestart" pour éviter les prompts interactifs
      "sudo DEBIAN_FRONTEND=noninteractive apt-get -yq remove needrestart || true",

      # Mise à jour + installation Ansible
      "sudo DEBIAN_FRONTEND=noninteractive apt-get update -yq && \
      sudo DEBIAN_FRONTEND=noninteractive apt-get dist-upgrade -yq && \
      sudo DEBIAN_FRONTEND=noninteractive apt-get install -yq ansible python3-pip",

      # Installer la collection Docker
      "ansible-galaxy collection install community.docker",

      # Lancer le playbook
      "ansible-playbook -i /tmp/inventory /tmp/playbook.yml -vvv"
    ]
  }
}
