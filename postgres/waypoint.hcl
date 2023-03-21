project = "voting-app-postgres"

variable "image" {
  type        = string
  description = "Image name for the built image in the Docker registry."
}

variable "tag" {
  default     = "latest"
  type        = string
  description = "Image tag for the image"
}

app "postgres" {
    labels = {
        "service" = "postgres",
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
            static_environment = {
                POSTGRES_USER: "postgres"
                POSTGRES_PASSWORD: "postgres"
            }
            pod {
                container {
                    port {
                        name = "tcp"
                        port = 5432
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
                    port = 5432
                    target_port = 5432
                }
            ]
        }
    }
}