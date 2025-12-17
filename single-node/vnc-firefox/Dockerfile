FROM alpine:edge

RUN apk add --no-cache \
    faenza-icon-theme \
    firefox \
    fluxbox \
    xfce4 \
    xvfb \
    x11vnc \
    novnc \
    supervisor \
    bash \
    net-tools

# Install noVNC & websockify from source code
RUN apk add --no-cache git python3 py3-pip \
    && rm -rf /usr/share/novnc \
    && git clone https://github.com/novnc/noVNC.git /usr/share/novnc \
    && git clone https://github.com/novnc/websockify.git /usr/share/novnc/utils/websockify \
    && ln -sf /usr/share/novnc/vnc.html /usr/share/novnc/index.html

ENV DISPLAY=:1
ENV RESOLUTION=1920x1080x24

# Set vnc password
ARG VNC_PASS=dummypass

# Create vnc password file
RUN mkdir -p /root/.vnc && \
    x11vnc -storepasswd "$VNC_PASS" /root/.vnc/passwd

COPY supervisord.conf /etc/supervisord.conf

EXPOSE 5900 6080

CMD ["supervisord", "-c", "/etc/supervisord.conf", "-n"]
