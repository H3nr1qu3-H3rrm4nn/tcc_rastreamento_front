# syntax=docker/dockerfile:1
FROM ghcr.io/cirruslabs/flutter:3.24.3

WORKDIR /app

COPY pubspec.yaml .
COPY pubspec.lock ./
RUN flutter pub get >/dev/null

COPY . .
RUN flutter pub get >/dev/null

RUN chmod +x docker/start.sh

EXPOSE 8080

CMD ["/app/docker/start.sh"]
