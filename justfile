# ----------------------------------------------------------------
# NOTE: Setting shell does not work!
# For GitHub-actions we need "bash", but
# for Windows we need "sh".
# The solution is to ensure tasks are written with bash-shebang
# if they involve bash-syntax, e.g. 'if [[ ... ]] then else fi'.
# ----------------------------------------------------------------
# set shell := [ "bash", "-c" ]
_default:
    @- just --unsorted --list
menu:
    @- just --unsorted --choose
# ----------------------------------------------------------------
# Justfile
# Recipes for various workflows.
# ----------------------------------------------------------------

set dotenv-load := true
set positional-arguments := true

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# VARIABLES
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

PATH_ROOT := justfile_directory()
CURRENT_DIR := invocation_directory()
OS := if os_family() == "windows" { "windows" } else { "linux" }
PYVENV_ON := if os_family() == "windows" { ". .venv/Scripts/activate" } else { ". .venv/bin/activate" }
PYVENV := if os_family() == "windows" { "python" } else { "python3" }
TOOL_TEST_BDD := "behave"
EXT := if os_family() == "windows" { ".exe" } else { "" }

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Macros
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

_clean-all-files path pattern:
    #!/usr/bin/env bash
    find {{path}} -type f -name "{{pattern}}" -exec basename {} \; 2> /dev/null
    find {{path}} -type f -name "{{pattern}}" -exec rm {} \; 2> /dev/null
    exit 0;

_clean-all-folders path pattern:
    #!/usr/bin/env bash
    find {{path}} -type d -name "{{pattern}}" -exec basename {} \; 2> /dev/null
    find {{path}} -type d -name "{{pattern}}" -exec rm -rf {} \; 2> /dev/null
    exit 0;

_check-tool tool name:
    #!/usr/bin/env bash
    success=false
    {{tool}} --version >> /dev/null 2> /dev/null && success=true;
    {{tool}} --help >> /dev/null 2> /dev/null && success=true;
    # NOTE: if exitcode is 251 (= help or print version), then render success.
    if [[ "$?" == "251" ]]; then success=true; fi
    # FAIL tool not installed
    if ( $success ); then
        echo -e "Tool \x1b[2;3m{{name}}\x1b[0m installed correctly.";
        exit 0;
    else
        echo -e "Tool \x1b[2;3m{{tool}}\x1b[0m did not work." >> /dev/stderr;
        echo -e "Ensure that \x1b[2;3m{{name}}\x1b[0m (-> \x1b[1mjust build\x1b[0m) installed correctly and system paths are set." >> /dev/stderr;
        exit 1;
    fi

_docker-build-and-log service progress="tty":
    @echo "BUILD DOCKER +LOG {{service}}"
    @docker compose down --remove-orphans {{service}}
    @docker compose logs -f --tail=0 {{service}} \
        && docker compose --progress={{progress}} up --build -d {{service}}

_docker-build-and-interact service container progress="tty":
    @echo "BUILD DOCKER +INTERACT {{service}} / {{container}}"
    @docker compose --progress={{progress}} up --build -d {{service}} \
        && docker attach {{container}}

_docker-run-and-log service progress="tty":
    @echo "RUN DOCKER +LOG {{service}}"
    @docker compose down --remove-orphans {{service}}
    @docker compose logs -f --tail=0 {{service}} \
        && docker compose --progress={{progress}} up {{service}}

_docker-exec service cmd:
    @echo "EXEC DOCKER CMD {{service}} / {{cmd}}"
    @docker compose down --remove-orphans {{service}}
    @docker compose run --service-ports {{service}} {{cmd}}

_docker-exec-interactive service cmd args:
    @echo "EXEC DOCKER CMD (it) {{service}} / {{cmd}}"
    @docker compose down --remove-orphans {{service}}
    @docker compose run --interactive --service-ports {{service}} {{cmd}}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# TARGETS
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# TARGETS: build
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

setup:
    @mkdir -p "setup"
    @mkdir -p ".vscode"
    @- cp -n "templates/template.env" ".env"
    @- cp -n "templates/template-config.yaml" "setup/config.yaml"
    @- cp -n "templates/template-extensions.json" ".vscode/extensions.json"
    @- cp -n "templates/template-launch.json" ".vscode/launch.json"
    @- cp -n "templates/template-settings.json" ".vscode/settings.json"
    @- cp -n "templates/template-tasks.json" ".vscode/tasks.json"
    @- cp -n "templates/template-host.json" "host.json"
    @- cp -n "templates/template-local.settings.json" "local.settings.json"

build:
    @echo "TASK: BUILD"
    @just build-requirements
    @just build-compile
    @just build-artefact
    @just check-system-requirements

build-requirements:
    @echo "SUBTASK: build requirements"
    @cargo update --verbose
    @rustup target add "${ARCHITECTURE}"
    @cargo install --locked cargo-zigbuild

build-compile:
    @echo "SUBTASK: compile code"
    @rm -f "dist/${ARTEFACT_NAME}" 2> /dev/null
    @cargo zigbuild --release --target-dir "target"

build-artefact:
    @echo "SUBTASK: extract artefact"
    @cp "target/release/${PROJECT_NAME}" "dist/${ARTEFACT_NAME}-v$(cat dist/VERSION){{EXT}}"

build-archive:
    @echo "SUBTASK: create .zip archive of project"
    @# store current state
    @git add . && git commit --no-verify --allow-empty -m "temp"
    @# create archive
    @git archive --output "dist/${PROJECT_NAME}-$(cat dist/VERSION).zip" HEAD
    @# undo above commit
    @git reset --soft HEAD~1 && git reset .

# process for release
dist:
    @echo "TASK: create release"
    @just setup
    @just build
    @just build-archive

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# TARGETS: run
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

