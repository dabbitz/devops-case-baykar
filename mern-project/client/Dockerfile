# Build stage
FROM node:20-alpine AS build

WORKDIR /app

COPY package*.json ./

RUN npm install

COPY . .

ARG REACT_APP_API_URL
ENV REACT_APP_API_URL=$REACT_APP_API_URL

RUN npm run build


# Production stage
FROM nginx:alpine

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/build /usr/share/nginx/html

RUN mkdir -p /var/cache/nginx \
    /var/run/nginx \
    /var/log/nginx \
    /tmp/nginx \
    && chown -R nginx:nginx \
        /var/cache/nginx \
        /var/run/nginx \
        /var/log/nginx \
        /tmp/nginx \
        /usr/share/nginx/html \
    && chown nginx:nginx /etc/nginx/conf.d/default.conf \
    && sed -i 's#pid[[:space:]]\+/run/nginx.pid;#pid /tmp/nginx.pid;#' /etc/nginx/nginx.conf

USER nginx

EXPOSE 8000

CMD ["nginx", "-g", "daemon off;"]