# Step 5: Setup Load Balancer

# 1. Backend Service - Connects the Load Balancer to your MIG
resource "google_compute_backend_service" "web_backend" {
  name        = "web-backend-service"
  protocol    = "HTTP"
  port_name   = "http"
  timeout_sec = 10
  enable_cdn  = false

  # This connects the backend service to your Managed Instance Group (MIG)
  backend {
    group = google_compute_instance_group_manager.web_mig.instance_group
  }

  # Uses the health check you already created
  health_checks = [google_compute_health_check.health_check.id]
}

# 2. URL Map - Defines routing rules (all traffic goes to our backend here)
resource "google_compute_url_map" "web_url_map" {
  name            = "web-url-map"
  default_service = google_compute_backend_service.web_backend.id
}

# 3. Target HTTP Proxy - Entry point for the load balancer
resource "google_compute_target_http_proxy" "http_proxy" {
  name    = "web-http-proxy"
  url_map = google_compute_url_map.web_url_map.id
}

# 4. Global Forwarding Rule - Assigns the public IP and port
resource "google_compute_global_forwarding_rule" "http_rule" {
  name       = "http-global-forwarding-rule"
  target     = google_compute_target_http_proxy.http_proxy.id
  port_range = "80"
  ip_protocol = "TCP"
}
