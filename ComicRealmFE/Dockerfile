# syntax=docker/dockerfile:1.7
# =============================================================================
# Hardened multi-stage build for ComicRealmFE.
#   - Build stage compiles the Vue/Vite SPA with pnpm; full toolchain is
#     discarded afterwards.
#   - Runtime stage uses the `nginxinc/nginx-unprivileged` image:
#       * runs as uid 101 (non-root),
#       * no extra packages installed,
#       * listens on 8080 by default so it can bind without CAP_NET_BIND_SERVICE.
#   - No source code, no node_modules, no shell tools in the final image.
# =============================================================================

# ---------- build ----------
FROM node:24.16.0-alpine3.22 AS build
ENV CI=true
WORKDIR /app

RUN corepack enable

COPY package.json pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile

COPY . .

ARG VITE_API_BASE_URL=http://localhost:5053/api
ENV VITE_API_BASE_URL=$VITE_API_BASE_URL
RUN pnpm run build-only

# ---------- runtime (nginx-unprivileged, non-root) ----------
# `stable-alpine-slim` strips perl/mail/stream modules and tracks the most
# recent patched alpine + nginx stable release — picked specifically to keep
# the Trivy CRITICAL/HIGH count at zero.
FROM nginxinc/nginx-unprivileged:stable-alpine-slim AS final
USER nginx
WORKDIR /usr/share/nginx/html

# Static SPA bundle only — nothing buildable or executable ships in the image.
COPY --from=build --chown=nginx:nginx /app/dist .

EXPOSE 8080
