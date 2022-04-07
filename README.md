# nginx-container


kubectl create secret docker-registry dockercred \
    --docker-server=https://index.docker.io/v1/ \
    --docker-username=<dockerhub-username> \
    --docker-password=<dockerhub-password>\
    --docker-email=<dockerhub-email>

kubectl get secret regcred --output="jsonpath={.data.\.dockerconfigjson}" | base64 -d
