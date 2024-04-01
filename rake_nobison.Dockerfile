FROM ruby:3.2.2-bullseye
ARG MRUBY_VER

RUN apt-get update && apt-get install -y \
    build-essential \
    git

RUN git clone https://github.com/mruby/mruby.git /usr/src/mruby
WORKDIR /usr/src/mruby
RUN git checkout $MRUBY_VER
RUN rake
ENV PATH /usr/src/mruby/bin:$PATH
