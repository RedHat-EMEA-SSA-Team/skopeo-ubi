FROM registry.access.redhat.com/ubi8/go-toolset:latest as builder

LABEL maintainer="Robert Bohne <robert.bohne@redhat.com>"

ENV SKOPEO_VERSION=v0.1.40

RUN git clone -b $SKOPEO_VERSION https://github.com/containers/skopeo.git && \
    cd skopeo/ && \
    make binary-local DISABLE_CGO=1

FROM registry.access.redhat.com/ubi8/ubi-minimal:latest as final

LABEL maintainer="Robert Bohne <robert.bohne@redhat.com>"

RUN mkdir /etc/containers/

COPY --from=builder /opt/app-root/src/skopeo/default-policy.json /etc/containers/policy.json
COPY --from=builder /opt/app-root/src/skopeo/skopeo /usr/bin/

