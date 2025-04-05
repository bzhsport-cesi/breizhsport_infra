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

  provisioner "file" {
    source      = local_file.ansible_inventory.filename
    destination = "/tmp/inventory"
  }

  provisioner "file" {
    source      = "../playbook.yml"
    destination = "/tmp/playbook.yml"
  }

  provisioner "file" {
    source      = "../templates/docker-compose.yml.j2"
    destination = "/tmp/docker-compose.yml.j2"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update -yq && sudo apt-get install -yq ansible python3-pip",
      "ansible-galaxy collection install community.docker",
      "ansible-playbook -i /tmp/inventory /tmp/playbook.yml -vvv --extra-vars 'image_name=${var.front_image_tag} registry_username=${var.registry_username} registry_token=${var.registry_token}'"
    ]
  }
}