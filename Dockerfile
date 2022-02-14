FROM rhub/r-minimal

COPY . /pkg

RUN installr -d -t "openssl-dev libgit2-dev libxml2-dev linux-headers" -a "libxml2 openssl libgit2 git" local::/pkg
