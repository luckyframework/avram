FROM crystallang/crystal:1.6.2
WORKDIR /data

# install base dependencies
RUN apt-get update && \
  apt-get install -y gnupg libgconf-2-4 curl libreadline-dev && \
  # postgres 11 installation
  curl https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - && \
  echo "deb http://apt.postgresql.org/pub/repos/apt/ focal-pgdg main" | tee /etc/apt/sources.list.d/postgres.list && \
  apt-get update && \
  apt-get install -y postgresql-11 && \
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Lucky cli
RUN git clone https://github.com/luckyframework/lucky_cli --branch v0.30.0 --depth 1 /usr/local/lucky_cli && \
  cd /usr/local/lucky_cli && \
  shards install && \
  crystal build src/lucky.cr -o /usr/local/bin/lucky

COPY . /data
