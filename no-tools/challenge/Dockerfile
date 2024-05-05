FROM debian:bookworm

RUN apt update -y && \
apt install socat -y && \
apt clean -y

RUN useradd -m ctf --uid 1000

RUN mkdir -p /home/ctf
RUN chown ctf /home/ctf
RUN chmod 0755 /home/ctf

COPY flag.txt /home/ctf/flag.txt
RUN chmod 0644 /home/ctf/flag.txt

COPY profile /home/ctf/.profile
RUN chown ctf /home/ctf/.profile
RUN chmod 0755 /home/ctf/.profile

WORKDIR /home/ctf

# Make sure sh isn't a symlink
RUN cp --remove-destination /usr/bin/dash /usr/bin/sh

# Give the ctf user permission to /usr/bin so it can be deleted later
RUN chown -R ctf /usr/bin

# Remove everything else, except for what's strictly needed
RUN find /usr/bin  \
  -not -wholename '/usr/bin/sh' -and \
  -not -wholename '/usr/bin/id' -and \
  -not -wholename '/usr/bin/rm' -and \
  -not -wholename '/usr/bin/socat' -and \
  -exec /usr/bin/rm "{}" \;
RUN /usr/bin/rm -rf /etc/alternatives

# Drop privs to the CTF user
USER 1000

ENTRYPOINT ["/usr/bin/socat", "TCP-LISTEN:4445,reuseaddr,fork", "EXEC:'/bin/sh -li',pty,stderr,setsid,sane"]
