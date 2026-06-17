load "helpers/test-helpers.bash"

setup() {
    test_setup
}

teardown() {
    test_teardown
}

@test "help path prints usage" {
    run_source_setup -h
    assert_failure
    assert_output --partial "Usage: . tcb-env-setup.sh"
}

@test "executing without sourcing fails" {
    run_direct_script
    assert_failure
    assert_direct_execution_failure_output
}

@test "sourcing succeeds with stubbed dependencies" {
    if shell_supports_dashed_function_name; then
        run_source_setup -a local -c
        assert_success
        assert_output --partial "Setup complete. TorizonCore Builder is ready to be used."
        assert_default_wrapper_exposed
    else
        run_source_setup -a local -c
        assert_failure
        assert_output --partial "Error: shell does not support function names with dashes."
        assert_output --partial "Re-run with -P"
    fi
}

@test "a and t are mutually exclusive" {
    run_source_setup -a remote -t 3.11.0
    assert_failure
    assert_output --partial "Error: -a and -t are mutually exclusive."
}

@test "invalid auto mode is rejected" {
    run_source_setup -a nonsense
    assert_failure
    assert_output --partial "Error: unrecognized value nonsense for -a"
}

@test "invalid storage is rejected" {
    run_source_setup -a local -s 9invalid
    assert_failure
    assert_output --partial "storage must be an absolute directory or a valid Docker volume name"
}

@test "missing value for -a is rejected" {
    run_source_setup -a
    assert_failure
    assert_output --partial "Usage: . tcb-env-setup.sh"
}

@test "missing value for -t is rejected" {
    run_source_setup -t
    assert_failure
    assert_output --partial "Usage: . tcb-env-setup.sh"
}

@test "missing value for -s is rejected" {
    run_source_setup -a local -s
    assert_failure
    assert_output --partial "Usage: . tcb-env-setup.sh"
}

@test "interactive mode fails without tty" {
    run_source_setup
    assert_failure
    assert_output --partial "Error: stdin is not attached to a TTY."
}

@test "non-tty auto mode succeeds" {
    run_source_setup -a local $(portable_args_if_needed)
    assert_success
    assert_output --partial "__TCB_COMMAND__docker run"
}

@test "local auto mode chooses latest local tag" {
    run_source_setup -a local -c $(portable_args_if_needed)
    assert_success
    assert_output --partial "Setting up TorizonCore Builder with version 3.11.0."
    assert_output --partial "__TCB_COMMAND_ARGS__ --rm -v /deploy -v \"\$(pwd)\":/workdir -v storage:/storage"
    refute_output --partial "docker pull"
}

@test "local auto mode errors when no local tags exist" {
    export TCB_STUB_DOCKER_IMAGES_FILE="${TEST_FIXTURES_DIR}/local-tags-empty.txt"
    run_source_setup -a local $(portable_args_if_needed)
    assert_failure
    assert_output --partial "Error: no local versions found!"
}

@test "remote auto mode pulls latest remote tag" {
    run_source_setup -a remote -c $(portable_args_if_needed)
    assert_success
    assert_output --partial "Setting up TorizonCore Builder with version 3.12.1."
    assert_output --partial "Pulling TorizonCore Builder..."
    run grep -F "docker pull torizon/torizoncore-builder:3.12.1" "${TCB_STUB_LOG}"
    assert_success
}

@test "specific tag mode pulls the requested tag" {
    run_source_setup -t 3.11.0 -c $(portable_args_if_needed)
    assert_success
    assert_output --partial "Setting up TorizonCore Builder with version 3.11.0."
    run grep -F "docker pull torizon/torizoncore-builder:3.11.0" "${TCB_STUB_LOG}"
    assert_success
}

@test "early-access tag disables latest-only completion path" {
    run_source_setup -t early-access $(portable_args_if_needed)
    assert_success
    if shell_supports_completion; then
        assert_output --partial "Completion will not be available because selected version of the tool is not the latest official one."
    else
        assert_output --partial "Completion will not be available because the current shell is not supported"
    fi
}

@test "interactive outdated local prompt accepts yes" {
    export TCB_STUB_DOCKER_IMAGES_FILE="${TEST_FIXTURES_DIR}/local-tags-old.txt"
    run_source_setup_tty $'y\n' $(portable_args_if_needed)
    assert_success
    assert_output --partial "You have an outdated version of the tool installed (3.10.0)."
    assert_output --partial "Setting up TorizonCore Builder with version 3.12.1."
}

@test "interactive outdated local prompt accepts no" {
    export TCB_STUB_DOCKER_IMAGES_FILE="${TEST_FIXTURES_DIR}/local-tags-old.txt"
    run_source_setup_tty $'n\n' $(portable_args_if_needed)
    assert_success
    assert_output --partial "You have an outdated version of the tool installed (3.10.0)."
    assert_output --partial "Setting up TorizonCore Builder with version 3.10.0."
}

@test "TCB_NO_PULL skips pull and adds pull-never" {
    export TCB_NO_PULL=1
    run_source_setup -a remote -c $(portable_args_if_needed)
    assert_success
    assert_output --partial "Pulling of the image was disabled by variable TCB_NO_PULL"
    assert_output --partial "__TCB_COMMAND_ARGS__ --rm --pull=never"
    run grep -F "docker pull" "${TCB_STUB_LOG}"
    assert_failure
}

@test "portable command name is selected with -P" {
    run_source_setup -a local -c -P
    assert_success
    assert_portable_wrapper_exposed
    refute_output --partial "Run: torizoncore-builder -h"
}

@test "generated command variables are exported" {
    run_source_setup -a local -c $(portable_args_if_needed)
    assert_success
    assert_output --partial "__TCB_COMMAND_BASE__docker run"
    assert_output --partial "__TCB_COMMAND_ARGS__"
    assert_output --partial "__TCB_COMMAND__docker run"
}

@test "docker option flags affect generated command" {
    run_source_setup -a local -c -d -n -s /var/lib/tcb $(portable_args_if_needed) -- --user 1000:1000 --privileged
    assert_success
    refute_output --partial " -v /deploy"
    refute_output --partial " --network=host"
    assert_output --partial " -v /var/lib/tcb:/storage"
    assert_output --partial " --user 1000:1000 --privileged"
}

@test "completion can be disabled explicitly" {
    run_source_setup -a local -c $(portable_args_if_needed)
    assert_success
    assert_output --partial "Completion script loading disabled by user."
}

@test "latest official tag falls back to remote completion when needed" {
    if ! shell_supports_completion; then
        skip "completion loading is shell-specific"
    fi

    run_source_setup -a remote $(portable_args_if_needed)
    assert_success
    assert_output --partial "Loading completion script from remote repository."
    assert_completion_loaded_for_current_shell_mode
}

@test "container completion is preferred when present" {
    if ! shell_supports_completion; then
        skip "completion loading is shell-specific"
    fi

    export TCB_STUB_DOCKER_COMPLETION_PRESENT=1
    run_source_setup -a remote $(portable_args_if_needed)
    assert_success
    assert_output --partial "Loading completion script from container image."
    refute_output --partial "Loading completion script from remote repository."
    assert_completion_loaded_for_current_shell_mode
}
