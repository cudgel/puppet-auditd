@test "audit service OK" {
    systemctl status auditd
}

@test "log_format set" {
    grep "log_format = ENRICHED" /etc/audit/auditd.conf
}

@test "max_log_file set" {
    grep "max_log_file = 50" /etc/audit/auditd.conf
}

@test "num_logs set" {
    grep "num_logs = 5" /etc/audit/auditd.conf
}

@test "local_events set" {
    grep "local_events = yes" /etc/audit/auditd.conf
}

@test "10_date_and_time.rules created" {
    ls /etc/audit/rules.d/10_date_and_time.rules
}

@test "10_date_and_time.rules content" {
    grep "# data and time" /etc/audit/rules.d/10_date_and_time.rules
}

@test "20_user_and_group.rules created" {
    ls /etc/audit/rules.d/20_user_and_group.rules
}

@test "20_user_and_group.rules content" {
    grep "# users and groups" /etc/audit/rules.d/20_user_and_group.rules
}

@test "puppet purges unmanaged rules" {
    ! ls /etc/audit/rules.d/puppet_should_remove_this_file.rules
}