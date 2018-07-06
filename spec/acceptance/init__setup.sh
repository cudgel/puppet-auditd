#!/bin/bash
# If this file exists it will be run on the system under test before puppet runs
# to setup any prequisite test conditions, etc
yum install -y audit
cp /testcase/spec/mock/auditd.service /usr/lib/systemd/system/auditd.service
systemctl daemon-reload
touch /etc/audit/rules.d/puppet_should_remove_this_file.rules