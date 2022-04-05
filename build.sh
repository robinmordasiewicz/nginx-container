#!/bin/bash
#

set -e

VERSION=`cat VERSION`

docker build -t robinhoodis/nginx:${VERSION} .
docker push robinhoodis/nginx:${VERSION}

docker build -t robinhoodis/nginx:latest .
docker push robinhoodis/nginx:latest
