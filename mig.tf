# Step 1: Create Terraform Code
provider "google" {
  project = "siva-477505"  
  region  = "asia-south1"      
}

resource "google_compute_instance_template" "web_template" {
  name_prefix = "web-template-"
  machine_type = "e2-micro"
  tags         = ["http-server"]

  disk {
    source_image = "ubuntu-os-cloud/ubuntu-2204-lts"
  }

  network_interface {
    network = "default"
    access_config {
      # Ephemeral public IP
    }
  }

  metadata_startup_script = <<-EOF
    #!/bin/bash
    sudo apt update
    sudo apt install -y ansible git
    git clone https://github.com/pavandath/ansible.git /tmp/config
    cd /tmp/config/ansible
    ansible-playbook -i "localhost," -c local playbook.yml
  EOF
}

resource "google_compute_instance_group_manager" "web_mig" {
  name               = "web-mig-manager"
  base_instance_name = "web-instance"
  zone               = "asia-south1-a"
  target_size        = 2               

  version {
    instance_template = google_compute_instance_template.web_template.id
  }
}

# Autoscaler to scale up to five instances (Step 2 continued)
resource "google_compute_autoscaler" "web_autoscaler" {
  name   = "web-autoscaler"
  zone   = "asia-south1-a"
  target = google_compute_instance_group_manager.web_mig.id

  autoscaling_policy {
    max_replicas    = 5 # Scale up to five instances
    min_replicas    = 2
    cooldown_period = 60 # Seconds

    cpu_utilization {
      target = 0.7 # Scale when CPU utilization is above 70%
    }
  }
}
