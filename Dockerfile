# Multi-stage build for Cobbleverse Minecraft Server
FROM openjdk:21-jdk-slim as builder

# Set working directory
WORKDIR /build

# Cache buster - force rebuild
ARG CACHE_BUST=v8

# Install required packages including jq for JSON parsing
RUN apt-get update && \
    apt-get install -y wget curl unzip jq && \
    rm -rf /var/lib/apt/lists/*

# Download Fabric installer (updated to latest version)
RUN wget -O fabric-installer.jar https://meta.fabricmc.net/v2/versions/loader/1.21.1/0.16.14/1.0.1/server/jar

# Download Cobbleverse modpack
RUN wget -O cobbleverse.mrpack "https://cdn.modrinth.com/data/Jkb29YJU/versions/CJgxxWjP/COBBLEVERSE%201.5.2.mrpack"

# Create extraction directory
RUN mkdir -p /build/modpack

# Extract modpack (mrpack is a zip file)
RUN cd /build/modpack && unzip ../cobbleverse.mrpack

# Debug: Show what was extracted
RUN echo "=== MODPACK CONTENTS ===" && ls -la /build/modpack/

# Create server directory structure
RUN mkdir -p /build/server/mods /build/server/config

# Process modrinth.index.json to download mods (excluding client-side mods)
RUN cd /build/modpack && \
    if [ -f "modrinth.index.json" ]; then \
        echo "=== FOUND MODRINTH INDEX ===" && \
        echo "Processing mod downloads from index..." && \
        # Client-side mods to exclude (known problematic for servers)
        EXCLUDE_MODS="modernfix|sodium|iris|continuity|immediatelyfast|moreculling|betterf3|zoomify|reeses-sodium-options|sodium-extra|sodiumoptionsapi|sodiumdynamiclights|entity_model_features|entity_texture_features|modmenu|betterbeds|mousetweaks|customsplashscreen|particlerain|brb|tooltipfix|controlling|searchables|betterthirdperson|resourcepackoverrides|particular|infinite-music|drop_confirm|euphoria_patcher|musicnotification|advancementplaques|structurify|fabric-renderer-api-v1|fabric-model-loading-api-v1|fabric-keybindings-v0|fabric-client-tags-api-v1|fabric-screen-api-v1|fabric-renderer-indigo|fabric-blockrenderlayer-v1|fabric-renderer-registries-v1|fabric-rendering-v0|fabric-sound-api-v1|fabric-rendering-v1|fabric-key-binding-api-v1|disable_custom_worlds_advice" && \
        jq -c '.files[] | select(.path | startswith("mods/")) | {path: .path, url: .downloads[0]}' modrinth.index.json | \
        while IFS= read -r line; do \
            path=$(echo "$line" | jq -r '.path') && \
            url=$(echo "$line" | jq -r '.url') && \
            filename=$(basename "$path") && \
            # Skip client-side mods \
            if echo "$filename" | grep -qE "$EXCLUDE_MODS"; then \
                echo "SKIPPING client-side mod: $filename"; \
            else \
                echo "Downloading: $filename" && \
                mkdir -p "/build/server/$(dirname "$path")" && \
                wget -q --timeout=30 "$url" -O "/build/server/$path" || echo "Failed: $filename"; \
            fi; \
        done && \
        echo "Mod download complete. Server mods found: $(ls /build/server/mods/ | wc -l)"; \
    else \
        echo "ERROR: No modrinth.index.json found!"; \
    fi

# Copy config files from modpack with proper permissions
RUN if [ -d "/build/modpack/config" ]; then \
        echo "=== COPYING CONFIG FROM MODPACK ===" && \
        cp -r /build/modpack/config/* /build/server/config/ && \
        chmod -R 755 /build/server/config/ && \
        echo "Config files copied with proper permissions"; \
    fi

# Copy overrides if they exist with proper permissions
RUN if [ -d "/build/modpack/overrides" ]; then \
        echo "=== COPYING OVERRIDES ===" && \
        cp -r /build/modpack/overrides/* /build/server/ && \
        chmod -R 755 /build/server/ && \
        echo "Overrides copied successfully with proper permissions"; \
    fi

# Final verification
RUN echo "=== FINAL VERIFICATION ===" && \
    mod_count=$(ls /build/server/mods/ 2>/dev/null | wc -l) && \
    echo "Total mods found: $mod_count" && \
    if [ "$mod_count" -gt 0 ]; then \
        echo "✓ SUCCESS: Found $mod_count mods!" && \
        ls /build/server/mods/ | head -10; \
    else \
        echo "✗ No mods found. Debug info:" && \
        ls -la /build/modpack/ && \
        head -20 /build/modpack/modrinth.index.json 2>/dev/null || echo "No index file"; \
    fi

# Production stage
FROM openjdk:21-jdk-slim

# Install required packages
RUN apt-get update && \
    apt-get install -y curl wget && \
    rm -rf /var/lib/apt/lists/*

# Create minecraft user and directory with proper permissions
RUN useradd -m -d /minecraft minecraft && \
    mkdir -p /minecraft/config /minecraft/mods /minecraft/world && \
    chown -R minecraft:minecraft /minecraft
WORKDIR /minecraft

# Copy Fabric server jar with proper ownership
COPY --from=builder --chown=minecraft:minecraft /build/fabric-installer.jar ./server.jar

# Copy all server files including mods with proper ownership
COPY --from=builder --chown=minecraft:minecraft /build/server/ ./

# Ensure proper directory structure and full write permissions for config
RUN mkdir -p mods config world logs crash-reports && \
    chmod -R 755 /minecraft && \
    chmod -R 775 /minecraft/config 2>/dev/null || true && \
    chmod -R 755 /minecraft/mods 2>/dev/null || true

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
