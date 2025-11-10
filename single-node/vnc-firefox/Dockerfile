FROM alpine:edge

RUN apk add --no-cache \
    xfce4 \
    faenza-icon-theme \
    firefox \
    fluxbox \
    xvfb \
    x11vnc \
    novnc \
    supervisor \
    bash

# Install noVNC & websockify
RUN apk add --no-cache git python3 py3-pip \
    && rm -rf /usr/share/novnc \
    && git clone https://github.com/novnc/noVNC.git /usr/share/novnc \
    && git clone https://github.com/novnc/websockify.git /usr/share/novnc/utils/websockify \
    && ln -sf /usr/share/novnc/vnc.html /usr/share/novnc/index.html

ENV DISPLAY=:1
ENV RESOLUTION=1920x1080x24

COPY supervisord.conf /etc/supervisord.conf

COPY auth.json /etc/novnc/auth.json

CMD ["supervisord", "-c", "/etc/supervisord.conf", "-n"]
