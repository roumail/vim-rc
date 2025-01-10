# Base Stage: Install common packages
ARG BASE_IMAGE=debian:stable-slim
FROM ${BASE_IMAGE} AS base
# https://stackoverflow.com/questions/53681522/share-variable-in-multi-stage-dockerfile-arg-before-from-not-substituted
ARG BASE_IMAGE
ARG DEV_IMAGE_NAME=dev-env
LABEL version="1.0.0"
LABEL org.opencontainers.image.authors="rohailt"
LABEL org.opencontainers.image.source="https://github.com/rohailt/dev-env-setup"
LABEL maintainer.email="sigmagraphinc@gmail.com"
LABEL org.opencontainers.image.base="$BASE_IMAGE"
LABEL org.opencontainers.image.name="$DEV_IMAGE_NAME"
LABEL org.opencontainers.image.description="Base stage for development environment with common utilities."
LABEL stage="base"
LABEL org.opencontainers.image.created=$(date)


RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    git \
    bash \
    tmux \
    bat \
    fontconfig \
    tree \
    ca-certificates \
    # For terminal support (xterm_clipboard feature)    
    vim-nox \  
    # Clipboard integration
    xclip \  
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* && \
    ln -s /usr/bin/batcat /usr/bin/bat

ENV SHELL=/bin/bash

# Font Installation Stage: Handle fonts in a separate stage
FROM base AS fonts
LABEL stage="fonts"
LABEL org.opencontainers.image.description="Stage for ensuring fonts and installed and configured."

COPY dev-env-setup/nerd-fonts/ /usr/share/fonts

# Rebuild font cache
RUN fc-cache -fv

FROM base AS tools
LABEL stage="tools"

RUN curl -fsSL https://starship.rs/install.sh | sh -s -- -y && \
    curl -LsSf https://astral.sh/uv/install.sh | env UV_UNMANAGED_INSTALL="/usr/local/bin" sh && \
    curl -fLo /root/.vim/autoload/plug.vim --create-dirs \
        https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

# Bash Stage: Default bash command
FROM base AS bash
LABEL stage="bash"
LABEL org.opencontainers.image.description="Stage for configuring bash with tools."

# Copy fonts from the previous stage
COPY --from=fonts /usr/share/fonts /usr/share/fonts

# Copy Starship binary from the tools stage
COPY --from=tools /usr/local/bin/starship /usr/local/bin/starship

# Copy uv binaries and environment from tools stage
COPY --from=tools /usr/local/bin/uv /usr/local/bin/uv

# Vim plug directories
COPY --from=tools /root/.vim/autoload /root/.vim/autoload

# Copy starship configuration
COPY dotfiles/bash-rc/starship.toml /root/.config/starship.toml

# Copy bashrc
COPY dotfiles/bash-rc/.bashrc /root/.bashrc

CMD ["/bin/bash"]

# Vim Plugins install
FROM bash AS vim_plugins
LABEL stage="vim_plugins"
LABEL org.opencontainers.image.description="Stage for configuring Vim with plugins."

# Copy vim configuration
COPY dotfiles/vim-rc/.vimrc /root/.vimrc 
COPY dotfiles/vim-rc/.vim/config /root/.vim/config 

# Run vim-plug in headless mode to install plugins
# vim -E: Enables "Ex mode," which is non-interactive.
# </dev/null: Prevents Vim from waiting for input during the build.
RUN vim -E -u /root/.vimrc +PlugInstall +qall </dev/null

CMD ["/bin/bash"]

# Install Python 3.11 and Jupyter using uv
FROM bash AS jupyter
LABEL stage="jupyter"
LABEL org.opencontainers.image.description="Stage for configuring a python installation with a jupyter notebook interface."

RUN uv python install 3.11 && \
    uv venv .venv --python 3.11 && \
    . .venv/bin/activate && \ 
    uv pip install jupyter

ENV PATH="/root/workspace/.venv/bin:$PATH"

# Default command for Jupyter stage
CMD ["jupyter", "notebook", "--allow-root", "--ip", "0.0.0.0", "--no-browser"]