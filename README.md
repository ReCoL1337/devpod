# DevOps Development Container

This repository contains a comprehensive development container setup for DevOps workflows, including programming languages, build tools, networking utilities, and infrastructure tools.

## Contents

### Dockerfile
A multi-layered container setup that includes:

**Programming Languages:**
- **Go** (1.21.5) - Systems programming and cloud-native development
- **Rust** - High-performance systems programming with cargo package manager
- **Python 3** - Scripting and automation

**Build Tools:**
- gcc, g++, make, cmake - Essential compilation tools
- build-essential - Additional build dependencies

**Network Analysis Tools:**
- nmap - Network discovery and security auditing
- mtr - Network diagnostic tool combining ping and traceroute
- iftop - Real-time network bandwidth usage
- tcpflow - TCP connection monitoring
- hping3 - Network testing tool
- bmon - Bandwidth monitoring

**Utilities:**
- ripgrep (rg) - Fast grep alternative written in Rust
- gzip - Compression utility
- ccze - Log file colorizer
- tree - Directory structure visualization
- diffutils - File comparison utilities

**Development Tools:**
- terraform - Infrastructure as Code
- helm - Kubernetes package manager
- neovim - Modern text editor
- tmux - Terminal multiplexer
- zsh - Enhanced shell

**Additional Rust Tools:**
- bat - Enhanced `cat` with syntax highlighting
- exa - Modern `ls` replacement
- fd - Fast `find` alternative

### devcontainer.json
VS Code development container configuration with:
- Relevant VS Code extensions for Go, Rust, Python, Terraform, and Kubernetes
- Port forwarding for common development ports (3000, 8000, 8080, 9090)
- Workspace mounting and user configuration
- Post-creation command to verify tool installation
- Configurable build arguments for username and user IDs

## Usage

### Method 1: With VS Code Dev Containers (Default)
1. Install the Dev Containers extension in VS Code
2. Place both files in your project's `.devcontainer/` directory
3. Open your project in VS Code
4. Press `Ctrl+Shift+P` and select "Dev Containers: Reopen in Container"

### Method 2: With Custom Username
To change the username from the default "dev", update the build args in `devcontainer.json`:

```json
{
    "build": {
        "dockerfile": "Dockerfile",
        "args": {
            "USERNAME": "myuser",
            "USER_UID": "1000",
            "USER_GID": "1000"
        }
    },
    "remoteUser": "myuser",
    "workspaceFolder": "/home/myuser/workspace",
    "mounts": [
        "source=${localWorkspaceFolder},target=/home/myuser/workspace,type=bind,consistency=cached"
    ]
}
```

### Method 3: Manual Docker Build
```bash
# Build with default username (dev)
docker build -t devops-container .

# Build with custom username
docker build --build-arg USERNAME=myuser --build-arg USER_UID=1000 --build-arg USER_GID=1000 -t devops-container .

# Run the container
docker run -it --rm \
  -v $(pwd):/home/dev/workspace \
  -p 3000:3000 -p 8000:8000 -p 8080:8080 -p 9090:9090 \
  devops-container

# Or with custom username
docker run -it --rm \
  -v $(pwd):/home/myuser/workspace \
  -p 3000:3000 -p 8000:8000 -p 8080:8080 -p 9090:9090 \
  devops-container
```

### Method 4: Docker Compose
Create a `docker-compose.yml`:
```yaml
version: '3.8'
services:
  devops:
    build: 
      context: .
      args:
        USERNAME: dev
        USER_UID: 1000
        USER_GID: 1000
    volumes:
      - .:/home/dev/workspace
    ports:
      - "3000:3000"
      - "8000:8000"
      - "8080:8080"
      - "9090:9090"
    stdin_open: true
    tty: true
```

Then run:
```bash
docker-compose up -d
docker-compose exec devops zsh
```

## Configuration Variables

The Dockerfile supports the following build arguments:

| Variable | Default | Description |
|----------|---------|-------------|
| `USERNAME` | `dev` | The username for the non-root user |
| `USER_UID` | `1000` | User ID for the non-root user |
| `USER_GID` | `1000` | Group ID for the non-root user |

### Changing the Username

To use a different username:

1. **For devcontainer.json**: Update the `args` section and corresponding `remoteUser`, `workspaceFolder`, and `mounts` paths
2. **For manual Docker build**: Use `--build-arg USERNAME=yourname`
3. **For Docker Compose**: Update the `args` section in the build configuration

Example with username "developer":
```bash
docker build --build-arg USERNAME=developer --build-arg USER_UID=1001 --build-arg USER_GID=1001 -t devops-container .
```

## Verification

After the container starts, you can verify all tools are properly installed:

```bash
# Programming languages
go version
cargo --version
python3 --version

# Infrastructure tools
terraform --version
helm version --client
nvim --version

# Networking tools
nmap --version
rg --version

# Shell and utilities
zsh --version
tmux -V
```

## Security Features

- Configurable non-root user with customizable UID/GID
- Minimal attack surface with only necessary packages
- No sudo privileges for the development user
- Clean package cache to reduce image size

## Customization

### Adding More Tools
To add additional packages, modify the Dockerfile's `RUN apt-get install` section:

```dockerfile
RUN apt-get update && apt-get install -y \
    # ... existing packages ...
    your-new-package \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*
```

### Environment Variables
The container includes pre-configured environment variables:
- `PATH` includes Go binaries and Cargo binaries
- `GOPATH` set to `/home/$USERNAME/go`
- `GOBIN` configured for Go binary installation

### Shell Configuration
The container uses zsh as the default shell with useful aliases:
- `grep` aliased to `rg` (ripgrep)
- Standard `ll`, `la`, `l` aliases for file listing

## File Structure

```
.devcontainer/
├── Dockerfile
├── devcontainer.json
└── README.md
```

## Best Practices

1. **Layer Optimization**: Multiple packages are installed in single RUN commands to minimize layers
2. **Caching**: Package caches are cleaned to reduce final image size  
3. **Security**: Configurable non-root user prevents privilege escalation
4. **Reproducibility**: Specific versions are pinned where possible
5. **Flexibility**: Username and user IDs are configurable via build arguments
6. **Development-Focused**: Includes comprehensive tooling for modern DevOps workflows

This setup provides a complete, isolated development environment that's consistent across different machines and team members, with the flexibility to customize the user configuration as needed.