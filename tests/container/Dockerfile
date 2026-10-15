FROM debian:trixie-slim@sha256:a99cfc517144bc59b1978475ec53b46ecabec7e43635402ee5b77cc54cd1b20a AS tools
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl unzip zsh git git-lfs jq eza ripgrep fd-find zoxide \
    direnv golang-go openssh-client less locales util-linux \
    && rm -rf /var/lib/apt/lists/* \
    && ln -s /usr/bin/fdfind /usr/local/bin/fd \
    && sed -i 's/^# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen \
    && locale-gen
ENV LANG=en_US.UTF-8 TERM=xterm-256color
COPY tests/container/install-tools.sh tests/container/install-plugins.sh /tmp/setup/
RUN sh /tmp/setup/install-tools.sh && sh /tmp/setup/install-plugins.sh
FROM tools AS validation
RUN cd /tmp && curl -fsSL --retry 3 https://pkgs.tailscale.com/stable/tailscale_1.102.4_arm64.tgz -o tailscale.tgz \
    && echo '9dd1e6a592a014bbaea0103167ffe299adeda4ba14e078ce9c2895364f6c4c3f  tailscale.tgz' | sha256sum -c - \
    && tar xzf tailscale.tgz \
    && install -m 755 tailscale_1.102.4_arm64/tailscale /usr/local/bin/tailscale \
    && install -m 755 tailscale_1.102.4_arm64/tailscaled /usr/local/bin/tailscaled \
    && rm -rf /tmp/tailscale.tgz /tmp/tailscale_1.102.4_arm64
RUN useradd -m -s /usr/bin/zsh tester
USER tester
ENV HOME=/home/tester SHELL=/usr/bin/zsh
USER root
COPY --chown=tester:tester home/ /home/tester/
COPY tests/container/verify.ts /tests/verify.ts
COPY tests/container/history-pty.go /tests/history-pty.go
RUN GOCACHE=/tmp/dotfiles-go-build-cache GOTOOLCHAIN=local GOPROXY=off GOSUMDB=off go build -o /tests/history-pty /tests/history-pty.go \
    && rm -rf /tmp/dotfiles-go-build-cache
RUN mkdir -p /results && chown tester:tester /results
USER tester
WORKDIR /home/tester
CMD ["bun", "/tests/verify.ts"]
