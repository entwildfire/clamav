FROM malice/alpine

LABEL maintainer "https://github.com/entwildfire"

LABEL malice.plugin.repository = "https://github.com/entwildfire/clamav.git"
LABEL malice.plugin.category="av"
LABEL malice.plugin.mime="*"
LABEL malice.plugin.docker.engine="*"

COPY . /go/src/github.com/entwildfire/clamav
RUN apk --update add --no-cache clamav ca-certificates
RUN apk --update add --no-cache -t .build-deps \
  build-base \
  mercurial \
  musl-dev \
  openssl \
  bash \
  wget \
  git \
  gcc \
  go \
  && echo "Building avscan Go binary..." \
  && cd /go/src/github.com/entwildfire/clamav \
  && export GOPATH=/go \
  && go version \
  && go get \
  && go build -ldflags "-s -w -X main.Version=v$(cat VERSION) -X main.BuildTime=$(date -u +%Y%m%d)" -o /bin/avscan \
  && rm -rf /go /usr/local/go /usr/lib/go /tmp/* \
  && apk del --purge .build-deps

# Update ClamAV Definitions
RUN mkdir -p /opt/malice \
  && chown malice /opt/malice \
  && freshclam

# Add EICAR Test Virus File to malware folder
ADD http://www.eicar.org/download/eicar.com.txt /malware/EICAR

RUN chown malice -R /malware

WORKDIR /malware

ENTRYPOINT ["/bin/avscan"]
CMD ["--help"]
