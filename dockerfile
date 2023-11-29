FROM ubuntu:latest

LABEL maintainer="warroyo@vmware.com"
LABEL version="1.0"

RUN apt-get update && apt-get install -y nginx


EXPOSE 80

ENTRYPOINT ["nginx", "-g", "daemon off;"]

USER appuser