FROM nginx:latest
WORKDIR /usr/share/nginx/html
RUN date +%x_%H:%M:%S:%N >> ./index.html

ADD VERSION .

RUN apt-get --yes update \
    && apt-get --yes upgrade \
    && apt install net-tools
