FROM dart:stable AS build

WORKDIR /app
COPY pubspec.* ./
RUN dart pub get

COPY . .
RUN dart pub get  # Run again after copying all files
RUN dart compile exe bin/server.dart -o bin/server

FROM debian:bullseye-slim

RUN apt-get update && apt-get install -y \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY --from=build /app/bin/server /app/bin/server
COPY --from=build /app/public /app/public

EXPOSE 1337
CMD ["/app/bin/server"]