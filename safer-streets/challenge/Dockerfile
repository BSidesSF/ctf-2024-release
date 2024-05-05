FROM ruby:3.2.3

RUN apt-get update
RUN apt-get install -y net-tools ruby-bundler ncat socat libmagickwand-dev libmagickcore-dev libzbar-dev

# Configuration
ENV HOST 0.0.0.0
ENV PORT 8080

# This is where everything lives
ENV APP_HOME /app
WORKDIR $APP_HOME

# Copy the app
COPY www/ $APP_HOME
RUN find $APP_HOME -type f -exec chmod 0644 "{}" \;
RUN find $APP_HOME -type d -exec chmod 0755 "{}" \;
RUN chown -R root.root $APP_HOME

# Install gems
RUN bundle install

# Copy up the safer-streets binary
COPY src/safer-streets $APP_HOME/safer-streets
RUN chmod 0755 $APP_HOME/safer-streets

# Copy up the print_flag binary, and make sure the standard user can't access it
COPY src/print-flag /home/ctf/print-flag
RUN chown root.root /home/ctf/print-flag
RUN chmod 0711 /home/ctf/print-flag

# We need this script to do nothing
RUN ln -s /usr/bin/true /usr/bin/report-infraction

RUN useradd -r ctf -u 1000
USER 1000

# Start server
CMD ["ruby", "./server.rb"]
