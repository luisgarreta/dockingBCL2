#!/usr/bin/env xvmdg.py
package require Orient
namespace import Orient::orient

set PROT  [lindex $argv 0]
mol new $PROT
set sel [atomselect top "all"]
#set selHG [atomselect top "resid 105 to 112 or resid 120 to 131"]
#set sel [atomselect top "all"]
set I [draw principalaxes $sel]
puts $I

#exec /bin/stty raw <@stdin
#set c [read stdin 1]
#
#set A [orient $sel [lindex $I 2] {0 0 1}]
#$sel move $A
#set I [draw principalaxes $sel]
#
#exec /bin/stty raw <@stdin
#set c [read stdin 1]
#
#set A [orient $sel [lindex $I 1] {0 1 0}]
#$sel move $A
#set I [draw principalaxes $sel]
#
#exec /bin/stty raw <@stdin
#set c [read stdin 1]
#

#exit
