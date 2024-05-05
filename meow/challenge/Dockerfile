FROM debian:latest

RUN apt update -y && \
apt install socat -y && \
apt clean -y


RUN useradd -m ctf -u1000

ADD bashrc /home/ctf/.bashrc

ADD flag.txt /home/ctf/

RUN chown -R root:ctf /home/ctf

USER 1000

ENTRYPOINT ["socat", "TCP-LISTEN:4445,reuseaddr,fork", "EXEC:'/bin/bash -li',pty,stderr,setsid,sane"]
