FROM nginx:latest
COPY argocd/nginx/VERSION .
COPY docs/_build/html /usr/share/nginx/html/
WORKDIR /usr/share/nginx/html
RUN date +%x_%H:%M:%S:%N >> ./index.html
