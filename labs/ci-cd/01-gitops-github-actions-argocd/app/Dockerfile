# Demo app image for Lab 01. Built for linux/arm64 and linux/amd64 by CI.
FROM python:3.13-slim

# CI passes the Git commit SHA here, so the running app can show its version.
ARG APP_VERSION=dev
ENV APP_VERSION=${APP_VERSION} \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app
COPY server.py .

# Run as a non-root user (matches runAsUser in deploy/deployment.yaml).
RUN useradd --uid 10001 --no-create-home --shell /usr/sbin/nologin app
USER 10001

EXPOSE 8080
CMD ["python", "server.py"]
