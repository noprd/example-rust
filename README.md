[![Rust version: 0.18.*](https://img.shields.io/badge/rust%20version-0.18.*-black)](https://www.rust-lang.org)

[![qa manual:main](https://github.com/noprd/example-rust/actions/workflows/manual.yaml/badge.svg?branch=main)](https://github.com/noprd/example-rust/actions/workflows/manual.yaml)
[![qa manual:staging](https://github.com/noprd/example-rust/actions/workflows/manual.yaml/badge.svg?branch=staging)](https://github.com/noprd/example-rust/actions/workflows/manual.yaml)

[![qa auto:staging](https://github.com/noprd/example-rust/actions/workflows/auto.yaml/badge.svg?branch=staging)](https://github.com/noprd/example-rust/actions/workflows/auto.yaml)
[![qa auto:current](https://github.com/noprd/example-rust/actions/workflows/auto.yaml/badge.svg)](https://github.com/noprd/example-rust/actions/workflows/auto.yaml)

# Example Rust #

This repository provides a simple Hello-World example of an http-server
written in [rust](https://www.rust-lang.org),
which in recent years has gained importance.

## Requirements ##

- A bash terminal.
  Windows users can e.g. install this via <https://gitforwindows.org>.

- The [justfile](https://github.com/casey/just?tab=readme-ov-file#installation) tool.

- [Rust](https://www.rust-lang.org/tools/install) `~0.18.0` incl. the cargo package manager.

> [!IMPORTANT]
> We also require an installation of [Zig](https://ziglang.org) for cross-compilation.
> This avoids gcc-compiler issues on your local machine,
> which the rust compiler requires to install some dependencies.

Ensure paths to the binaries have been set.

> [!TIP]
> To verify, open a bash terminal and call.
>
> ```bash
> just --version
> # rust
> rustup --version
> rustc --version
> cargo --version
> # zig
> zig version
> # docker
> docker version
> docker compose version
> ```

### Optional requirements ###

- [Postman](https://www.postman.com/downloads),
  also available as a [VSCode extension](https://marketplace.visualstudio.com/items?itemName=Postman.postman-for-vscode).
- (necessary for [docker usage](#via-docker))
  [docker](https://docs.docker.com/engine/install) incl. the docker CLI.

## Usage ##

Open a bash terminal and run:

```bash
just setup
```

This is only needed once.
After this, adjust the values in the newly created **.env** files
based on the [template](templates/template.env).

### Direct usage ###

Open a bash terminal and run:

```bash
# compiles code and creates binary artefact in ./dist folder
just build
# execution
just run-binary # runs from binary
just run # runs from source code (this may involve recompiling dependencies / code)
# tests
just tests-unit
# linting
just prettify
```

### Via docker ###

Start up the docker engine.

```bash
# compiles code and creates binary artefact in ./dist folder
just docker-build
# execution
just docker-run-binary # runs from binary created in container
just docker-run # runs from source code (this may involve recompiling dependencies / code)
# tests
just docker-utests # runs unit-tests within container
# linting
just prettify
# exploration
just explore {service} # service = one of build, run, run-binary, utests
```

> [!TIP]
> Due to the volume mounting (see [docker-compose.yaml](docker-compose.yaml)),
> whilst "exploring" you can alter the source code
> and run the tests using the commands exactly as stated in [Direct Usage](#direct-usage).

> [!NOTE]
> Changes performed whilst exploring the container will mostly be reverted
> (bar those performed on mounted volumes),
> once the container is exited.

## Interaction with the Http-Server ##

Whilst "running" the compiled code
(via either
`just run-binary`,
`just run`,
`just docker-run-binary`,
`just docker-run`;
see above),
the endpoints are exposed to the `HTTP_PORT` value set in your **.env**-file.

The exposed endpoints of the application can now be spoken to, e.g.

```bash
curl --request GET 'http://{HTTP_IP}:{HTTP_PORT}/api/ping'
curl --request POST 'http://{HTTP_IP}:{HTTP_PORT}/api/token' \
    --data '{"key1": value1, "key2", value2, ...}'
```

where `{HTTP_IP}` and `{HTTP_PORT}` are to be replaced by the values set in your **.env**-file.
Alternatively, we recommend using [Postman](https://www.postman.com/downloads).

### Clean up ###

To clean up build artefacts and dangling docker images,
simply run

```bash
just clean
```

To be more thorough, you may wish to run

```bash
docker system prune
```

> [!WARNING]
> The latter command clears _all_ docker images, containers, etc.
> not just for this project.
