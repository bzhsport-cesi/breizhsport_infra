
data "warren_network" "public" {
  name = "${var.network_name}"
}

# Resources managed by Terraform
resource "warren_virtual_machine" "denvr_vm" {
    count = "${var.vm_number}"
    disk_size_in_gb = "${var.disk_size}"
    memory          = "${var.ram_number}"
    name            = "${var.vm_prefix}-${count.index}"
    username        = "${var.username}"
    os_name         = "${var.os_name}"
    os_version      = "${var.os_version}"
    vcpu            = "${var.cpu_number}"
    network_uuid = data.warren_network.public.id
    reserve_public_ip = false
    public_key = "${var.ssh_public_key}"
}

resource "warren_floating_ip" "denvr_ip" {
  count = "${var.vm_number}"
  name = "ip-${var.vm_prefix}-${count.index}"
  assigned_to = resource.warren_virtual_machine.denvr_vm[count.index].id

  connection {
    type        = "ssh"
    user        = var.username
    private_key = var.ssh_private_key
    host        = self.address
  }
  
# Copie du playbook Ansible vers la VM
  provisioner "file" {
    source      = "../playbook.yml"  # Assurez-vous que Terraform est exécuté depuis `terraform/`
    destination = "/tmp/playbook.yml"
  }

  # Copie de l'inventaire depuis le dossier terraform
  provisioner "file" {
    source      = "inventory.tmpl"  # Fichier présent dans le dossier terraform
    destination = "/tmp/inventory"
  }

  # Exécution du playbook Ansible
  provisioner "remote-exec" {
    inline = [
      "sudo apt update && sudo apt install -y ansible",
      "ansible-playbook -i /tmp/inventory /tmp/playbook.yml -vvv"
    ]
  }
}