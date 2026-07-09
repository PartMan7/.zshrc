
FROM ubuntu:latest

RUN apt-get update && \
    apt-get install -y zsh build-essential procps curl file git && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh | sh

CMD ["zsh"]
