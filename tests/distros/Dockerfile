ARG DISTRO=debian:trixie-slim
FROM ${DISTRO}
# These are compatibility probes of current native repositories, not release
# images. Versioned bases are selected explicitly by the CI matrix.
RUN if command -v apt-get >/dev/null; then \
      apt-get update && apt-get install -y --no-install-recommends golang-go zsh bash fish git jq ca-certificates; \
    elif command -v dnf >/dev/null; then \
      dnf install -y golang zsh bash fish git jq ca-certificates; \
    elif command -v pacman >/dev/null; then \
      pacman -Syu --noconfirm --needed go zsh bash fish git jq ca-certificates; \
    elif command -v apk >/dev/null; then \
      apk add --no-cache go zsh bash fish git jq ca-certificates; \
    else exit 1; fi
RUN mkdir -p /home/tester && chown 10001:10001 /home/tester
COPY go.mod README.md /src/
COPY cmd/ /src/cmd/
COPY internal/ /src/internal/
COPY home/ /src/home/
COPY machines/ /src/machines/
COPY tests/container/history-pty.go /src/tests/container/history-pty.go
USER 10001:10001
ENV HOME=/home/tester GOCACHE=/tmp/go-cache GOTOOLCHAIN=local DOTFILES_REQUIRED_SHELLS=zsh,bash,fish,posix
WORKDIR /src
CMD ["go", "test", "-v", "./..."]
