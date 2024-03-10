---
layout: post
title: Terraform
tags: ['devops', 'server', 'cloud']
icon: server
---

## Digital Ocean App Platform

```terraform
resource "digitalocean_certificate" "do_cert" {
  name    = "weav.ovh"
  type    = "lets_encrypt"
  domains = ["weav.ovh", "*.weav.ovh"]
}

# Create a new container registry
resource "digitalocean_container_registry" "aagy_registry" {
  name                   = "aagy-registry"
  subscription_tier_slug = "starter"
}

resource "digitalocean_app" "aagy_app" {
  depends_on = [ docker_registry_image.aagy_registry_image ]
  
  spec {
    name   = "aagy-app"
    region = "lon1"
    domain {
      name = "aagy.weav.ovh"
      zone = "weav.ovh"
    }

    service {
      name               = "aagy"
      instance_count     = 1
      instance_size_slug = "basic-xxs"
      http_port          = 5549

      image {
        registry_type = "DOCR"
        repository    = "aagy"
        tag = "latest"
        deploy_on_push {
          enabled = true
        }
      }
    }

    ingress {
      rule {
        component {
          name = "aagy"
        }
        match {
          path {
            prefix = "/"
          }
        }
        cors {
          allow_origins {
            regex = ".*"
          }
        }
      }     
    }

        
  }
}
```

## Docker Registry

```
resource "digitalocean_container_registry_docker_credentials" "aagy_registry_docker_credentials" {
  registry_name = "aagy-registry"
  write = true
  depends_on = [ digitalocean_container_registry.aagy_registry ]
}

provider "docker" {
  registry_auth {
    address             = digitalocean_container_registry.aagy_registry.server_url
    config_file_content = digitalocean_container_registry_docker_credentials.aagy_registry_docker_credentials.docker_credentials
  }
}

resource "docker_registry_image" "aagy_registry_image" {
  name          = docker_image.aagy.name
  keep_remotely = false
  depends_on = [ docker_image.aagy, digitalocean_container_registry_docker_credentials.aagy_registry_docker_credentials ]
}

resource "docker_image" "aagy" {
  name         = "registry.digitalocean.com/aagy-registry/aagy"
  build {
    context = "../../"
    dockerfile = ".docker/Dockerfile"
    tag = ["registry.digitalocean.com/aagy-registry/aagy:latest"]
  }
}
```

## Digital Ocean Droplet
```
terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

# Set the variable value in *.tfvars file
# or using -var="do_token=..." CLI option
variable "do_token" {}

# Configure the DigitalOcean Provider
provider "digitalocean" {
  token = var.do_token
}

# Create a web server
resource "digitalocean_droplet" "droppy" {
    name = "droppy"
    image = "ubuntu-23-10-x64"
    size = "s-1vcpu-1gb"
    region = "lon1"
    user_data = file("cloudinit.yaml")
    ssh_keys = ["fa:7c:c5:69:da:f1:42:0a:70:56:53:a8:f6:36:64:1a"]
}

output "ip_addresses" {
  value = [digitalocean_droplet.droppy.ipv4_address]
  description = "Droplet IP addresses"
}
```