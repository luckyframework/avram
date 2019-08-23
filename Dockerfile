FROM crystallang/crystal:0.30.0

RUN apt-get update && \
  apt-get install -y libgconf-2-4 build-essential curl libreadline-dev libevent-dev libssl-dev libxml2-dev libyaml-dev libgmp-dev git wget

# Lucky cli
RUN git clone https://github.com/luckyframework/lucky_cli --branch v0.17.0 --depth 1 /usr/local/lucky_cli && \
  cd /usr/local/lucky_cli && \
  shards install && \
  crystal build src/lucky.cr -o /usr/local/bin/lucky

# Install updated pg client
RUN touch /etc/apt/sources.list.d/pgdg.list
RUN echo "deb http://apt.postgresql.org/pub/repos/apt/ xenial-pgdg main" > /etc/apt/sources.list.d/pgdg.list
RUN wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
RUN apt-get update && apt-get install -y postgresql-11

# Cleanup leftovers
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN mkdir /data
WORKDIR /data
ADD . /data
