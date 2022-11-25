
proc draw_axes { mol sel {weights domass} } {
    if { $weights == "domass" } {
        set weights [ $sel get mass ]
    }

    set I [Orient::calc_principalaxes $sel $weights]
    set a1 [lindex $I 0]
    set a2 [lindex $I 1]
    set a3 [lindex $I 2]

    # find the size of the system
    set minmax [measure minmax $sel]
    set ranges [vecsub [lindex $minmax 1] [lindex $minmax 0]]
    set scale [expr .7*[Orient::max [lindex $ranges 0] \
                             [lindex $ranges 1] \
                             [lindex $ranges 2]]]
    set scale2 [expr 1.02 * $scale]

    # draw some nice vectors
    graphics $mol delete all
    graphics $mol color yellow
    set COM [Orient::sel_com $sel $weights]
    vmd_draw_vector $mol $COM [vecscale $scale $a1]
    vmd_draw_vector $mol $COM [vecscale $scale $a2]
    vmd_draw_vector $mol $COM [vecscale $scale $a3]

    graphics $mol color white
    graphics $mol text [vecadd $COM [vecscale $scale2 $a1]] "1"
    graphics $mol text [vecadd $COM [vecscale $scale2 $a2]] "2"
    graphics $mol text [vecadd $COM [vecscale $scale2 $a3]] "3"
    
    return [list $a1 $a2 $a3]
}

