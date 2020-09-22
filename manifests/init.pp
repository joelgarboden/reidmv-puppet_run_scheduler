# puppet_run_scheduler
#
# A description of what this class does
#
# @summary A short summary of the purpose of this class
#
# @example
#   include puppet_run_scheduler
class puppet_run_scheduler (
  Enum['present', 'absent']          $ensure       = 'present',
  Puppet_run_scheduler::Run_interval $run_interval = '30m',
  Pattern[/[0-2]\d:\d\d/]            $start_time   = '00:00',
  Puppet_run_scheduler::Run_interval $splaylimit   = $run_interval,
) {
  $interval_mins = puppet_run_scheduler::minutes($run_interval)
  $splaylimit_mins = puppet_run_scheduler::minutes($splaylimit)

  $splay_mins = fqdn_rand($splaylimit_mins, 'puppet_run_scheduler')
  # https://ask.puppet.com/question/24257/why-does-the-statement-008-0-fail-saying-it-cant-convert-to-numeric/?answer=24302#post-id-24302
  $input_start_hour = Integer($start_time[0,2].scanf('%d')[0])
  $input_start_min  = Integer($start_time[3,2].scanf('%d')[0])

  $splayed_start_epoch_mins = $input_start_hour * 60 + $input_start_min + $splay_mins
  $first_start_epoch_mins   = $splayed_start_epoch_mins % $interval_mins

  $runs_per_day = 1440 / $interval_mins
  $start_hour = $first_start_epoch_mins / 60
  $start_min  = $first_start_epoch_mins % 60

  $agent_flags = '--onetime --no-daemonize --splay --splaylimit=60s'

  case $facts[os][family] {
    'windows': { contain puppet_run_scheduler::windows }
    default:   { contain puppet_run_scheduler::posix   }
  }

  if ($ensure == 'present') {
    $service_enable = false
    $service_ensure = stopped
  } else {
    $service_enable = true
    $service_ensure = running
  }

  service { 'puppet':
    ensure => $service_ensure,
    enable => $service_enable,
  }
}
