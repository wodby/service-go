# Go on Wodby

What Wodby sets up for an application that runs on this service. Check it before changing the build, the port or connection settings in the code.

## Build and start

The service's Dockerfile copies the repository to `/usr/src/app` and, when there are `.go` files at its root:

1. runs `go mod download` when `go.mod` exists;
2. runs `go build -o /home/wodby/go/bin/app .`

The container starts that binary as `app`. So with the service's Dockerfile the `main` package must be at the root of the repository. A pipeline that passes a Dockerfile from the repository (`wodby ci build go -f Dockerfile`) uses that file instead; it must still end with a command that starts the server.

- The application must listen on port 8080, on all interfaces. That is the port of the service's HTTP endpoint. The service sets no `PORT` variable in a deployed environment: default to 8080 in the code.
- The service sets no other variable for the application and generates no configuration file.
- The service declares no volume of its own: files written inside the container are lost when it is replaced.

## Linked services

Links to other services reach the application as environment variables. Nothing in the image reads them: the application reads them itself. Do not hardcode hosts or credentials.

| Link | Variables |
| --- | --- |
| Database (MariaDB, MySQL or PostgreSQL) | `DB_HOST`, `DB_PORT`, `DB_NAME` (also `DB_DATABASE`), `DB_USERNAME`, `DB_PASSWORD`, `DB_DRIVER` (also `DB_CONNECTION`) |
| Mail | `SMTP_HOST`, `SMTP_PORT` |
| Redis or Valkey | `REDIS_HOST`, `REDIS_PORT`, `REDIS_PASSWORD` |

All three links are optional. A variable is present only while its link exists and the linked service is enabled. The mail link carries no credentials.

## Environment

- `WODBY_HOSTS` is a JSON array of the environment's hosts, not a comma-separated string. `WODBY_PRIMARY_HOST` and `WODBY_PRIMARY_URL` are the canonical ones for links generated outside a request.
- `WODBY_APP_SERVICE_NAME` is this service's host name inside the environment. Other services reach the application at that name on port 8080.
- `WODBY_ENV_TYPE` tells a development environment from a production-like one.

## In a development workspace

- The checkout is mounted at `/usr/src/app`. The application is compiled from it and run, and the checkout is watched: when a file changes, it is compiled again and the application is restarted with the new build, in the same container, usually within a few seconds. Nothing has to be restarted or deployed for a code change. A build that fails leaves the previous build running; the compiler's errors are in the service's logs.
- Workspace setup resolves dependencies with `workspace-go prepare`. `go.mod` is required. Builds use `-mod=readonly` on a temporary copy of `go.mod` and `go.sum`, so the repository's files are never rewritten: a missing requirement or checksum fails the build and must be fixed in the repository with `go get` or `go mod tidy`.
- The package built is `.`; `WORKSPACE_GO_PACKAGE` on the service selects another one, such as `./cmd/server`.
- `HOST` and `PORT` are set, to `0.0.0.0` and `8080` by default. The application must read them or listen on 8080 anyway.
- A repository with a `go.work` file is refused. It needs `WORKSPACE_GO_COMMAND` on the service, which replaces the start command.
- The compiled binary is `.wodby-workspace/app` in the checkout. `.wodby-workspace/` is kept out of Git status without touching `.gitignore`.
- A change to variables or linked services still needs a deployment of the environment.

## Check the result

- `curl -s -o /dev/null -w '%{http_code}' localhost:8080` from the container shows whether the application answers on the expected port.
- `go build ./... && go vet ./...` in the checkout shows compile errors at once; the service's logs show them too when a change does not appear.
