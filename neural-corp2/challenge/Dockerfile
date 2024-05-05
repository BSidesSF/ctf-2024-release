FROM ubuntu:20.04

RUN apt-get update -y && \
    apt-get install -y python3-pip python3-dev && \
    apt-get install sqlite3

COPY . /app

WORKDIR /app

RUN useradd -m ctf -u2000
RUN chown -R root:ctf /home/ctf
RUN chmod 777 .
RUN chmod 777 instance/database.db
RUN chmod 777 instance

RUN pip install -r requirements.txt


EXPOSE 5000

USER 2000

ENTRYPOINT [ "python3" ]

CMD [ "server.py" ]
