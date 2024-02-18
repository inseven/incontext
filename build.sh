#!/bin/bash

docker run \
       --rm \
       -v /home/jbmorley/Projects/incontext:/app  \
       -v /usr/include:/usr/include \
       -v /usr/lib:/libs \
       -w /app \
       swift:latest \
       swift \
       build


# -u $(id -u ${USER}):$(id -g ${USER}) \
