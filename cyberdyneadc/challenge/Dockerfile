FROM debian:bookworm

RUN apt-get update
RUN apt-get install -y socat perl

# This is where everything lives
ENV APP_HOME /home/ctf
WORKDIR $APP_HOME

# Copy up the binary
COPY src/cyberdyne_adc.pl $APP_HOME/cyberdyne_adc.pl
COPY src/disk.bin $APP_HOME/disk.bin
COPY src/flag_scratches.raw $APP_HOME/flag_scratches.raw
RUN chmod 0755 $APP_HOME/cyberdyne_adc.pl
RUN chmod 0444 $APP_HOME/disk.bin
RUN chmod 0444 $APP_HOME/flag_scratches.raw

RUN useradd -r ctf -u 1000
USER 1000

# Start server
ENTRYPOINT ["socat", "TCP-LISTEN:1800,reuseaddr,fork", "EXEC:'/home/ctf/cyberdyne_adc.pl',pty,stderr,sane"]
