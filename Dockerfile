FROM ruby:2.7.4

WORKDIR /code
COPY . /code
RUN bundle install

EXPOSE 4567

CMD ["bundle", "exec", "rackup", "--host", "0.0.0.0", "-p", "4567"]
