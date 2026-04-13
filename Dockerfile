FROM ghcr.io/astral-sh/uv:python3.12-bookworm-slim

# Install system dependencies (including Matrix-required libs)
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    curl ca-certificates gnupg git bubblewrap openssh-client \
    libolm-dev build-essential && \
    mkdir -p /etc/apt/keyrings && \
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg && \
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" > /etc/apt/sources.list.d/nodesource.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends nodejs && \
    apt-get purge -y gnupg && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Clone the latest version from GitHub
RUN git clone --depth 1 https://github.com/HKUDS/nanobot.git .

# Install nanobot with Matrix support
RUN uv pip install --system --no-cache ".[matrix]"

# Build the WhatsApp bridge
WORKDIR /app/bridge
RUN npm install && npm run build
WORKDIR /app

# Create non-root user and config directory
RUN useradd -m -u 1000 -s /bin/bash nanobot && \
    mkdir -p /home/nanobot/.nanobot && \
    chown -R nanobot:nanobot /home/nanobot /app

# Set permissions on the cloned entrypoint.sh (No COPY needed!)
RUN chmod +x /app/entrypoint.sh && \
    ln -s /app/entrypoint.sh /usr/local/bin/entrypoint.sh

USER nanobot
ENV HOME=/home/nanobot
ENV PYTHONUNBUFFERED=1

# Gateway default port
EXPOSE 18790

# Use the entrypoint from the cloned repo
ENTRYPOINT ["/app/entrypoint.sh"]
CMD ["gateway"]
