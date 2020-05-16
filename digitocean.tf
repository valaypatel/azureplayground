# Set the variable value in *.tfvars file
# or using -var="do_token=..." CLI option
variable "do_token" {}
variable "do_ssh_pub" {}
variable "do_ssh_private" {}
variable "coder_password" {}

# Configure the DigitalOcean Provider
provider "digitalocean" {
  token = var.do_token
}

resource "digitalocean_volume" "galaxy-data" {
  region                  = "nyc1"
  name                    = "galaxy-work"
  size                    = 20
  initial_filesystem_type = "ext4"
  description             = "Work Data"
}

# Create a coder-server
resource "digitalocean_droplet" "galaxy-vs-code" {
  image  = "code-server-18-04"
  name   = "galaxycode-server"
  region = "nyc1"
  size   = "s-2vcpu-2gb"
  ssh_keys = [
    var.do_ssh_pub
    ]
  connection {
    user = "root"
    type = "ssh"
    host = digitalocean_droplet.galaxy-vs-code.ipv4_address
    private_key = var.do_ssh_private
    timeout = "2m"
  }

  provisioner "remote-exec" {
    inline = [
      "export PATH=$PATH:/usr/bin",
      # install nginx
      "sudo rm -rf /etc/code-server/pass",
      "sudo echo ${var.coder_password} > /etc/code-server/pass",
    ]
  }

  provisioner "remote-exec" {
    inline = [ "reboot" ]
    on_failure = "continue"
    connection { host = self.ipv4_address }
  }
}

resource "digitalocean_volume_attachment" "galaxy-attachement" {
  droplet_id = digitalocean_droplet.galaxy-vs-code.id
  volume_id  = digitalocean_volume.galaxy-data.id
}