FROM ruby:3.2.3-slim-bookworm

ARG BUNDLER_VERSION=2.4.20

ENV LANG=C.UTF-8 \
    BUNDLE_PATH=/usr/local/bundle \
    BUNDLE_IGNORE_CONFIG=1 \
    BUNDLE_JOBS=4 \
    BUNDLE_RETRY=3

RUN apt-get update -qq \
    && apt-get install --no-install-recommends -y \
      build-essential \
      ca-certificates \
      libpq-dev \
    && rm -rf /var/lib/apt/lists/*

RUN gem install bundler --no-document --version "${BUNDLER_VERSION}"

WORKDIR /app

COPY Gemfile Gemfile.lock ./
RUN bundle _${BUNDLER_VERSION}_ install

COPY . .

EXPOSE 3000

CMD ["sh", "-lc", "rm -f tmp/pids/server.pid && exec bundle exec rails server -b 0.0.0.0 -p ${PORT:-3000}"]
