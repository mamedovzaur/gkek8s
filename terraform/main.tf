terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0" # or latest version
    }
  }
}

provider "google" {
  project = "128688545888" # Replace with your GCP project ID
  region  = "us-central1"           # Replace with your desired region
  zone    = "us-central1-f"          # Replace with your desired zone (optional, for node pools)
}

resource "google_container_cluster" "gke_cluster" {
  name               = "zaur-gke-cluster"
  location           = "us-central1-f" # Must match the provider region above.
  remove_default_node_pool = true
  initial_node_count = 1 #initial node count for the default pool that will be removed.

  network    = "default" # or your vpc network
  subnetwork = "default" # or your subnetwork

  ip_allocation_policy {
    cluster_ipv4_cidr_block  = "/14" # Adjust as needed
    services_ipv4_cidr_block = "/20" # Adjust as needed
  }

  master_auth {
    client_certificate_config {
      issue_client_certificate = false
    }
  }

  addons_config {
    http_load_balancing {
      disabled = false
    }
    horizontal_pod_autoscaling {
      disabled = false
    }
  }

  release_channel {
    channel = "REGULAR" # REGULAR, RAPID, STABLE
  }

  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }
}

resource "google_container_node_pool" "primary_nodes" {
  name       = "primary-node-pool"
  location   = "us-central1-f"
  cluster    = google_container_cluster.gke_cluster.name
  node_count = 2

  node_config {
    machine_type = "e2-standard-2"
    preemptible  = false
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]
    disk_size_gb = 50
  }
}

# Get the credentials 
#resource "null_resource" "get-credentials" {
#
# depends_on = [google_container_cluster.gke_cluster] 
# 
# provisioner "local-exec" {
#   command = "gcloud container clusters get-credentials ${google_container_cluster.gke_cluster.name} --zone=us-central1-f"
# }
#}
#
#resource "kubernetes_namespace" "webapp" {
#
# depends_on = [null_resource.get-credentials]
#
# metadata {
#   name = "webapp"
# }
#}


variable "project_id" {
  type = string
  default = "zaurproject"
}