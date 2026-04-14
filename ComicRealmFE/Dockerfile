FROM node:22-alpine

WORKDIR /app

RUN corepack enable

COPY package.json pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile

COPY . .

EXPOSE 5173

CMD ["sh", "-c", "CI=true pnpm install --frozen-lockfile --config.confirmModulesPurge=false && pnpm exec vite --host 0.0.0.0 --port 5173"]