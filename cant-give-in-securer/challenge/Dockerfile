FROM httpd:2.4.58

RUN apt update && apt install -y socat ncat

RUN rm -rf /usr/local/apache2/htdocs/*
RUN rm -rf /usr/local/apache2/cgi-bin/*

RUN sed -i 's/Listen 80/Listen 8080/' /usr/local/apache2/conf/httpd.conf

COPY web/*.html /usr/local/apache2/htdocs/
RUN chmod 0644 /usr/local/apache2/htdocs/*.html

COPY src/*.cgi /usr/local/apache2/cgi-bin/
RUN chmod 0755 /usr/local/apache2/cgi-bin/*.cgi

RUN mkdir /home/ctf
COPY flag.txt /home/ctf/flag.txt
RUN chmod 0644 /home/ctf/flag.txt

RUN useradd -r ctf -u 1000
RUN chown -R ctf:ctf /usr/local/apache2
USER 1000

CMD httpd-foreground -c "LoadModule cgid_module modules/mod_cgid.so"
