FROM alpine:3.19

ARG USERNAME=recol
ARG USER_UID=1000
ARG USER_GID=$USER_UID

ENV DEBIAN_FRONTEND=noninteractive
ENV GO_VERSION=1.21.5
ENV TERRAFORM_VERSION=1.6.6
ENV HELM_VERSION=3.13.3

RUN apk update && apk add --no-cache \
    gcc \
    g++ \
    make \
    cmake \
    musl-dev \
    gzip \
    tree \
    diffutils \
    nmap \
    mtr \
    iftop \
    tcpdump \
    zsh \
    python3 \
    python3-dev \
    py3-pip \
    neovim \
    tmux \
    stow \
    openssh-server \
    openssh-client \
    curl \
    wget \
    git \
    unzip \
    ca-certificates \
    sudo \
    pkgconfig \
    openssl-dev \
    linux-headers \
    htop \
    less

RUN addgroup -g $USER_GID $USERNAME \
    && adduser -u $USER_UID -G $USERNAME -s /bin/zsh -D $USERNAME \
    && echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

RUN mkdir -p /var/run/sshd \
    && ssh-keygen -A 

RUN wget https://github.com/BurntSushi/ripgrep/releases/download/14.1.1/ripgrep-14.1.1-x86_64-unknown-linux-musl.tar.gz -O ripgrep.tar.gz \
    && tar -xzf ripgrep.tar.gz \
    && mv ripgrep-14.1.1-x86_64-unknown-linux-musl/rg /usr/local/bin/ \
    && rm -rf ripgrep.tar.gz ripgrep-14.1.1-x86_64-unknown-linux-musl

RUN wget "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz" -O go.tar.gz \
    && tar -C /usr/local -xzf go.tar.gz \
    && rm go.tar.gz

# Install Rust and Cargo
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y \
    && /root/.cargo/bin/rustup default stable

# Install Terraform
RUN wget "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip" -o terraform.zip \
    && unzip terraform.zip \
    && mv terraform /usr/local/bin/ \
    && rm terraform.zip

# Install Helm
RUN wget "https://get.helm.sh/helm-v${HELM_VERSION}-linux-amd64.tar.gz" -o helm.tar.gz \
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