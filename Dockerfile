# File: Dockerfile.ansible
FROM python:3.9-slim

RUN apt-get update && \
    apt-get install -y sshpass iputils-ping curl && \
    pip install ansible && \
    mkdir /ansible

WORKDIR /ansible

CMD [ "tail", "-f", "/dev/null" ]

