FROM nginx:latest
COPY VERSION .
COPY html /usr/share/nginx/html/
WORKDIR /usr/share/nginx/html
RUN date +%x_%H:%M:%S:%N >> ./index.html
