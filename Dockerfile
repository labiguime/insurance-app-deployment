FROM ruby:2.6.6-slim-stretch

EXPOSE 3000

ARG RAILS_ROOT=/application
ARG BUILD_PACKAGES="build-essential libpq-dev unzip python3-pip python3-setuptools git "
ARG DEV_PACKAGES="nodejs yarn cron"
ARG RUBY_PACKAGES="tzdata pdftk bash"

RUN apt-get update -qq && apt-get upgrade -yq && apt-get install -yq curl && \
  curl -sL https://deb.nodesource.com/setup_14.x | bash - && \
  curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
  echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list && \
  apt-get update -qq && apt-get upgrade -yq && apt-get install -yq --no-install-recommends $BUILD_PACKAGES $DEV_PACKAGES $RUBY_PACKAGES && pip3 install awscli

WORKDIR $RAILS_ROOT

COPY Gemfile* package.json yarn.lock ./

RUN gem install bundler:2.1.4

COPY Gemfile Gemfile.lock $RAILS_ROOT/
RUN bundle config --global frozen 1 \
    && bundle install --without development:test:assets -j4 --retry 3 --path=vendor/bundle \
    # Remove unneeded files (cached *.gem, *.o, *.c)
    && rm -rf vendor/bundle/ruby/2.6.0/cache/*.gem \
    && find vendor/bundle/ruby/2.6.0/gems/ -name "*.c" -delete \
    && find vendor/bundle/ruby/2.6.0/gems/ -name "*.o" -delete \
    && yarn install

COPY ./Rakefile $RAILS_ROOT/Rakefile
COPY ./app/models/application_record.rb $RAILS_ROOT/app/models/application_record.rb
COPY ./app/assets $RAILS_ROOT/app/assets
COPY ./app/validators $RAILS_ROOT/app/validators
COPY ./bin $RAILS_ROOT/bin
COPY ./lib $RAILS_ROOT/lib
COPY ./app/models/concerns $RAILS_ROOT/app/models/concerns
COPY ./app/models/user.rb $RAILS_ROOT/app/models/
COPY ./config $RAILS_ROOT/config

COPY ./beanstalk $RAILS_ROOT/beanstalk

ENV RAILS_MASTER_KEY=efb719192e050838193062ca7a1a746f
RUN mv config/credentials.yml.enc config/credentials.yml.enc.backup && \
    mv beanstalk/credentials.yml.enc config/credentials.yml.enc && \
    mv beanstalk/master.key config/master.key && \
    RAILS_MASTER_KEY=efb719192e050838193062ca7a1a746f RAILS_ENV=production bundle exec rake assets:precompile && \
    mv config/credentials.yml.enc.backup config/credentials.yml.enc && \
    rm config/master.key

ARG AWS_DEFAULT_REGION
ARG AWS_CONTAINER_CREDENTIALS_RELATIVE_URI
RUN tar -zcf public.tar.gz public/ \
  && aws s3 cp public.tar.gz s3://haywards-utils/public.tar.gz

COPY . .

ARG master_key
ARG environment
ENV RAILS_MASTER_KEY=$master_key \
    RAILS_ENV=$environment \
    NODE_ENV=$environment \
    RACK_ENV=$environment

CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]

RUN bundle exec whenever --update-crontab
