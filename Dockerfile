FROM crystallang/crystal:1.15.1
WORKDIR /data

# install base dependencies
RUN apt-get update && \
  apt-get install -y gnupg curl libreadline-dev wget ca-certificates && \
  # Add PostgreSQL APT repository
  mkdir -p /etc/apt/keyrings && \
  wget -qO - https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor -o /etc/apt/keyrings/postgresql.gpg && \
  echo "deb [signed-by=/etc/apt/keyrings/postgresql.gpg] http://apt.postgresql.org/pub/repos/apt noble-pgdg main" > /etc/apt/sources.list.d/postgres.list && \
  apt-get update && \
  apt-get install -y postgresql-16 && \
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Lucky cli
RUN git clone https://github.com/luckyframework/lucky_cli --branch main --depth 1 /usr/local/lucky_cli && \
  cd /usr/local/lucky_cli && \
  shards install && \
  crystal build src/lucky.cr -o /usr/local/bin/lucky

COPY . /data
