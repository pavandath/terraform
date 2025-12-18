provider "google" {
  project = "your-gcp-project"
  region  = "asia-south1"  # Changed region to Mumbai
}

resource "google_compute_instance_template" "web_template" {
  name_prefix = "web-template-"
  machine_type = "e2-micro"
  tags = ["http-server"]

  disk {
    source_image = "ubuntu-os-cloud/ubuntu-2204-lts"
  }

  network_interface {
    network = "default"
    access_config {}
  }
  zone = "asia-south1-a" 

  metadata_startup_script = <<-EOF
    #!/bin/bash
    sudo apt update
    sudo apt install -y ansible git
    git clone https://github.com/pavandath/ansible.git /tmp/config
    cd /tmp/config/ansible
    ansible-playbook -i "localhost," -c local playbook.yml
  EOF
}

resource "google_compute_health_check" "health_check" {
  name = "web-health-check"
  http_health_check {
    port = 80
  }
}
