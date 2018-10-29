# == Define: cron::allow_deny_fragment
#
# Defined type to add users to cron.allow and cron.deny
#
define cron::allow_deny_fragment (
  $users,
  $type,
) {

  # variable validation
  include ::cron

  validate_re($type, ['^allow$','^deny$'],
    'cron::allow_deny_fragment must be allow or deny.')
  validate_array($users)

  $target = $type ? {
    'allow' => $cron::cron_allow_path,
    'deny'  => $cron::cron_deny_path,
  }

  # functionality
  $users_real = flatten($users)

  concat::fragment { $name:
    target  => $target,
    order   => '02',
    content => template('cron/_cron_allow_deny_fragment.erb'),
  }
}
