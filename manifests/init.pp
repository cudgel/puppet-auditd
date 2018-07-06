# Auditd
#
# Setup and manage auditd using Puppet
#
# This module takes a non-templated approach to management in order to easily incorporate upstream
# changes from vendor.
#
# You may control:
#   * Overall auditd settings in auditd.conf
#   * audispd settings in audispd.conf
#   * Auditd rules (as managed files under /etc/audit/rules.d)
#   * Purging of non-managed rules (default behaviour)
#
# @example Install auditd, manage service and create rules
#   include auditd
#
# @example Hiera data for auditd.conf settings
#   audit::settings:
#     log_format: "ENRICHED"
#     max_log_file: "50"
#     num_logs: "5"
#     max_log_file_action: "rotate"
#     local_events: "yes"
#
# @example Hiera data for audispd.conf settings
#   audit::audispd_settings:
#     overflow_action: syslog
#     priority_boost: 4
#
# @example Hiera data for custom auditd rules
#   audit::rules:
#     10_date_and_time:
#       content: |
#         # data and time
#         -a always,exit -F arch=b64 -S adjtimex -S settimeofday -k time-change
#         -a always,exit -F arch=b32 -S adjtimex -S settimeofday -S stime -k time-change
#         -a always,exit -F arch=b64 -S clock_settime -k time-change
#         -a always,exit -F arch=b32 -S clock_settime -k time-change
#         -w /etc/localtime -p wa -k time-change
#     20_user_and_groups:
#       content: |
#         # users and groups
#         -w /etc/group -p wa -k identity
#         -w /etc/passwd -p wa -k identity
#         -w /etc/gshadow -p wa -k identity
#         -w /etc/shadow -p wa -k identity
#
# @param package_name Name of the audit packages to install
# @param settings Hash of settings for the main auditd.conf config file
# @param audispd_settings Hash of settings for the audispd.conf config file
# @param service_ensure Ensure the audit service to this state
# @param service_enable `true` to start audit service on boot otherwise false
# @param config_file Full path to main auditd.conf config file
# @param audispd_config_file Full path to audispd.conf config file
# @param rules Hash of audit rules to enforce
# @param service_name Name of audit service to manage
# @param purge_rules `true` to remove all non-puppet managed rules from `conf_d` directory
# @param header Warning message to add to top of each managed file
# @param conf_d directory to store rule fragments in
class auditd(
    Array[String]                       $package_name         = ["audit", "audispd-plugins"],
    Hash[String, Any]                   $settings             = {},
    Hash[String, Any]                   $audispd_settings     = {},
    Enum['running','stopped']           $service_ensure       = 'running',
    Boolean                             $service_enable       = true,
    String                              $config_file          = '/etc/audit/auditd.conf',
    String                              $audispd_config_file  = '/etc/audisp/audispd.conf',
    Hash[String, Hash[String, String]]  $rules                = {},
    String                              $service_name         = "auditd",
    Boolean                             $purge_rules          = true,
    String                              $header               = "# managed by puppet",
    String                              $conf_d               = "/etc/audit/rules.d/",
) {

  # Install package
  package { $package_name:
    ensure => 'present',
  }

  # Configure required config files
  file { [$config_file, $audispd_config_file]:
    ensure => 'file',
    owner  => 'root',
    group  => 'root',
    mode   => '0640',
  }

  fm_prepend { $config_file:
    ensure => present,
    data   => $header
  }

  $settings.each |$key, $value| {
    fm_replace { "${config_file}:${key}":
      ensure            => present,
      path              => $config_file,
      data              => "${key} = ${value}",
      match             => "^\s*${key}\s*=",
      insert_if_missing => true,
      insert_at         => 'bottom',
      notify            => Service[$service_name],
    }
  }

  $audispd_settings.each |$key, $value| {
    fm_replace { "${audispd_config_file}:${key}":
      ensure            => present,
      path              => $audispd_config_file,
      data              => "${key} = ${value}",
      match             => "^\s*${key}\s*=",
      insert_if_missing => true,
      insert_at         => 'bottom',
      notify            => Service[$service_name],
    }
  }

  if $purge_rules{
    file { '/etc/audit/rules.d':
      ensure  => 'directory',
      owner   => 'root',
      group   => 'root',
      mode    => '0750',
      recurse => true,
      purge   => true,
    }
  }

  $rules.each |$rule_group_name, $opts| {
    file { "${conf_d}/${rule_group_name}.rules":
      ensure  => 'file',
      owner   => 'root',
      group   => 'root',
      mode    => '0640',
      content => "${header}\n${opts['content']}",
      notify  => Service[$service_name],
    }
  }

  service { $service_name:
    ensure => $service_ensure,
    enable => $service_enable,
  }

}