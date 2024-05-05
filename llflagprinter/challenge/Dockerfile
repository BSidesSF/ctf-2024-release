FROM ruby:3.2.3

RUN apt-get update
RUN apt-get install -y net-tools ncat socat

# This is where everything lives
ENV APP_HOME /home/ctf
WORKDIR $APP_HOME

# Copy up the binary
#COPY src/slay-the-spider $APP_HOME/slay-the-spider
#RUN chmod 0755 $APP_HOME/slay-the-spider

# Copy up the flag
#COPY src/flag.txt /home/ctf/flag.txt
#RUN chown root.root /home/ctf/flag.txt
#RUN chmod 0644 /home/ctf/flag.txt

#RUN useradd -r ctf -u 1000
#USER 1000

# Start server
#ENTRYPOINT ["socat", "TCP-LISTEN:4441,reuseaddr,fork", "EXEC:'/home/ctf/slay-the-spider'"]
