ARG WODBY_BASE_IMAGE
FROM ${WODBY_BASE_IMAGE}

ARG COPY_FROM
ARG COPY_TO=/usr/src/app
COPY --chown=wodby:wodby ${COPY_FROM} ${COPY_TO}

RUN if ls *.go >/dev/null 2>&1; then \
      if [ -f go.mod ]; then go mod download; fi; \
      go build -o /home/wodby/go/bin/app .; \
    fi

CMD ["app"]
