FROM ruby:3.2.2-bullseye
ARG MRUBY_VER

# Debian bullseye は EOL のため、bullseye-security の Release ファイルが
# 期限切れになっており、素の `apt-get update` は exit 100 で失敗する。
# Check-Valid-Until=false で期限切れを許容する。
# また将来 deb.debian.org から bullseye が撤去された場合に備え、
# 失敗時は archive.debian.org へフォールバックする。
# （2026-09 時点では bullseye-security はまだ archive に無いため、
#   フォールバックは deb.debian.org が使えなくなってからの保険）
RUN set -eux; \
    APT_OPT="-o Acquire::Check-Valid-Until=false"; \
    apt-get $APT_OPT update \
    || { \
        sed -i \
            -e "s|http://deb.debian.org/debian-security|http://archive.debian.org/debian-security|g" \
            -e "s|http://deb.debian.org/debian|http://archive.debian.org/debian|g" \
            /etc/apt/sources.list; \
        apt-get $APT_OPT update; \
    }; \
    apt-get $APT_OPT install -y \
        build-essential \
        bison \
        git

RUN git clone https://github.com/mruby/mruby.git /usr/src/mruby
WORKDIR /usr/src/mruby
RUN git checkout $MRUBY_VER
RUN rake
ENV PATH /usr/src/mruby/bin:$PATH
