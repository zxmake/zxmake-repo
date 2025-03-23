FROM ubuntu:22.04

RUN sed -i 's/archive.ubuntu.com/mirrors.aliyun.com/g' /etc/apt/sources.list \
    && apt-get clean && apt-get update && apt-get install -y --fix-missing \
    build-essential \
    git \
    make \
    sudo

# install xmake master
ENV XMAKE_ROOT=y
ENV XMAKE_STATS=n
ENV XMAKE_PROGRAM_DIR=/usr/local/share/xmake
ENV XMAKE_MAIN_REPO=https://github.com/zxmake/zxmake-repo.git
ENV XMAKE_BINARY_REPO=https://github.com/zxmake/zxmake-build-artifacts.git

RUN mkdir /software && cd /software \
    && git clone --recursive https://github.com/TOMO-CAT/xmake.git \
    && cd xmake \
    && git checkout ${XMAKE_COMMIT_VERSION} \
    && bash scripts/install.sh \
    && xmake --version \
    && cd / && rm -r software

RUN apt-get install -y --fix-missing \
    curl \
    sudo \
    cmake \
    unzip

ARG USER_NAME=root
RUN useradd -m ${USER_NAME}
RUN echo "${USER_NAME} ALL=NOPASSWD: ALL" >> /etc/sudoers
USER ${USER_NAME}
