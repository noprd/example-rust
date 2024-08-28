# Issues #

## Posix bug ##

### Description ###

When expanding the environment variable `WD`
from [docker-compose.yaml](docker-compose.yaml) in [Dockerfile](Dockerfile),
and running `docker compose up --build -d ...`
(see [justfile](justfile) > command: `just docker-build`)
paths like `/usr/home/myapp` would be bafflingly
replaced by `C:/Program Files/Git/usr/home/myapp`.

### Diagnosis ###

This bug occurs on Windows when using the Git Bash console
as is a known issue, see <https://github.com/git-for-windows/build-extra/blob/main/ReleaseNotes.md>.

### Solution ###

Whilst there a new release of Git Bash may solve this issue,
a work around that work with older versions is to simply replace

```.env
DOCKER_WORKDIR="/usr/home/${DOCKER_APP}"
```

via

```.env
DOCKER_WORKDIR="//usr/home/${DOCKER_APP}"
```

in the [.env](templates/template.env) file.
By replacing `//` by `/`, such forced expansions are avoided.