run *args:
    @RUST_BACKTRACE=1 cargo run \
        --offline \
        --target-dir "target" \
        --release "$@"

run-debug *args:
    @RUST_BACKTRACE=1 cargo run \
        --offline \
        --verbose \
        --color "always" \
        --target-dir "target" \
        --message-format "human"

run-binary *args:
    @./dist/${ARTEFACT_NAME}-v$(cat dist/VERSION){{EXT}}

examples log_path="logs":
    #!/usr/bin/env bash
    echo -e "CREATE EXAMPLES" >> /dev/stdout;
    just _reset-logs
    while read path; do
        if [[ "${path}" == "" ]]; then continue; fi
        echo "RUN EXAMPLE ${path} - Not yet implemented"
    done <<< $( find examples/example_*.rs -mindepth 0 -maxdepth 0 2> /dev/null );
    exit 0;

# --------------------------------
# TARGETS: docker
# --------------------------------

docker-explore service="build":
    @just _docker-exec "{{service}}" "bash"

docker-build progress="tty":
    @just _docker-build-and-log "build" "{{progress}}"

docker-run progress="tty":
    @just _docker-run-and-log "run" "{{progress}}"

docker-run-binary progress="tty":
    @just _docker-run-and-log "run-binary" "{{progress}}"

docker-utests progress="tty":
    @just _docker-run-and-log "utests" "{{progress}}"

docker-btests progress="tty":
    @echo "Not yeat implemented"

docker-itests progress="tty":
    @echo "Not yeat implemented"

docker-tests progress="tty":
    @just docker-utests "{{progress}}"
    @just docker-btests "{{progress}}"
    @just docker-itests "{{progress}}"

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# TARGETS: development
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

dev *args:
    @just _reset-logs
    @touch test.rs
    @echo "Not yet implemented"

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# TARGETS: tests
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

tests:
    @just tests-unit
    @just tests-cases
    @just tests-behave
    @just tests-integration

tests-logs log_path="logs":
    @just _reset-logs "{{log_path}}"
    @- just tests
    @just _display-logs "{{log_path}}"

test-unit path="":
    #!/usr/bin/env bash
    # NOTE: path must be in the form path::to::module (without / or .rs)
    path="{{path}}"
    path="${path//\//::}"
    path="${path//.rs/}"
    # run unit tests
    cargo test "${path}"

tests-unit:
    @cargo test

tests-behave *arrgs:
    @echo "Not yet implemented"

tests-cases *args:
    @echo "Not yet implemented"

tests-integration *args:
    @echo "Not yet implemented"

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# TARGETS: prettify
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# NOTE: This looks unintuitive, but *.rs instead of **/*.rs is correct.
lint path="src/*.rs":
    rustfmt --edition 2021 --verbose --color "auto" {{path}}

lint-check path="src/*.rs":
    @rustfmt --edition 2021 --verbose --color "auto" --check {{path}}

prettify:
    @- just lint "src/*.rs" 2> /dev/null
    @- just lint "tests/*.rs" 2> /dev/null
    @- just lint "examples/*.rs" 2> /dev/null

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# TARGETS: clean
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

clean log_path="logs":
    @echo "All system artefacts will be force removed."
    @- just _clean-all-files "." ".DS_Store" 2> /dev/null
    @echo "All execution artefacts will be force removed."
    @- rm -rf "{{log_path}}" 2> /dev/null
    @echo "All build artefacts will be force removed."
    @- rm -rf "target" 2> /dev/null
    @- just _clean-all-folders "." ".idea" 2> /dev/null
    @echo "All docker images will be removed."
    @- docker-compose down -v --rmi all --remove-orphans 2> /dev/null

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# TARGETS: logs
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

_clear-logs log_path="logs":
    @rm -rf "{{log_path}}"

_create-logs log_path="logs":
    @just _create-logs-part "debug" "{{log_path}}"
    @just _create-logs-part "out" "{{log_path}}"
    @just _create-logs-part "err" "{{log_path}}"

_create-logs-part part log_path="logs":
    @mkdir -p "{{log_path}}"
    @touch "{{log_path}}/{{part}}.log"

_reset-logs log_path="logs":
    @rm -rf "{{log_path}}"
    @just _create-logs "{{log_path}}"

_reset-test-logs kind:
    @rm -rf "tests/{{kind}}/logs"
    @just _create-logs-part "debug" "tests/{{kind}}/logs"

_display-logs log_path="logs":
    @echo ""
    @echo "Content of {{log_path}}/debug.log:"
    @echo "----------------"
    @echo ""
    @- cat "{{log_path}}/debug.log"
    @echo ""
    @echo "----------------"

watch-logs n="10" log_path="logs":
    @tail -f -n {{n}} "{{log_path}}/out.log"

watch-logs-err n="10" log_path="logs":
    @tail -f -n {{n}} "{{log_path}}/err.log"

watch-logs-debug n="10" log_path="logs":
    @tail -f -n {{n}} "{{log_path}}/debug.log"

watch-logs-all n="10" log_path="logs":
    @just watch-logs {{n}} "{{log_path}}" &
    @just watch-logs-err {{n}} "{{log_path}}" &
    @just watch-logs-debug {{n}} "{{log_path}}" &

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# TARGETS: requirements
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

check-system:
    @echo "Operating System detected:  {{os_family()}}"
    @echo "Cargo command:              $( cargo --version )"
    @echo "Rustc command:              $( rustc --version )"
    @echo "Cargo Zigbuild:             $( cargo-zigbuild --version )"

check-system-requirements:
    @just _check-tool "cargo" "cargo"
    @just _check-tool "cargo zigbuild" "cargo-zigbuild"
