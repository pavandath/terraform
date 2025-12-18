
provider "google" {
  project = "your-gcp-project"
  region  = "us-central1"
}

resource "google_compute_instance_template" "web_template" {
  name_prefix = "web-template-"
  machine_type = "e2-micro"
  tags = ["http-server"]

  disk {
    source_image = "debian-cloud/debian-11"
  }

  network_interface {
    network = "default"
    access_config {}
  }

  metadata_startup_script = <<-EOF
    #!/bin/bash
    sudo apt update
    sudo apt install -y ansible git
    git clone https://github.com/pavandath/ansible.git /tmp/config
    cd /tmp/config
    ansible-playbook -i "localhost," -c local playbook.yml
  EOF
}

resource "google_compute_health_check" "health_check" {
  name = "web-health-check"
  http_health_check {
    port = 80
  }
}

resource "google_compute_instance_group_manager" "web_mig" {
  name               = "web-mig"
  base_instance_name = "web-instance"
  zone               = "us-central1-a"
  target_size        = 2

  version {
    instance_template = google_compute_instance_template.web_template.id
  }

  auto_healing_policies {
    health_check      = google_compute_health_check.health_check.id
    initial_delay_sec = 300
  }
}

resource "google_compute_autoscaler" "autoscaler" {
  name   = "web-autoscaler"
  zone   = "us-central1-a"
  target = google_compute_instance_group_manager.web_mig.id

  autoscaling_policy {
    max_replicas    = 5
    min_replicas    = 2
    cooldown_period = 60

    cpu_utilization {
      target = 0.7
    }
  }
}
