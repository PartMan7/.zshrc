
FROM ubuntu:latest

ENV PARTZSH_NONINTERACTIVE=1 \
    PARTZSH_SKIP_CLONE=1 \
    PARTZSH=/root/.partzsh

RUN apt-get update && \
    apt-get install -y zsh build-essential procps curl file git parallel gawk findutils && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh | bash

COPY . /root/.partzsh
RUN sh /root/.partzsh/install.sh

CMD ["zsh", "-l"]
