#@PDQTest

$settings =  {
  "log_format"          => "ENRICHED",
  "max_log_file"        => "50",
  "num_logs"            => "5",
  "max_log_file_action" => "rotate",
  "local_events"        => "yes",
}

$rules = {
  "10_date_and_time" => {
    "content" => "
# data and time
-a always,exit -F arch=b64 -S adjtimex -S settimeofday -k time-change
-a always,exit -F arch=b32 -S adjtimex -S settimeofday -S stime -k time-change
-a always,exit -F arch=b64 -S clock_settime -k time-change
-a always,exit -F arch=b32 -S clock_settime -k time-change
-w /etc/localtime -p wa -k time-change",
  },
  "20_user_and_group" => {
    "content" => "
# users and groups
-w /etc/group -p wa -k identity
-w /etc/passwd -p wa -k identity
-w /etc/gshadow -p wa -k identity
-w /etc/shadow -p wa -k identity",
  }
}

class { "auditd":
  settings => $settings,
  rules    => $rules,
}