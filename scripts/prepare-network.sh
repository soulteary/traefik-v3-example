#!/bin/bash

NETWORK_NAME=traefik

if [ -z $(docker network ls --filter name=^${NETWORK_NAME}$ --format="{{ .Name }}") ] ; then
    # 创建 Docker 网络
    output=$(docker network create ${NETWORK_NAME});
    # 检查输出是否为64位长度的字符串
    if [[ ${#output} -eq 64 ]]; then
        echo "create docker network for traefik ok"
    else
        echo "Network creation failed or output is not 64 characters long."
    fi
fi
