FROM crystallang/crystal:0.29.0

RUN apt-get update && \
  apt-get install -y libgconf-2-4 build-essential curl libreadline-dev libevent-dev libssl-dev libxml2-dev libyaml-dev libgmp-dev git postgresql postgresql-contrib && \
  apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Lucky cli
RUN git clone https://github.com/luckyframework/lucky_cli /usr/local/lucky_cli
WORKDIR "/usr/local/lucky_cli"
RUN git checkout v0.12.0
RUN shards install
RUN crystal build src/lucky.cr
RUN mv lucky /usr/local/bin

RUN mkdir /data
WORKDIR /data
ADD . /data
