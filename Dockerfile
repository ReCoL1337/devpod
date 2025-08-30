# Use specific Ubuntu version for reproducibility
FROM ubuntu:22.04

# Set build arguments - can be overridden during build
ARG USERNAME=recol
ARG USER_UID=1000
ARG USER_GID=$USER_UID

# Set environment variables to avoid interactive prompts
ENV DEBIAN_FRONTEND=noninteractive
ENV GO_VERSION=1.21.5
ENV TERRAFORM_VERSION=1.6.6
ENV HELM_VERSION=3.13.3

# Create a non-root user for development
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USERNAME --shell /bin/zsh --create-home $USERNAME

# Install system packages and development tools
RUN apt-get update && apt-get install -y \
    # Build tools
    gcc \
    g++ \
    make \
    cmake \
    # Compression and utilities  
    gzip \
    tree \
    diffutils \
    # Network tools
    nmap \
    mtr-tiny \
    iftop \
    tcpflow \
    hping3 \
    bmon \
    # Log processing and shell
    ccze \
    zsh \
    # Development tools
    python3 \
    python3-pip \
    neovim \
    tmux \
    # Dots
    stow \
    # SSH and networking
    openssh-server \
    openssh-client \
    # Common utilities
    curl \
    wget \
    git \
    unzip \
    ca-certificates \
    sudo \
    # Required for building from source
    build-essential \
    pkg-config \
    libssl-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Configure SSH
RUN mkdir /var/run/sshd \
    && echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Install ripgrep (Rust-based grep alternative)
RUN curl -fsSL https://github.com/BurntSushi/ripgrep/releases/download/14.1.0/ripgrep_14.1.0-1_amd64.deb -o ripgrep.deb \
    && dpkg -i ripgrep.deb \
    && rm ripgrep.deb

# Install Go
RUN curl -fsSL https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz -o go.tar.gz \
    && tar -C /usr/local -xzf go.tar.gz \
    && rm go.tar.gz

# Install Rust and Cargo
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y \
    && /root/.cargo/bin/rustup default stable

# Install Terraform
RUN curl -fsSL https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip -o terraform.zip \
    && unzip terraform.zip \
    && mv terraform /usr/local/bin/ \
    && rm terraform.zip

# Install Helm
RUN curl -fsSL https://get.helm.sh/helm-v${HELM_VERSION}-linux-amd64.tar.gz -o helm.tar.gz \
    && tar -zxvf helm.tar.gz \
    && mv linux-amd64/helm /usr/local/bin/helm \
    && rm -rf helm.tar.gz linux-amd64

# Set up environment variables
ENV PATH="/usr/local/go/bin:/root/.cargo/bin:${PATH}"
ENV GOPATH="/home/$USERNAME/go"
ENV GOBIN="${GOPATH}/bin"

# Create Go workspace for the user
RUN mkdir -p /home/$USERNAME/go/src /home/$USERNAME/go/bin /home/$USERNAME/go/pkg \
    && chown -R $USERNAME:$USERNAME /home/$USERNAME/go

# Install additional Rust tools that might be useful
RUN /root/.cargo/bin/cargo install \
    bat \
    exa \
    fd-find

# Set up zsh as default shell for user
RUN chsh -s /bin/zsh $USERNAME

# Switch to non-root user
USER $USERNAME
WORKDIR /home/$USERNAME

# Copy Rust environment to user
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

# Set up user environment variables
ENV PATH="/home/$USERNAME/.cargo/bin:${PATH}"

# Create workspace directory
RUN mkdir -p /home/$USERNAME/workspace

# Create minimal .zshrc (will be replaced by dotfiles)
RUN echo '# Minimal zsh config - will be replaced by dotfiles' > ~/.zshrc \
    && echo 'export PATH="/usr/local/go/bin:$HOME/.cargo/bin:$PATH"' >> ~/.zshrc \
    && echo 'export GOPATH="$HOME/go"' >> ~/.zshrc \
    && echo 'export GOBIN="$GOPATH/bin"' >> ~/.zshrc \
    && echo 'export EDITOR="nvim"' >> ~/.zshrc \
    && echo 'export VISUAL="nvim"' >> ~/.zshrc

# Expose SSH port
EXPOSE 22

# Switch back to root for SSH daemon
USER root

# Set default command to start SSH daemon
CMD ["/usr/sbin/sshd", "-D"]