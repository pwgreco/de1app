set plugin_name "hooah"

namespace eval ::plugins::${plugin_name} {

    # These are shown in the plugin selection page
    variable author "Paul"
    variable contact "local"
    variable version 1.0
    variable name "Hoo-ah"
    variable description "Plays hoo-ah.mp3 when an espresso shot or steaming finishes."

    # Plays through Android's notification/ringer stream (same mechanism as the
    # app's keypress sounds, dui.tcl). Deliberately bypasses ::settings(enable_sounds),
    # which defaults to off. No-op on desktop, where `borg` does not exist.
    proc play {} {
        set path [file join [homedir] [plugin_directory] hooah hoo-ah.mp3]
        if {[catch { borg beep $path } err]} {
            msg -NOTICE [namespace current] "could not play $path: $err"
        } else {
            msg -INFO [namespace current] "played $path"
        }
    }

    # Fires when the flow phase leaves "during" (preinfusion/pouring):
    #   Espresso: pour stops (stop button, SAW/SAV, or profile end)
    #   Steam:    steaming stops, before the purge puffs
    # HotWater and flush are ignored.
    proc on_flow_change {event_dict} {
        set prev_state [dict get $event_dict previous_state]
        if {$prev_state ni {Espresso Steam}} {
            return
        }

        set prev_phase [::de1::state::flow_phase $prev_state \
                            [dict get $event_dict previous_substate]]
        set this_phase [::de1::state::flow_phase \
                            [dict get $event_dict this_state] \
                            [dict get $event_dict this_substate]]

        if {$prev_phase eq "during" && $this_phase ne "during"} {
            play
        }
    }

    proc main {} {
        ::de1::event::listener::on_flow_change_add ::plugins::hooah::on_flow_change
        msg -INFO [namespace current] "hooah plugin loaded"
    }
}
