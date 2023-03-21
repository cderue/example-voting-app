project = "voting-app-worker"

variable "image" {
  type        = string
  description = "Image name for the built image in the Docker registry."
  default = ""
}

variable "tag" {
  default     = "latest"
  type        = string
  description = "Image tag for the image"
}

app "worker" {
    labels = {
        "service" = "worker",
        "env"     = "dev"
    }
    build {
        use "pack" {
            builder = "paketobuildpacks/builder:full"
        }
        registry {
            use "docker" {
                image = var.image
                tag   = var.tag
                #local = true
            }
        }
    }

    deploy {
        use "kubernetes" {
            pod {
                container {
                    port {
                        name = "tcp"
                        port = 5000
                    }
                }
            }
        }
    }

    release {
        use "kubernetes" {
            ports = [
                {
                    name = "tcp"
                    port = 5000
                    target_port = 5000
                }
            ]
        }
    }
}