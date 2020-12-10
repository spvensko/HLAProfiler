#FROM ubuntu:16.04
#FROM perl:5
FROM ubuntu:xenial
USER root

RUN apt-get update \
  && apt-get install -y bash \
    curl \
    wget \
    make \
    gcc \
    g++ \
    zlib1g-dev \
    file \
    livperl-dev \
  && rm -rf /var/lib/apt/lists/*

RUN yes | cpan App::cpanminus
RUN cpanm Parallel::ForkManager
RUN cpanm -f install Number::Format
RUN cpanm Statistics::Basic

RUN \
  curl -L -O https://github.com/ExpressionAnalysis/HLAProfiler/archive/v.1.10beta.tar.gz && \
  tar xvzf v.1.10beta.tar.gz && \
  rm v.1.10beta.tar.gz

RUN \
  export PATH="/HLAProfiler-v.1.10beta/jellyfish-1.1.11/bin/:$PATH" && \
  export PATH="/HLAProfiler-v.1.10beta/kraken-0.10.5-beta-ea.1/bin/kraken:$PATH" && \
  cd /HLAProfiler-v.1.10beta && \
  perl /HLAProfiler-v.1.10beta/bin/install.pl –d ./ -m wget –b ./bin

RUN \
  cd /opt && \
  echo "download hlaprofiler database" && \
  wget https://github.com/ExpressionAnalysis/HLAProfiler/archive/v1.0.0-db_only.tar.gz && \
  tar xvzf v1.0.0-db_only.tar.gz && \
  rm v1.0.0-db_only.tar.gz

RUN \
  cd /opt && \
  wget https://github.com/ExpressionAnalysis/HLAProfiler/releases/download/v1.0.0-db_only/database.kdb && \
  wget https://github.com/ExpressionAnalysis/HLAProfiler/releases/download/v1.0.0-db_only/database.idx && \
  mv database.kdb HLAProfiler-1.0.0-db_only/hla_database && \
  mv database.idx HLAProfiler-1.0.0-db_only/hla_database
