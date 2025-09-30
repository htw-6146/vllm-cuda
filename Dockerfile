# Dockerfile.min
FROM swr.cn-north-4.myhuaweicloud.com/ddn-k8s/docker.io/nvidia/cuda:12.2.0-devel-ubuntu22.04
ENV DEBIAN_FRONTEND=noninteractive
ENV CMAKE_BUILD_PARALLEL_LEVEL=16
ARG VLLM_VERSION=v0.10.2          # 仅做标记，实际用本地代码

# 换 Ubuntu 源
RUN sed -i 's@http://.*.ubuntu.com@https://mirrors.tuna.tsinghua.edu.cn@g' /etc/apt/sources.list

# 安装系统依赖
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        python3 python3-dev python3-pip python3-venv \
        build-essential git ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# 换 PyPI 源
RUN mkdir -p /etc/pip && \
    printf "[global]\nindex-url = https://mirrors.aliyun.com/pypi/simple/\ntrusted-host = mirrors.aliyun.com\n" > /etc/pip.conf

# 升级基础工具
RUN python3 -m pip install -U --no-cache-dir pip setuptools wheel numpy

# 把本地已改好的 vllm 源码复制进来
COPY vllm /tmp/vllm

# 构建并安装 vLLM，完成后清理
RUN cd /tmp/vllm && \
    pip install --no-cache-dir -e . && \
    cd / && \
    rm -rf /tmp/vllm /root/.cache/pip

ENTRYPOINT ["python3", "-m", "vllm.entrypoints.openai.api_server"]
