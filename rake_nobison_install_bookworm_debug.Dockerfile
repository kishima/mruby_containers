FROM ruby:3.2.2-bookworm AS build
ARG MRUBY_VER

RUN apt-get update && apt-get install -y \
    build-essential \
    git

RUN git clone https://github.com/mruby/mruby.git /usr/src/mruby
WORKDIR /usr/src/mruby
RUN git checkout $MRUBY_VER
# 既定の build_config/default.rb のうち enable_debug だけを有効にする。
# host-debug.rb は gembox や boxing 設定まで変わるため使わない（通常版と同じ bytecode を出すことが目的）。
RUN grep -q "^  # conf.enable_debug" build_config/default.rb && sed -i "s/^  # conf.enable_debug/  conf.enable_debug/" build_config/default.rb
RUN rake && rake install

FROM ruby:3.2.2-bookworm
RUN apt-get update && apt-get install -y \
    build-essential \
    git
RUN git clone https://github.com/mruby/mruby.git /usr/src/mruby
WORKDIR /usr/src/mruby
RUN git checkout $MRUBY_VER
COPY --from=build /usr/local/ /usr/local
