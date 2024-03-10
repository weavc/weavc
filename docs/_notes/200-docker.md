---
layout: post
title: Docker
tags: ['dev', 'devops']
icon: box-seam
---

### Compose

#### Example:
```yaml
version: '3.8'
services:
  # ms sql, environment variables, ports & restart policy
  mssql:
    image: mcr.microsoft.com/mssql/server:2019-latest
    container_name: mssql-db
    environment:
      - ACCEPT_EULA=Y
      - SA_PASSWORD=Password01!
    ports:
      - 1483:1433
    restart: unless-stopped

  mongo:
    image: mongo:latest
    restart: unless-stopped
    ports:
      - "27017:27017"
    environment:
      TZ: "Europe/London"
  
  azurite:
    image: mcr.microsoft.com/azure-storage/azurite:latest
    restart: unless-stopped
    ports:
      - "10000:10000"
      - "10001:10001"
      - "10002:10002"

  discord:
    # build example
    build: 
      context: ../
      dockerfile: .docker/Dockerfile.package
      args:
        - package=discord
    ports:
      - "50051:8001"
    # Adding service to an ipam network
    networks:
      netty:
        ipv4_address: 172.123.2.1
    # Resource limits
    deploy:
      resources:
        limits:
          cpus: "4"
          memory: "2g"

networks:
  netty:
    ipam:
      driver: default
      config:
        - subnet: 172.123.0.0/16
```


### Dockerfiles

#### Go

```dockerfile
# Use the official Go image as the base image
FROM golang:1.20-alpine AS build

# Set the working directory inside the container
WORKDIR /app

# Copy the Go module files
COPY go.mod go.sum ./

# Download and cache Go dependencies
RUN go mod download

# Copy the source code into the container
COPY . .

# These don't cache, not sure why currently.
RUN go install google.golang.org/protobuf/cmd/protoc-gen-go@v1.28
RUN go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@v1.2
RUN go install github.com/a-h/templ/cmd/templ@v0.2

RUN apk add --no-cache make protoc

# Build the Go application
RUN make build

# Use a minimal base image for deployment
FROM alpine:latest

# Set the working directory inside the container
WORKDIR /app

# Copy the built executable from the build stage
COPY --from=build /tmp/bin/weavc .
COPY --from=build /app/.config/ ./.config/

ENV WEAVC_ENV=prod

# Expose the port that the application listens on
EXPOSE 50051
EXPOSE 5549

# Run the application
CMD ["./weavc"]
```


#### .NET

```dockerfile
FROM mcr.microsoft.com/dotnet/sdk:6.0-bullseye-slim AS build
WORKDIR /app

# Copy csproj files 
# this is done to cache the restore if nothing has changed
COPY ./**/*.csproj ./

# Restore dependancies
RUN dotnet restore ./src/Web/Web.csproj

# Copy the rest of the files
COPY ./services/identity/src ./src
COPY ./services/identity/lib/Core ./lib/Core

RUN dotnet publish ./src/Web/Web.csproj -c Release -o ./release

FROM mcr.microsoft.com/dotnet/aspnet:6.0-bullseye-slim

WORKDIR /app
COPY --from=build /app/release .

RUN rm appsettings*.json

COPY ./.envs/master/identity/overrides/ ./

ENTRYPOINT ["dotnet", "Web.dll"]

EXPOSE 80 443
```


### Swarm

#### Services/Swarms examples
```shell
docker swarm init
docker network create --driver overlay my-network
```

```shell
docker service create \
    --mount type=bind,src=<path-to-certs>/fullchain.pem,dst=/certs/fullchain.pem,ro \
    --mount type=bind,src=<path-to-certs>/privkey.pem,dst=/certs/privkey.pem,ro \
    --mount type=bind,src=<path-to-site-defs>,dst=/sites \
    --publish 80:80 \
    --publish 443:443 \
    --replicas 3 \
    --name weavc-nginx \
    --network=<network> \
    docker.pkg.github.com/weavc/weavc-nginx/weavc-nginx:latest
```

```shell
docker service create \
    --replicas 3 \
    --name <name> \
    --network=<network> \
    <image>:latest
```

- [service docs](https://docs.docker.com/engine/reference/commandline/service/)
- [swarm/services docs](https://docs.docker.com/engine/swarm/services/)