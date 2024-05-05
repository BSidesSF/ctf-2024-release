FROM debian:bookworm@sha256:1aadfee8d292f64b045adb830f8a58bfacc15789ae5f489a0fedcd517a862cb9

RUN apt-get update
RUN apt-get install -y net-tools ncat socat procps gdb

# This is where everything lives
ENV APP_HOME /home/ctf
WORKDIR $APP_HOME

# Copy up the binary
COPY src/turing-incomplete64 $APP_HOME/turing-incomplete64
RUN chmod 0755 $APP_HOME/turing-incomplete64

# Copy the libc library, just in case
COPY src/libc.so.6 /usr/lib/x86_64-linux-gnu/libc.so.6
RUN chmod 0755 /usr/lib/x86_64-linux-gnu/libc.so.6

# Copy up the flag
COPY src/flag.txt /home/ctf/flag.txt
RUN chown root.root /home/ctf/flag.txt
RUN chmod 0644 /home/ctf/flag.txt

RUN useradd -r ctf -u 1000
USER 1000

# Start server
ENTRYPOINT ["socat", "TCP-LISTEN:1954,reuseaddr,fork", "EXEC:'/home/ctf/turing-incomplete64'"]
