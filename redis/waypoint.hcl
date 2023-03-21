project = "voting-app-redis"

variable "image" {
  type        = string
  description = "Image name for the built image in the Docker registry."
}

variable "tag" {
  default     = "latest"
  type        = string
  description = "Image tag for the image"
}

app "redis" {
    labels = {
        "service" = "redis",
        "env"     = "dev"
    }
    build {
        use "docker-pull" {
        image = var.image
        tag   = var.tag
        disable_entrypoint = true
    }
}


    deploy {
        use "kubernetes" {
            pod {
                container {
                    port {
                        name = "tcp"
                        port = 6379
                    }
                }
            }
        }
    }

    release {
        use "kubernetes" {
            load_balancer = false
            ports = [
                {
                    name = "tcp"
                    port = 6379
                    target_port = 6379
                }
            ]
        }
    }
}