FROM node:22-alpine

WORKDIR /app

RUN corepack enable

COPY package.json pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile

COPY . .

ARG VITE_API_BASE_URL=http://localhost:5053/api
ENV VITE_API_BASE_URL=$VITE_API_BASE_URL

EXPOSE 5173

CMD ["sh", "-c", "CI=true pnpm install --frozen-lockfile --config.confirmModulesPurge=false && pnpm exec vite --host 0.0.0.0 --port 5173"]