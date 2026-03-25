# ─────────────────────────────────────────────────────────────────────────────
# ComfyUI — Dockerfile para deploy no Coolify (VPS)
#
# MODO CPU (padrão): Funciona em qualquer VPS sem GPU
# MODO GPU: Troque a linha FROM abaixo pela versão CUDA
# ─────────────────────────────────────────────────────────────────────────────

# ── CPU (padrão) ──────────────────────────────────────────────────────────────
FROM python:3.11-slim

# ── GPU NVIDIA (descomente se o VPS tiver GPU NVIDIA) ────────────────────────
# FROM nvidia/cuda:12.1.1-cudnn8-runtime-ubuntu22.04
# RUN apt-get update && apt-get install -y python3.11 python3.11-pip python3-pip \
#     && ln -s /usr/bin/python3.11 /usr/bin/python

# ─────────────────────────────────────────────────────────────────────────────

ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1
ENV HF_HUB_DISABLE_TELEMETRY=1
ENV DO_NOT_TRACK=1

WORKDIR /app

# Dependências do sistema
RUN apt-get update && apt-get install -y \
    git \
    wget \
    curl \
    libgl1 \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender-dev \
    libgomp1 \
    && rm -rf /var/lib/apt/lists/*

# Copiar requirements primeiro (cache de layers)
COPY requirements.txt .

# Instalar PyTorch CPU (menor, mais rápido para build)
# Para GPU NVIDIA, substitua pela linha comentada abaixo
RUN pip install --no-cache-dir torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu

# Para GPU NVIDIA com CUDA 12.1:
# RUN pip install --no-cache-dir torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121

# Instalar restante das dependências (sem torch — já instalado)
RUN pip install --no-cache-dir \
    torchsde \
    numpy>=1.25.0 \
    einops \
    "transformers>=4.50.3" \
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
    alembic \
    SQLAlchemy \
    "av>=14.2.0" \
    "comfy-kitchen>=0.2.7" \
    "comfy-aimdo>=0.1.8" \
    requests \
    "kornia>=0.7.1" \
    spandrel \
    "pydantic~=2.0" \
    "pydantic-settings~=2.0" \
    comfyui-frontend-package==1.38.13 \
    comfyui-workflow-templates==0.8.38 \
    comfyui-embedded-docs==0.4.1

# Copiar código fonte
COPY . .

# Criar diretórios para modelos, outputs e inputs
RUN mkdir -p models/checkpoints models/loras models/vae \
    models/controlnet models/clip models/unet \
    output input temp user

# Porta padrão do ComfyUI
EXPOSE 8188

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8188/ || exit 1

# Iniciar ComfyUI com acesso externo habilitado
CMD ["python", "main.py", "--listen", "0.0.0.0", "--port", "8188"]
