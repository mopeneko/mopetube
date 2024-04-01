FROM node:20

WORKDIR /app

RUN apt update && apt upgrade -y

RUN corepack enable

COPY ./package.json ./pnpm-lock.yaml ./

RUN pnpm install

COPY . .

RUN pnpm run build

CMD ["node", "build/api.js"]
