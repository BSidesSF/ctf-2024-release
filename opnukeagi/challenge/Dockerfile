FROM debian:bookworm

RUN apt-get update
RUN apt-get install -y socat perl

# This is where everything lives
ENV APP_HOME /home/ctf
WORKDIR $APP_HOME

# Copy up the binary
COPY src/galois_lfsr.pl $APP_HOME/galois_lfsr.pl
RUN chmod 0755 $APP_HOME/galois_lfsr.pl

RUN useradd -r ctf -u 1000
USER 1000

# Start server
ENTRYPOINT ["socat", "TCP-LISTEN:6464,reuseaddr,fork", "EXEC:'/home/ctf/galois_lfsr.pl',pty,stderr,sane"]

