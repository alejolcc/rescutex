# Custom build for postgres with postgis & pgvector enabledCustom build for postgres with postgis & pgvector enabled
# Ita can be improved removing some stuff maybe but for now is just fine

FROM postgis/postgis:17-master

# Install pgvector dependencies
RUN apt-get update && apt-get install -y \
  build-essential \
  postgresql-server-dev-$(pg_config --version | sed -e 's/.* //g' -e 's/\..*//g') \
  git \
  --no-install-recommends && \
  rm -rf /var/lib/apt/lists/*

# Clone and build pgvector
RUN git clone https://github.com/pgvector/pgvector.git /tmp/pgvector && \
  cd /tmp/pgvector && \
  make && \
  make install && \
  rm -rf /tmp/pgvector