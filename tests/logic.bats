load "helpers/test-helpers.bash"

setup() {
    test_setup
}

teardown() {
    test_teardown
}

@test "latest tag logic picks the highest semantic version" {
    run_logic_body '_tcb_get_latest_tag 3.11.0 3.9.9 malformed 3.12.1 3.12.0'
    assert_success
    assert_output "3.12.1"
}

@test "latest tag logic ignores malformed values" {
    run_logic_body '_tcb_get_latest_tag latest early-access 3.12 invalid 4..1'
    assert_failure
}
