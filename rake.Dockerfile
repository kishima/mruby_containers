FROM debian:bookworm AS build
ARG MRUBY_VER

RUN apt-get update && apt-get install -y \
    build-essential \
    bison \
    ruby \
    git

RUN git clone https://github.com/mruby/mruby.git /usr/src/mruby
WORKDIR /usr/src/mruby
RUN git checkout $MRUBY_VER
RUN rake && rake install

FROM debian:bookworm
RUN apt-get update && apt-get install -y \
    build-essential \
    bison \
    ruby \
    git
RUN git clone https://github.com/mruby/mruby.git /usr/src/mruby
WORKDIR /usr/src/mruby
RUN git checkout $MRUBY_VER
COPY --from=build /usr/local/ /usr/local
