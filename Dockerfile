ARG WODBY_BASE_IMAGE
FROM ${WODBY_BASE_IMAGE}

ARG COPY_FROM
COPY --chown=wodby:wodby ${COPY_FROM} /usr/src/app

RUN if ls *.go >/dev/null 2>&1; then \
      if [ -f go.mod ]; then go mod download; fi; \
      go build -o /home/wodby/go/bin/app .; \
    fi

CMD ["app"]
