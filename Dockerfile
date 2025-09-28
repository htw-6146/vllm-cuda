FROM nvidia/cuda:12.2.0-devel-ubuntu22.04
ENV DEBIAN_FRONTEND=noninteractive
ARG VLLM_VERSION=v0.10.2

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        python3 python3-dev python3-pip python3-venv \
        build-essential git ca-certificates && \
    rm -rf /var/lib/apt/lists/* && \
    python3 -m pip install -U --no-cache-dir pip setuptools wheel numpy

RUN pip install --no-cache-dir \
        --extra-index-url https://download.pytorch.org/whl/cu121 \
        torch==2.2.0+cu121

# 3. 源码构建 vLLM（落盘安装，最后清理）
RUN cd /tmp && \
    git clone --depth 1 --branch ${VLLM_VERSION} https://github.com/vllm-project/vllm.git && \
    cd vllm && \
    pip3 install --no-cache-dir -e . && \
    cd / && \
    rm -rf /tmp/vllm /root/.cache/pip

ENTRYPOINT ["python3", "-m", "vllm.entrypoints.openai.api_server"]
