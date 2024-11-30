FROM ghcr.io/darkness4/aoc-2024:base AS base
WORKDIR /work
COPY . .
RUN zig build

FROM debian:latest AS static-bash-provider
RUN apt update -y \
  && apt install -y --no-install-recommends \
  bash-static \
  && rm -rf /var/lib/apt/lists/*

FROM scratch
COPY --from=base /work/zig-out/bin /bin
COPY --from=static-bash-provider /bin/bash-static /bin/bash
ENV PATH=/bin:$PATH
ENTRYPOINT [ "/bin/bash", "-c" ]
