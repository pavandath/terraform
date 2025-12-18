# Instance Template with named_port
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

  metadata_startup_script = <<-EOF
    #!/bin/bash
    sudo apt update -y
    sudo apt install -y ansible git
    git clone https://github.com/pavandath/ansible.git /tmp/config
    cd /tmp/config/ansible
    ansible-playbook -i "localhost," -c local playbook.yml
  EOF

  lifecycle {
    create_before_destroy = true
  }
}

# MIG with named_port inheritance
resource "google_compute_instance_group_manager" "web_mig" {
  name               = "web-mig-manager"
  base_instance_name = "web-instance"
  zone               = "asia-south1-a"
  target_size        = 2

  version {
    instance_template = google_compute_instance_template.web_template.id
  }

  auto_healing_policies {
    health_check      = google_compute_health_check.health_check.id
    initial_delay_sec = 300
  }

  named_port {
    name = "http"
    port = 80
  }
}
