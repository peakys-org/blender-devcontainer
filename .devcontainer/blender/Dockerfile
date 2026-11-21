FROM archlinux
LABEL org.opencontainers.image.source="https://github.com/peakys-org/blender-devcontainer/"
RUN pacman -Syyu --noconfirm

ARG USER=user
ARG PUID=1000
ARG PGID=1000
ARG RENDER_GROUP_GID=997
ARG BLENDER_VERSION=4.5.0

ENV DOCKER_USER=$USER
ENV PUID=$PUID
ENV PGID=$PGID
ENV BLENDER_VERSION=${BLENDER_VERSION:-4.5.0}
ENV SERVICE_NAME=${SERVICE_NAME:-blender}

USER root
RUN groupadd -g $PGID $USER
RUN useradd -ms /bin/bash -u $PUID -g $PGID $USER
RUN groupadd -o -g $RENDER_GROUP_GID docker-render
RUN usermod -aG docker-render $USER

WORKDIR /workspaces/

# Install sway/wayvnc and dependencies
RUN pacman -Syu --noconfirm sway swaybg wayvnc

# Install Bldender.
RUN pacman -Syu --noconfirm curl libx11 libxrender libxxf86vm libxfixes libxi libxkbcommon libsm mesa libdecor
RUN curl -o blender.tar.xz https://download.blender.org/release/Blender${BLENDER_VERSION%.*}/blender-${BLENDER_VERSION}-linux-x64.tar.xz \
    && tar -xf blender.tar.xz \
    && mv blender-${BLENDER_VERSION}-linux-x64 blender/ \
    && rm -rf blender.tar.xz \
    && chown -R $USER:$USER blender/

# Install other tools
RUN pacman -Syu --noconfirm jq inotify-tools

# Install websockify (not in the Arch repos) into a venv.
# wayvnc's built-in --websocket mode segfaults on client connect with
# Arch's wayvnc 0.10.2 / neatvnc 1.0.3 (see any1/neatvnc#177), so the
# WebSocket layer is provided by websockify in front of a plain wayvnc.
RUN python -m venv /opt/websockify \
    && /opt/websockify/bin/pip install --no-cache-dir websockify

# Clean up pacman cache
RUN pacman -Scc --noconfirm && rm -rf /var/cache/pacman/pkg/* /root/.cache

# Copy sway/wayvnc configs
COPY --chown=$USER:$USER sway/ /home/$USER/.config/sway/
COPY --chown=$USER:$USER wayvnc/ /home/$USER/.config/wayvnc/

# Copy and set the entrypoint script
COPY --chown=$USER:$USER --chmod=0700 entrypoint.sh .
COPY --chown=$USER:$USER --chmod=0700 entrypoint_user.sh .
COPY --chown=$USER:$USER --chmod=0700 reload.sh .

ENTRYPOINT ["./entrypoint.sh"]
