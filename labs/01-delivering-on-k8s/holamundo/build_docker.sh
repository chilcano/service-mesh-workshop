#!/bin/bash

set -o errexit

SCRIPTDIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

## building a docker image and setting the tag 'chilcano/holamundo:release1'
docker build -t chilcano/holamundo:release1 --build-arg service_version=v666 ${SCRIPTDIR}

# cd holamundo
# docker build --rm -t chilcano/holamundo:latest .
# docker build --rm -t chilcano/holamundo:v1 .
# docker run -dt --name=hola-v1 -p 5050:5000 chilcano/holamundo:v1
# docker run -d -t --name=hola-latest -p 5051:5000 chilcano/holamundo:latest
