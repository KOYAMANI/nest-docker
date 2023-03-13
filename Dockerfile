ARG NODE_IMAGE=node:19.6.0

### TARGET: builder ###
FROM $NODE_IMAGE as builder

RUN \
  apt-get update && \
  apt-get install --yes build-essential make gcc g++ python3 python3-pip zsh bash curl && \
  apt-get clean

SHELL [ "/bin/zsh", "-c" ]

WORKDIR /app

COPY package*.json ./

ENV NODE_ENV=development
ENV ENV=development

RUN \
  npm version && \
  npm install --include=dev && \
  npm cache clean --force


### TARGET: development ###
FROM $NODE_IMAGE as development

RUN \
  apt-get update && \
  apt-get install --yes build-essential make gcc g++ python3 python3-pip zsh curl && \
  apt-get clean

SHELL [ "/bin/zsh", "-c" ]

WORKDIR /app

COPY --from=builder /app/node_modules ./node_modules

CMD ["npm", "run", "start:dev"]

### TARGET: pre-production ###
FROM $NODE_IMAGE as pre-production

RUN \
  apt-get update && \
  apt-get install --yes zsh && \
  apt-get clean

SHELL [ "/bin/zsh", "-c" ]

WORKDIR /app

COPY . .
COPY --from=builder /app/package*.json ./app/
COPY --from=builder /app/node_modules ./node_modules

ENV NODE_ENV=development
ENV ENV=development

RUN \
  apt-get update && \
  apt-get install --yes build-essential make gcc g++ python3 python3-pip curl && \
  apt-get clean

RUN \
  npm version && \
  npm run build && \
  npm cache clean --force

### TARGET: production ###
FROM $NODE_IMAGE as production

RUN \
  apt-get update && \
  apt-get install --yes build-essential make gcc g++ python3 python3-pip zsh curl && \
  apt-get clean

SHELL [ "/bin/zsh", "-c" ]

WORKDIR /app

COPY . .
COPY --from=pre-production /app/package*.json ./app
COPY --from=pre-production /app/node_modules ./node_modules
COPY --from=pre-production /app/dist ./dist

RUN apt-get update && \
  apt-get install --yes build-essential make gcc g++ python3 python3-pip curl && \
  apt-get clean
RUN \
  npm version && \
  npm install && \
  npm ci --omit=dev && \
  npm cache clean --force
  
# ENTRYPOINT ["tail", "-f", "/dev/null"]

