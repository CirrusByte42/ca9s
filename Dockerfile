# -----------------------------------------------------------------------------
# The base image for building the ca9s binary

FROM golang:1.23-alpine3.20 AS build

WORKDIR /ca9s
COPY go.mod go.sum main.go Makefile ./
COPY internal internal
COPY cmd cmd
RUN apk --no-cache add --update make libx11-dev git gcc libc-dev curl && make build

# -----------------------------------------------------------------------------
# Build the final Docker image

FROM alpine:3.20.3
ARG KUBECTL_VERSION="v1.29.0"

COPY --from=build /ca9s/execs/ca9s /bin/ca9s
RUN apk add --update ca-certificates \
  && apk add --update -t deps curl vim \
  && TARGET_ARCH=$(arch | sed s/aarch64/arm64/ | sed s/x86_64/amd64/) \
  && curl -L https://storage.googleapis.com/kubernetes-release/release/${KUBECTL_VERSION}/bin/linux/${TARGET_ARCH}/kubectl -o /usr/local/bin/kubectl \
  && chmod +x /usr/local/bin/kubectl \
  && apk del --purge deps \
  && rm /var/cache/apk/*

ENTRYPOINT [ "/bin/ca9s" ]
