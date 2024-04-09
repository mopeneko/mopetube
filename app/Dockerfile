FROM node:20 AS base

WORKDIR /app

RUN apt update && apt upgrade -y

RUN corepack enable

FROM base AS prod-deps

ENV NODE_ENV=production

COPY pnpm-lock.yaml .

RUN pnpm fetch --prod

COPY package.json .

RUN pnpm install --offline --prod

FROM base AS build

ENV NODE_ENV=development

COPY pnpm-lock.yaml .

RUN pnpm fetch

COPY package.json .

RUN pnpm install --offline

COPY . .

RUN pnpm run build

FROM gcr.io/distroless/nodejs20-debian12

WORKDIR /app

COPY --from=prod-deps /app/node_modules ./node_modules

COPY --from=build /app/build/api .

COPY --from=build /app/build/client ./build/client

COPY package.json ./

COPY --chmod=600 certs certs

ENV NODE_ENV=production
ENV CA_PATH=/app/certs/isrgrootx1.pem

CMD ["index.js"]
