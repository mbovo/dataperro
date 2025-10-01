FROM python:3.13.7-slim as builder
WORKDIR /app
COPY . /app/
RUN apt-get update && apt-get install -y curl=* \
  && sh -c "$(curl --location https://taskfile.dev/install.sh)" -- -d \
  && pip install --no-cache-dir poetry==2.1.3 \
  && ./bin/task build

FROM python:3.13.7-slim
LABEL org.opencontainers.image.source="https://github.com/mbovo/dataperro"
LABEL org.opencontainers.image.authors="Manuel Bovo"
LABEL org.opencontainers.image.maintainers="Manuel Bovo"
LABEL org.opencontainers.image.licenses="CC BY-NC-SA 4.0"
LABEL org.opencontainers.image.title="dataperro"

RUN groupadd --gid 1000 perro && useradd --uid 1000 --gid 1000 -m perro
WORKDIR /app
COPY --from=builder /app/dist/*.whl /app
RUN pip install --no-cache-dir /app/dataperro-*.whl>=0.0.1
USER perro
ENTRYPOINT ["dataperro"]
