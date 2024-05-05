FROM debian:bookworm

RUN apt-get update
RUN apt-get install -y socat

# This is where everything lives
ENV APP_HOME /home/ctf
WORKDIR $APP_HOME

# Copy up the binary
COPY src/truthescrow $APP_HOME/truthescrow
COPY src/banner.txt $APP_HOME/banner.txt
RUN chmod 0755 $APP_HOME/truthescrow
RUN chmod 0444 $APP_HOME/banner.txt

# Copy up the flag
COPY src/flag_1.txt $APP_HOME/flag_1.txt
COPY src/flag_2.txt $APP_HOME/flag_2.txt

RUN chmod 0444 $APP_HOME/flag_1.txt
RUN chmod 0444 $APP_HOME/flag_2.txt

RUN useradd -r ctf -u 1000
USER 1000

# Start server
ENTRYPOINT ["socat", "TCP-LISTEN:1984,reuseaddr,fork", "EXEC:'/home/ctf/truthescrow',pty,stderr,sane"]
