FROM node:20 AS base

WORKDIR /app

RUN apt update && apt upgrade -y

RUN corepack enable

FROM base AS prod-deps

COPY pnpm-lock.yaml .

RUN pnpm fetch --prod

COPY package.json .

RUN pnpm install --offline --prod

FROM base AS build

COPY pnpm-lock.yaml .

RUN pnpm fetch

COPY package.json .

RUN pnpm install --offline

COPY . .

RUN pnpm run build

FROM gcr.io/distroless/nodejs20-debian12

WORKDIR /app

COPY --from=prod-deps /app/node_modules ./node_modules

COPY --from=build /app/build/api.js .

COPY --from=build /app/build/client ./build/client

COPY package.json .

CMD ["api.js"]
