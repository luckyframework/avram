FROM crystallang/crystal:0.29.0

RUN apt-get update && \
  apt-get install -y libgconf-2-4 build-essential curl libreadline-dev libevent-dev libssl-dev libxml2-dev libyaml-dev libgmp-dev git postgresql postgresql-contrib && \
  # Lucky cli
  git clone https://github.com/luckyframework/lucky_cli --branch v0.12.0 --depth 1 /usr/local/lucky_cli && \
  cd /usr/local/lucky_cli && \
  shards install && \
  crystal build src/lucky.cr -o /usr/local/bin/lucky && \
  # Cleanup leftovers
  apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN mkdir /data
WORKDIR /data
ADD . /data
