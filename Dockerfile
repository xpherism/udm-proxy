FROM caddy:builder-alpine AS builder

RUN xcaddy build \
    --with github.com/abiosoft/caddy-json-schema \
    --with github.com/mholt/caddy-l4

FROM caddy:alpine

COPY --from=builder /usr/bin/caddy /usr/bin/caddy
