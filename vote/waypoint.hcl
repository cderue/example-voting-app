project = "voting-app-vote"

variable "image" {
  type        = string
  description = "Image name for the built image in the Docker registry."
}

variable "tag" {
  default     = "latest"
  type        = string
  description = "Image tag for the image"
}


app "vote" {
    labels = {
        "service" = "vote",
        "env"     = "dev"
    }

    build {
        use "docker" {
            #builder= "gcr.io/buildpacks/builder:v1"
        }
        registry {
            use "docker" {
                /*auth {
                    hostname = var.registry_dns
                    username = var.registry_user_name
                    password = var.registry_password
                }*/
                image = var.image
                tag   = var.tag
                //local = false
            }
        }
    }

    deploy {
        use "kubernetes" {
            pod {
                container {
                    port {
                        name = "http"
                        port = 4000
                    }
                }
            }
        }
    }

    release {
        use "kubernetes" {
            load_balancer = true
            ports = [
                {
                    name = "http"
                    port = 5000
                    target_port = 4000
                }
            ]
        }
    }
}