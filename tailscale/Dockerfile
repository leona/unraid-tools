FROM ubuntu:20.04
ARG DEBIAN_FRONTEND=noninteractive
WORKDIR /app

RUN apt-get update -y && \
    apt-get install -y curl gnupg2 systemctl && \
    curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/focal.gpg | apt-key add - && \
    curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/focal.list | tee /etc/apt/sources.list.d/tailscale.list && \
    apt-get update -y && apt-get install -y tailscale

COPY /start.sh /app/start.sh
RUN chmod +x /app/start.sh
ENTRYPOINT [ "/app/start.sh" ]