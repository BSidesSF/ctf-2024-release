FROM debian:bookworm

RUN apt-get update
RUN apt-get install -y net-tools ncat socat

# This is where everything lives
ENV APP_HOME /home/ctf
WORKDIR $APP_HOME

# Copy up the binary
COPY src/humain $APP_HOME/humain
RUN chmod 0755 $APP_HOME/humain

RUN useradd -r ctf -u 1000
USER 1000

# Start server
ENTRYPOINT ["/usr/bin/socat", "TCP-LISTEN:2049,reuseaddr,fork", "EXEC:'/home/ctf/humain',pty,stderr,setsid,sane"]
