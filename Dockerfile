# 保存为 Dockerfile.min
FROM nvidia/cuda:12.2.0-devel-ubuntu22.04
ENV DEBIAN_FRONTEND=noninteractive
ARG PY_VERSION=3.12.0
ARG VLLM_VERSION=v0.10.2

# 1. 把 /tmp、/var/cache/apt、pip 缓存全部挂内存，构建完自动消失
RUN --mount=type=tmpfs,target=/tmp \
    --mount=type=tmpfs,target=/var/cache/apt \
    --mount=type=tmpfs,target=/root/.cache \
    set -ex && \
    # 1. 系统依赖（内存盘里，不占磁盘）
    apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential git wget ca-certificates \
        libbz2-dev libffi-dev libgdbm-dev liblzma-dev libncurses5-dev \
        libreadline-dev libsqlite3-dev libssl-dev make tk-dev \
        xz-utils zlib1g-dev && \
    # 2. Python：边下边编译边删 tarball
    cd /tmp && \
    wget -q https://www.python.org/ftp/python/${PY_VERSION}/Python-${PY_VERSION}.tar.xz && \
    tar -xf Python-${PY_VERSION}.tar.xz && rm -f Python-${PY_VERSION}.tar.xz && \
    cd Python-${PY_VERSION} && \
    ./configure --enable-optimizations --prefix=/usr/local && \
    make -j$(nproc) && make altinstall && \
    cd / && rm -rf /tmp/Python-${PY_VERSION} && \
    ln -sf /usr/local/bin/python3.12 /usr/local/bin/python3 && \
    ln -sf /usr/local/bin/pip3.12   /usr/local/bin/pip3 && \
    # 3. pip 升级
    pip3 install --no-cache-dir -U pip setuptools wheel && \
    # 4. PyTorch：直链 wheel，不缓存
    pip3 install --no-cache-dir \
        https://download.pytorch.org/whl/cu121/torch-2.2.0%2Bcu121-cp312-cp312-linux_x86_64.whl && \
    # 5. vLLM：浅克隆，装完立即删
    cd /tmp && \
    git clone --depth 1 --branch ${VLLM_VERSION} https://github.com/vllm-project/vllm.git && \
    cd vllm && pip3 install --no-cache-dir -e . && \
    cd / && rm -rf /tmp/vllm && \
    # 6. 最后把 apt 索引也清掉（内存盘，其实可有可无）
    apt-get autoremove -y && apt-get clean

ENTRYPOINT ["python3", "-m", "vllm.entrypoints.openai.api_server"]