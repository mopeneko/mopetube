FROM node:20

RUN corepack enable

COPY ./package.json ./pnpm-lock.yaml ./

RUN pnpm install

COPY . .

RUN pnpm run build

CMD ["node", "build/api.js"]
