proc eulerAngles { T } {
	set DEGPI 57.29578

	set R11 [lindex [lindex $T 0] 0]; set R12 [lindex [lindex $T 0] 1]; set R13 [lindex [lindex $T 0] 2] 
    set R21 [lindex [lindex $T 1] 0]; set R22 [lindex [lindex $T 1] 1]; set R23 [lindex [lindex $T 1] 2] 
    set R31 [lindex [lindex $T 2] 0]; set R32 [lindex [lindex $T 2] 1]; set R33 [lindex [lindex $T 2] 2] 

    set sy [expr {sqrt ($R11 * $R11 +  $R21 * $R21)}]
    set singular [expr $sy < 1e-6]

    if  { $singular==0 } {
        #set x [expr atan2 (-$R23 , $R33) * $DEGPI]
        #set sy [expr $R13 * cos ($x)]
        #set y [expr atan2 ($sy, $R33) * $DEGPI]
        #set z [expr atan2 (-$R12, $R11) * $DEGPI]

		# Meth 2
        set x [expr atan2 ($R32 , $R33) * $DEGPI]
        set y [expr atan2 (-$R31, $sy) * $DEGPI]
        set z [expr atan2 ($R21, $R11) * $DEGPI]

		# Meth 3
        #set x [expr atan2 (-$R12 , $R22) * $DEGPI]
        #set sy [expr {sqrt (1 - $R32*$R32)}]
        #set y [expr atan2 ($R32, $sy) * $DEGPI]
        #set z [expr atan2 (-$R31, $R33) * $DEGPI]
        #set z [expr [expr int ($z)] % -360]
    }  else {
        set x [expr atan2 (-$R23, $R22) * $DEGPI]
        set y [expr atan2 (-$R31, $sy) * $DEGPI]
        set z [expr 0 * $DEGPI]
    }

    set angles [list $x $y $z]
    return $angles
}

