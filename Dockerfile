# Main image
FROM nvcr.io/nvidia/cuda:12.5.1-cudnn-runtime-ubuntu22.04

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

WORKDIR /

# Prevents prompts from packages asking for user input during installation
ENV DEBIAN_FRONTEND=noninteractive
# Prefer binary wheels over source distributions for faster pip installations
ENV PIP_PREFER_BINARY=1
# Ensures output from python is printed immediately to the terminal without buffering
ENV PYTHONUNBUFFERED=1

ENV ROOT="/rp-vol" \
	RP_VOLUME="/workspace"
ENV HF_DATASETS_CACHE="/runpod-volume/huggingface-cache/datasets" \
    HF_HUB_CACHE="/runpod-volume/huggingface-cache/hub" \
    HF_HOME="/runpod-volume/huggingface-cache" \
    HF_HUB_ENABLE_HF_TRANSFER=1

RUN apt-get update && apt-get install software-properties-common -y
RUN add-apt-repository ppa:deadsnakes/ppa
# Update apps
RUN --mount=type=cache,id=dev-apt-cache,sharing=locked,target=/var/cache/apt \
    --mount=type=cache,id=dev-apt-lib,sharing=locked,target=/var/lib/apt \
	apt update && \
    apt upgrade -y && \
    apt install -y --no-install-recommends \
        build-essential \
        software-properties-common \
    	python3.11 \
        python3.11-venv \
        nodejs \
        npm \
        bash \
        dos2unix \
        git \
        git-lfs \
        ncdu \
        nginx \
        net-tools \
        dnsutils \
        inetutils-ping \
        openssh-server \
        libglib2.0-0 \
        libsm6 \
        libgl1 \
        libxrender1 \
        libxext6 \
        ffmpeg \
        wget \
        curl \
        psmisc \
        rsync \
        vim \
        zip \
        unzip \
        p7zip-full \
        htop \
        screen \
        tmux \
        bc \
        aria2 \
        cron \
        pkg-config \
        plocate \
        libcairo2-dev \
        libgoogle-perftools4 \
        libtcmalloc-minimal4 \
        apt-transport-https \
        ca-certificates

# Install .NET
RUN wget https://dot.net/v1/dotnet-install.sh -O dotnet-install.sh && \
    chmod +x dotnet-install.sh && \
    ./dotnet-install.sh --channel 8.0 --runtime aspnetcore && \
    ./dotnet-install.sh --channel 8.0 && \
    rm dotnet-install.sh

RUN update-ca-certificates
RUN wget https://bootstrap.pypa.io/get-pip.py && \
	python3.11 get-pip.py && \
	rm get-pip.py

RUN update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.11 3 && \
	update-alternatives --install /usr/bin/python python /usr/bin/python3.11 3 && \
    update-alternatives --config python3

RUN pip install -U jupyterlab \
        jupyterlab_widgets \
        ipykernel \
        ipywidgets \
        gdown \
        OhMyRunPod --no-cache-dir --prefer-binary

RUN curl https://rclone.org/install.sh | bash

 # Update rclone
RUN rclone selfupdate
RUN curl https://getcroc.schollz.com | bash
RUN curl -s  \
    https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.deb.sh \
    | bash && \
        apt install -y speedtest

RUN pip install --upgrade pip setuptools pickleshare --no-cache-dir --prefer-binary

# Install additional Python packages
RUN pip install --no-cache-dir --prefer-binary \
    comfyui-frontend-package==1.16.9 \
    comfyui-workflow-templates==0.1.1 \
    torch \
    torchsde \
    torchvision \
    torchaudio \
    "numpy>=1.25.0" \
    einops \
    "transformers>=4.28.1" \
    "tokenizers>=0.13.3" \
    sentencepiece \
    "safetensors>=0.4.2" \
    "aiohttp>=3.11.8" \
    "yarl>=1.18.0" \
    pyyaml \
    Pillow \
    scipy \
    tqdm \
    psutil \
    "kornia>=0.7.1" \
    spandrel \
    soundfile \
    av

# Upgrade apt packages and install required dependencies

ARG TCMALLOC="/usr/lib/x86_64-linux-gnu/libtcmalloc.so.4"
ENV LD_PRELOAD=${TCMALLOC}

RUN mkdir -vp ${ROOT}/.cache

# Cleanup section (Worker Template)
RUN apt-get autoremove -y && \
    apt-get clean -y && \
    rm -rf /var/lib/apt/lists/*

# Set Python
#RUN ln -s /usr/bin/python3.12 /usr/bin/python
RUN pip cache purge

# Build files
WORKDIR ${ROOT}

ENV NVIDIA_VISIBLE_DEVICES=all
# Install the required python packages
ENV SWARM_NO_VENV="false"
ENV SYNCTHING_HOME=/workspace/syncthing
# install syncthing
RUN curl -s -o /usr/share/keyrings/syncthing-archive-keyring.gpg https://syncthing.net/release-key.gpg && \
	echo "deb [signed-by=/usr/share/keyrings/syncthing-archive-keyring.gpg] https://apt.syncthing.net/ syncthing stable" | \
	tee /etc/apt/sources.list.d/syncthing.list && \
	apt-get update && \
    apt-get install syncthing

# copy from local to container
RUN mkdir -p /launchx
COPY --chmod=755 ./scripts/start.sh /launchx/start.sh

# Download and install SwarmUI

# START
CMD ["/launchx/start.sh"]