ARG VERSION=11.0.8
FROM codeberg.org/forgejo/forgejo:${VERSION}

# TODO: install dependencies
RUN apk add --no-cache \
    sudo \
    postgresql-client \
    curl \
    sed \
    util-linux

# TODO: add a new entrypoint and use it to replace the original one
COPY ./entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/bin/s6-svscan", "/etc/s6"]