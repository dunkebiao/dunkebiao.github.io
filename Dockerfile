
# 使用ruby
FROM ruby:latest

# 维护者
MAINTAINER dunkebiao dunkebiao@tsingpu.com

RUN bundle config mirror.https://rubygems.org https://gems.ruby-china.org
RUN gem install jekyll rdiscount

WORKDIR /var/www