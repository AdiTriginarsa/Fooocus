FROM nvidia/cuda:12.2.0-runtime-ubuntu22.04
ENV DEBIAN_FRONTEND noninteractive
ENV CMDARGS --listen

RUN apt-get update -y && \
	apt-get install -y curl libgl1 libglib2.0-0 python3-pip python-is-python3 git wget && \
	apt-get clean && \
	rm -rf /var/lib/apt/lists/*

COPY requirements_docker.txt requirements_versions.txt /tmp/
RUN pip install --no-cache-dir -r /tmp/requirements_docker.txt -r /tmp/requirements_versions.txt && \
	rm -f /tmp/requirements_docker.txt /tmp/requirements_versions.txt
RUN pip install --no-cache-dir xformers==0.0.23 --no-dependencies
RUN curl -fsL -o /usr/local/lib/python3.10/dist-packages/gradio/frpc_linux_amd64_v0.2 https://cdn-media.huggingface.co/frpc-gradio-0.2/frpc_linux_amd64 && \
	chmod +x /usr/local/lib/python3.10/dist-packages/gradio/frpc_linux_amd64_v0.2

RUN adduser --disabled-password --gecos '' user && \
	mkdir -p /content/app /content/data

WORKDIR /content/app/models/checkpoints
RUN wget -O illustrious-xl.safetensors https://huggingface.co/OnomaAIResearch/Illustrious-xl-early-release-v0/resolve/main/Illustrious-XL-v0.1.safetensors
    
WORKDIR /content/app/models/loras
RUN wget -O otti.safetensors https://huggingface.co/AdiCakepLabs/otti_v1/resolve/main/otti.safetensors
RUN wget -O otti_v2_000002.safetensors https://huggingface.co/AdiCakepLabs/otti_v2/blob/main/otti_v2-000002.safetensors

COPY entrypoint.sh /content/
RUN chown -R user:user /content

WORKDIR /content
USER user

COPY --chown=user:user . /content/app
RUN mv /content/app/models /content/app/models.org

CMD [ "sh", "-c", "/content/entrypoint.sh ${CMDARGS}" ]
