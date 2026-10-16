FROM debian:trixie-slim@sha256:a99cfc517144bc59b1978475ec53b46ecabec7e43635402ee5b77cc54cd1b20a AS tools
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl unzip zsh git git-lfs jq eza ripgrep fd-find zoxide \
    direnv golang-go openssh-client less locales util-linux bash \
    && rm -rf /var/lib/apt/lists/* \
    && ln -s /usr/bin/fdfind /usr/local/bin/fd \
    && sed -i 's/^# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen \
    && locale-gen
ENV LANG=en_US.UTF-8 TERM=xterm-256color
COPY go.mod /src/go.mod
COPY cmd/ /src/cmd/
COPY internal/ /src/internal/
RUN cd /src && GOTOOLCHAIN=local go build -o /usr/local/bin/dotfiles ./cmd/dotfiles
COPY tests/container/install-tools.sh tests/container/install-plugins.sh /tmp/setup/
RUN --mount=type=secret,id=proxy_ca \
    if [ -f /run/secrets/proxy_ca ]; then export SSL_CERT_FILE=/run/secrets/proxy_ca CURL_CA_BUNDLE=/run/secrets/proxy_ca; fi; \
    sh /tmp/setup/install-tools.sh && sh /tmp/setup/install-plugins.sh
FROM tools AS validation
RUN useradd -m -s /usr/bin/zsh tester
USER tester
ENV HOME=/home/tester BUN_INSTALL=/home/tester/.bun SHELL=/usr/bin/zsh
# Node versions are fixture runtimes for testing real fnm switching.
RUN --mount=type=secret,id=proxy_ca \
    if [ -f /run/secrets/proxy_ca ]; then export SSL_CERT_FILE=/run/secrets/proxy_ca; fi; \
    fnm install 22.23.3 && fnm install 24.21.0 && fnm default 22.23.3 \
    && mkdir -p "$BUN_INSTALL" && bun completions > "$BUN_INSTALL/_bun"
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
