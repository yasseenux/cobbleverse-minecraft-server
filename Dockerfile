# Multi-stage build for Cobbleverse Minecraft Server
FROM openjdk:21-jdk-slim as builder

# Set working directory
WORKDIR /build

# Install required packages including jq for JSON parsing
RUN apt-get update && \
    apt-get install -y wget curl unzip jq && \
    rm -rf /var/lib/apt/lists/*

# Download Fabric installer
RUN wget -O fabric-installer.jar https://meta.fabricmc.net/v2/versions/loader/1.21.1/0.16.9/1.0.1/server/jar

# Download Cobbleverse modpack
RUN wget -O cobbleverse.mrpack "https://cdn.modrinth.com/data/Jkb29YJU/versions/CJgxxWjP/COBBLEVERSE%201.5.2.mrpack"

# Create extraction directory
RUN mkdir -p /build/modpack

# Extract modpack (mrpack is a zip file)
RUN cd /build/modpack && unzip ../cobbleverse.mrpack

# Debug: Show what was extracted
RUN echo "=== MODPACK CONTENTS ===" && ls -la /build/modpack/

# Parse modrinth.index.json to get mod download URLs
RUN cd /build/modpack && \
    echo "=== CHECKING FOR MODRINTH INDEX ===" && \
    ls -la && \
    if [ -f "modrinth.index.json" ]; then \
        echo "=== PARSING MODRINTH INDEX ===" && \
        cat modrinth.index.json | jq '.' | head -20 && \
        jq -r '.files[] | select(.path | startswith("mods/")) | .downloads[0]' modrinth.index.json > mod_urls.txt && \
        jq -r '.files[] | select(.path | startswith("mods/")) | .path' modrinth.index.json > mod_paths.txt && \
        echo "Found $(wc -l < mod_urls.txt) mods to download" && \
        echo "First 5 URLs:" && head -5 mod_urls.txt; \
    else \
        echo "ERROR: modrinth.index.json not found!" && \
        echo "Available files:" && ls -la; \
    fi

# Create mods directory and download all mods
RUN mkdir -p /build/server/mods && \
    cd /build/modpack && \
    if [ -f "mod_urls.txt" ] && [ -s "mod_urls.txt" ]; then \
        echo "=== DOWNLOADING MODS ===" && \
        paste mod_urls.txt mod_paths.txt | while IFS=$'\t' read -r url path; do \
            filename=$(basename "$path") && \
            echo "Downloading: $filename from $url" && \
            wget -q --timeout=30 -O "/build/server/$path" "$url" && echo "✓ $filename" || echo "✗ Failed: $filename"; \
        done && \
        echo "=== DOWNLOAD COMPLETE ===" && \
        echo "Mods downloaded: $(ls /build/server/mods/ | wc -l)"; \
    else \
        echo "ERROR: No mod URLs found - will try alternative method" && \
        if [ -d "mods" ]; then \
            echo "Copying mods from modpack mods directory..." && \
            cp -r mods/* /build/server/mods/ 2>/dev/null || echo "No mods found in mods directory"; \
        fi; \
    fi

# Copy overrides if they exist
RUN if [ -d "/build/modpack/overrides" ]; then \
        echo "=== COPYING OVERRIDES ===" && \
        cp -r /build/modpack/overrides/* /build/server/ 2>/dev/null || true && \
        echo "Overrides copied successfully"; \
    else \
        echo "No overrides directory found"; \
    fi

# Alternative: Try to find and copy any existing mods
RUN echo "=== LOOKING FOR EXISTING MODS ===" && \
    find /build/modpack -name "*.jar" -type f | head -10 && \
    find /build/modpack -name "*.jar" -type f -exec cp {} /build/server/mods/ \; 2>/dev/null || true

# Verify mods were downloaded/copied
RUN echo "=== FINAL MOD COUNT ===" && \
    mod_count=$(ls /build/server/mods/ 2>/dev/null | wc -l) && \
    echo "Total mods found: $mod_count" && \
    if [ "$mod_count" -gt 0 ]; then \
        echo "✓ SUCCESS: Mods found!" && \
        ls /build/server/mods/ | head -10; \
    else \
        echo "✗ WARNING: No mods found - server will run vanilla Fabric only" && \
        echo "Contents of modpack:" && \
        find /build/modpack -type f -name "*.jar" | head -5; \
    fi

# Production stage
FROM openjdk:21-jdk-slim

# Install required packages
RUN apt-get update && \
    apt-get install -y curl wget && \
    rm -rf /var/lib/apt/lists/*

# Create minecraft user and directory
RUN useradd -m -d /minecraft minecraft
WORKDIR /minecraft

# Copy Fabric server jar
COPY --from=builder /build/fabric-installer.jar ./server.jar

# Copy all server files including mods
COPY --from=builder /build/server/ ./

# Ensure proper directory structure
RUN mkdir -p mods config world logs crash-reports

# Set proper permissions
RUN chown -R minecraft:minecraft /minecraft

# Switch to minecraft user
USER minecraft

# Create server startup script
RUN echo '#!/bin/bash\n\
echo "Starting Cobbleverse Server..."\n\
echo "eula=true" > eula.txt\n\
\n\
# Set default server properties if not exists\n\
if [ ! -f server.properties ]; then\n\
    echo "Creating default server.properties..."\n\
    cat > server.properties << EOF\n\
server-port=${PORT:-25565}\n\
gamemode=survival\n\
difficulty=normal\n\
allow-flight=true\n\
max-players=${MAX_PLAYERS:-20}\n\
online-mode=${ONLINE_MODE:-true}\n\
white-list=false\n\
spawn-protection=16\n\
max-world-size=29999984\n\
level-name=world\n\
level-seed=\n\
pvp=true\n\
hardcore=false\n\
enable-command-block=true\n\
max-tick-time=60000\n\
generator-settings=\n\
force-gamemode=false\n\
allow-nether=true\n\
enforce-whitelist=false\n\
resource-pack=\n\
spawn-monsters=true\n\
spawn-animals=true\n\
spawn-npcs=true\n\
level-type=default\n\
EOF\n\
fi\n\
\n\
# Start server with optimized JVM flags\n\
exec java -Xms${MIN_RAM:-2G} -Xmx${MAX_RAM:-4G} \\\n\
    -XX:+UseG1GC \\\n\
    -XX:+ParallelRefProcEnabled \\\n\
    -XX:MaxGCPauseMillis=200 \\\n\
    -XX:+UnlockExperimentalVMOptions \\\n\
    -XX:+DisableExplicitGC \\\n\
    -XX:+AlwaysPreTouch \\\n\
    -XX:G1NewSizePercent=30 \\\n\
    -XX:G1MaxNewSizePercent=40 \\\n\
    -XX:G1HeapRegionSize=8M \\\n\
    -XX:G1ReservePercent=20 \\\n\
    -XX:G1HeapWastePercent=5 \\\n\
    -XX:G1MixedGCCountTarget=4 \\\n\
    -XX:InitiatingHeapOccupancyPercent=15 \\\n\
    -XX:G1MixedGCLiveThresholdPercent=90 \\\n\
    -XX:G1RSetUpdatingPauseTimePercent=5 \\\n\
    -XX:SurvivorRatio=32 \\\n\
    -XX:+PerfDisableSharedMem \\\n\
    -XX:MaxTenuringThreshold=1 \\\n\
    -Dusing.aikars.flags=https://mcflags.emc.gs \\\n\
    -Daikars.new.flags=true \\\n\
    -jar server.jar --nogui' > start.sh && chmod +x start.sh

# Expose the default Minecraft port
EXPOSE 25565

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:25565 || exit 1

# Start the server
CMD ["./start.sh"]
