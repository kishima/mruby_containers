FROM ruby:3.2.2-bullseye
ARG MRUBY_VER

# Debian bullseye は EOL のため、bullseye / bullseye-updates / bullseye-security は
# archive.debian.org に移された。deb.debian.org では apt-get update が通っても
# pool の古いパッケージが消えていて install が 404 になる
# （2026-10 に git_2.30.2-1+deb11u5 で確認）。そのため最初から archive を見る。
# Check-Valid-Until=false は、2026-09 に deb.debian.org の bullseye-security の Release が
# 期限切れで update が失敗したため入れたもの。2026-10 時点の archive の Release には
# Valid-Until が無いので効いていないが、期限付きの Release に戻っても通るよう残す。
RUN set -eux; \
    APT_OPT="-o Acquire::Check-Valid-Until=false"; \
    sed -i \
        -e "s|http://deb.debian.org/debian-security|http://archive.debian.org/debian-security|g" \
        -e "s|http://deb.debian.org/debian|http://archive.debian.org/debian|g" \
        /etc/apt/sources.list; \
    apt-get $APT_OPT update; \
    apt-get $APT_OPT install -y \
        build-essential \
        bison \
        git

RUN git clone https://github.com/mruby/mruby.git /usr/src/mruby
WORKDIR /usr/src/mruby
RUN test -n "$MRUBY_VER" && git checkout "$MRUBY_VER"
RUN rake
ENV PATH /usr/src/mruby/bin:$PATH
