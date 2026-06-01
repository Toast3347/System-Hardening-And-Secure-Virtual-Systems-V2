FROM node:24.16.0-alpine3.22

ENV CI=true
WORKDIR /app

RUN corepack enable

COPY package.json pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile

COPY . .

ARG VITE_API_BASE_URL=http://localhost:5053/api
ENV VITE_API_BASE_URL=$VITE_API_BASE_URL

RUN addgroup -S appgroup && adduser -S appuser -G appgroup

USER appuser

EXPOSE 5173

CMD ["pnpm", "exec", "vite", "--host", "0.0.0.0", "--port", "5173"]

HEALTHCHECK --interval=30s --timeout=3s --retries=3 CMD wget -qO- http://localhost:5173/ >/dev/null || exit 1
