FROM debian:testing

RUN apt-get update && apt-get -y install ca-certificates && apt-get -y satisfy "golang (>= 1.21)"

RUN mkdir -p /src
WORKDIR /src
COPY ./cwa/go.mod /src/go.mod
COPY ./cwa/go.sum /src/go.sum
RUN go mod download

RUN mkdir -p /opt/cwa/files
COPY ./cwa.config.json /opt/cwa/cwa.config.json
COPY ./files/* /opt/cwa/files
COPY ./cwa /src

RUN go build -o /opt/cwa/cwa ./cmd/cwa

WORKDIR /opt/cwa
RUN /opt/cwa/cwa -listen "" || mv /opt/cwa/core* /opt/cwa/files/core

RUN useradd -u 1337 -U ctf && chown -R ctf:ctf /opt/cwa

USER 1337

EXPOSE 5432/tcp

CMD ["/opt/cwa/cwa", "-listen", "0.0.0.0:5432"]
