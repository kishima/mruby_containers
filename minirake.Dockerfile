FROM ruby:3.2.2-bullseye AS build
ARG MRUBY_VER

RUN apt-get update && apt-get install -y \
    build-essential \
    git

RUN git clone https://github.com/mruby/mruby.git /usr/src/mruby
WORKDIR /usr/src/mruby
RUN git checkout $MRUBY_VER
RUN ruby ./minirake

FROM ruby:3.2.2-bullseye
RUN apt-get update && apt-get install -y \
    build-essential \
    git
RUN git clone https://github.com/mruby/mruby.git /usr/src/mruby
WORKDIR /usr/src/mruby
RUN git checkout $MRUBY_VER
COPY --from=build /usr/src/mruby/bin /usr/src/mruby/bin
COPY --from=build /usr/src/mruby/lib /usr/src/mruby/lib
ENV PATH /usr/src/mruby/bin:$PATH
