#@PDQTest

# force a restart by adding a bogus value, just need to make sure puppet run
# doesn't error here. This merits a separate test due to the auditd not
# supporting restarts via systemd
class { "auditd":
  settings => {"force_restart" => "true"}
}