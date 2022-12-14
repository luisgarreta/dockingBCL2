#
# $Id: qwikmd_func.tcl,v 1.72 2019/10/30 16:56:43 jribeiro Exp $
#
#==============================================================================
proc QWIKMD::procs {} {

    global tcl_platform env

     if {$::tcl_platform(os) == "Darwin"} {
        catch {exec sysctl -n hw.ncpu} proce
        return $proce
      } elseif {$::tcl_platform(os) == "Linux"} {
        catch {exec grep -c "model name" /proc/cpuinfo} proce
        return $proce
      } elseif {[string first "Windows" $::tcl_platform(os)] != -1} {
        catch {HKEY_LOCAL_MACHINE\HARDWARE\DESCRIPTION\System\CentralProcessor } proce
        set proce [llength $proce]
        return $proce
      }
}
proc QWIKMD::loadTopologies {} {
    set QWIKMD::topoinfo [list]
    foreach topo $QWIKMD::TopList {
        if {[file exists $topo]} {
            set handler [::Toporead::read_charmm_topology $topo 1]
            lappend QWIKMD::topoinfo [::Toporead::topology_from_handler $handler]
        }
    }

}

proc QWIKMD::redirectPuts {outputfile cmd } {
    set cmdOK 0
    rename ::puts ::tcl::orig::puts

    proc ::puts args "
        if {\$args == \{\}} {set args \" \"}
        if {\[file channels \[lindex \[lindex \$args 0\] 0\]  \] == \[lindex \[lindex \$args 0\] 0\] && \[lindex \[lindex \$args 0\] 0\] != \"\"} {
             uplevel \"::tcl::orig::puts \[lindex \[lindex \$args 0\] 0\] \[lrange \$args 1 end\]\"; return
        } else {
            uplevel \"::tcl::orig::puts $outputfile \$args\"; return
        }    
    "
    set outcommand ""
    set cmdOK [eval catch {$cmd} outcommand]
    rename ::puts {}
    rename ::tcl::orig::puts ::puts
    return "$cmdOK $outcommand"
}

proc QWIKMD::checkDeposit { {gui 1} } {
    global env
    set do 0
    set answer cancel
    set filename ".qwikmdrc"
    if {[string first "Windows" $::tcl_platform(os)] != -1} {
        set filename "qwikmd.rc"
    }
 
    set location ${env(HOME)}

    if {[file exists ${location}/${filename}] == 1} {
        source ${location}/${filename}
    }
    if {$gui ==1 && [info exists env(QWIKMDFOLDER)] == 0} {
        set answer [tk_messageBox -message "The library folder \"qwikmd\" and preferences file \"$filename\" were created in your home directory."\
         -title "QwikMD Library Folder" -icon info -type ok -parent $QWIKMD::topGui]
         set do 1

    } elseif {$gui ==1 && [info exists env(QWIKMDFOLDER)] == 1 && [file exists $env(QWIKMDFOLDER)] == 0} {
        tk_messageBox -message "QwikMD Library folder was deleted or moved. A new folder will be created." \
        -title "QwikMD Library Folder" -icon info -type ok -parent $QWIKMD::topGui
        file delete -force ${location}/${filename}
        unset env(QWIKMDFOLDER)
        QWIKMD::checkDeposit
    } elseif {$gui == 0 && ([info exists env(QWIKMDFOLDER)] == 0 || [file exists $env(QWIKMDFOLDER)] == 0)} {
        ### Return 1 (error) if trying to use this proc to load topologies uploaded to QwikMD
        ### from other tools, like Molefacture
        return 1
    }
    set folder "${::env(HOME)}/qwikmd"
    if {$do == 1} {
        if {[file exists ${folder}] == 0}  {
            file mkdir ${folder}
        }

        if {[file exists ${folder}/templates] == 0}  {
            file mkdir ${folder}/templates
            file mkdir ${folder}/templates/Explicit
            file mkdir ${folder}/templates/Implicit
            file mkdir ${folder}/templates/Vacuum
        }
            
        set templates [glob ${env(QWIKMDDIR)}/*.conf]
        foreach temp $templates {
            file copy -force ${temp} ${folder}/templates/
        }
        if {[file exists ${folder}/toppar] == 0}  {
            file mkdir ${folder}/toppar
        }
        
        set vmdrc [open ${location}/${filename} a]
        puts $vmdrc "set env(QWIKMDFOLDER) \"[file normalize ${folder}]\""
        set env(QWIKMDFOLDER) [file normalize ${folder}]
        close $vmdrc
    } else {
        ## Version compatibility to add QM/MM configuration file to the qwikmd lib folder
        if {[catch {glob ${folder}/templates/QMMM*.conf} qmfiles] == 1} {
            set QMtemplates [glob ${env(QWIKMDDIR)}/QMMM*.conf]
            foreach temp $QMtemplates {
                file copy -force ${temp} ${folder}/templates/
            }
        }
        ## Update old conf files with the new stepspercycle value
        set files {Minimization Annealing Equilibration MD SMD}
        foreach temp $files {
            set origfile ${folder}/templates/$temp.conf
            set conffile [open $origfile r]
            set stop 0
            set replace 0
            while {[eof $conffile] != 1 && $stop == 0} {
                set line [gets $conffile]
                set i 0
                foreach key $line {
                    if {$key == "\$Date:"} {
                        set date [lindex [split [lindex $line [expr $i + 1]] "/"] 0]
                        if {$date == 2016} {
                            set replace 1
                        }
                        set stop 1
                        break
                    }
                    incr i
                }
            }
            close $conffile
            if {$replace == 1} {
                if {[file exists ${folder}/backup] == 0}  {
                    file mkdir ${folder}/templates/backup
                }
                file copy -force $origfile ${folder}/templates/backup/${temp}_[clock format [clock seconds] -format {%m%d%Y}].conf
                file copy -force ${env(QWIKMDDIR)}/$temp.conf ${folder}/templates/
            }
            
        }
        
    }
    if {[file exists ${folder}/toppar/toppartable.txt] == 0} {
        set file [open ${folder}/toppar/toppartable.txt w+]
        QWIKMD::printTopParHeader $file
        close $file
    }
    if {[file exists ${folder}/toppar/pdbaliastable.txt] == 0} {
        QWIKMD::printDeafultPdbalias ${folder}/toppar/pdbaliastable.txt
    }
    ## Check if the QWIKMDTMPDIR folder exists
    if {[info exists env(QWIKMDTMPDIR)] == 1 && [file exists ${env(QWIKMDTMPDIR)}] == 1} {
        return 0
    }
    if {[file exists $env(TMPDIR)] == 1} {
        set env(QWIKMDTMPDIR) ${env(TMPDIR)}
    } else {
        set env(QWIKMDTMPDIR) ""
        switch [vmdinfo arch] {
            WIN64 -
            WIN32 {
                set env(QWIKMDTMPDIR) "c:/"
            }
            MACOSXX86_64 -
            MACOSXX86 -
            MACOSX {
                set env(QWIKMDTMPDIR) "/"
            }
            default {
                set env(QWIKMDTMPDIR) "/tmp"
            }
        }
    }
    if {[file exists ${env(QWIKMDTMPDIR)}] == 0} {
        set answer [tk_messageBox -message "There is no Temporary file defined. Do you want to define it now?" \
        -title "Temporary Folder" -icon warning -type yesno -parent $QWIKMD::topGui]
        QWIKMD::setTempFolder $answer
    }
    set testfile ""
    catch {open ${env(QWIKMDTMPDIR)}/test.log w+} testfile
    if {[file exists ${env(QWIKMDTMPDIR)}/test.log] == 0} {
        set answer [tk_messageBox -message "You don't have permission to write on the ${env(QWIKMDTMPDIR)} folder.\
         Do you want to define a new Temporary Folder?" -title "Temporary Folder" -icon error -type yesno -parent $QWIKMD::topGui]
         QWIKMD::setTempFolder $answer
    } else {
        close $testfile
        file delete -force -- ${env(QWIKMDTMPDIR)}/test.log
    }
    return 0
}
################################################################################
## Define a new Temp Dir for QwikMD
################################################################################
proc QWIKMD::setTempFolder {answer} {
    set printError 0
    if {$answer == "yes"} {
        set folder [tk_chooseDirectory -title "Temporary Folder"]
        if {$folder != ""} {
            set env(QWIKMDTMPDIR) ${folder}
            set vmdrc [open ${location}/${filename} a]
            puts $vmdrc "set env(QWIKMDTMPDIR) \"[file normalize ${folder}]\""
            close $vmdrc
        } else {
            set printError 1
        }
    } else {
        set printError 1
    }
    if {$printError == 1} {
        tk_messageBox -message "Temporary Folder not created. Please exit QwikMD." \
        -title "Temporary Folder" -icon error -type ok -parent $QWIKMD::topGui
    }  
}
proc QWIKMD::printTopParHeader {file} {
    puts $file [string repeat "#" 80]
    puts $file "## This file contains the definition of the user defined macros\
    added \n## through the \"Topology & Parameters Selection\".If edited manually, please\
    keep the file format."
    puts $file "## File Format"
    puts $file "## <Residue Name> <CHARMM Name> <MacroName> <Topology File Name>"
    puts $file "[string repeat "#" 80]\n"
}
####################################################################################
## Print the pdbalias matching what autopsf pdbalias list in the ::autopsf::psfaliases
## command. The list should be synchronized between QwikMD and autopsf
####################################################################################
proc QWIKMD::printDeafultPdbalias {outputfile} {
    ## list composed by the residues subject to pdbalias in autopsf
    set resRenames [list {G GUA} {C CYT} {A ADE} {T THY} {U URA} {Gr GUA} {Gd GUA}\
    {Cr CYT} {Cd CYT} {Ar ADE} {Ad ADE} {Ur URA} {Td THY} {DT THY} {DG GUA} {DC CYT}\
    {DA ADE} {HIS HSD} {BMA BMAN} {MAN AMAN} {FUC AFUC} {HEM HEME} {HOH TIP3} {K POT}\
    {ICL CLA} {INA SOD} {CA CAL} {ZN ZN2}]

    set atmRenames [list]
    foreach bp { GUA CYT ADE THY URA } {
        lappend atmRenames [list $bp "O5\\*" "O5'"]
        lappend atmRenames [list $bp "C5\\*" "C5'"]
        lappend atmRenames [list $bp "O4\\*" "O4'"]
        lappend atmRenames [list $bp "C4\\*" "C4'"]
        lappend atmRenames [list $bp "C3\\*" "C3'"]
        lappend atmRenames [list $bp "O3\\*" "O3'"]
        lappend atmRenames [list $bp "C2\\*" "C2'"]
        lappend atmRenames [list $bp "O2\\*" "O2'"]
        lappend atmRenames [list $bp "C1\\*" "C1'"]
        lappend atmRenames [list $bp "OP1" "O1P"]
        lappend atmRenames [list $bp "OP2" "O2P"]
    }
    set atmRenames [concat $atmRenames [list {ILE CD1 CD} {SER HG HG1} {HEME {N A} NA} {HEME {N B} NB}\
    {HEME {N C} NC} {HEME {N D} ND} {TIP3 O OH2} {POT K POT} {CLA CL CLA} {SOD NA SOD} {CAL CA CAL}\
    {LYS 1HZ HZ1} {LYS 2HZ HZ2} {LYS 3HZ HZ3} {ARG 1HH1 HH11} {ARG 2HH1 HH12} {ARG 1HH2 HH21}\
    {ARG 2HH2 HH22} {ASN 1HD2 HD21} {ASN 2HD2 HD22}]]

    set file [open $outputfile w+]
    puts $file [string repeat "#" 80]
    puts $file "## This file contains the definition of the pdb aliases (pdbalias) used\
    by autopsf to automatically\n## rename residues and atoms. If edited manually, please\
    keep the file format. IMPORTANT: Don't include the keyword pdbalias"
    puts $file "## File Format"
    puts $file "## residue <CurrentName> <ResidueName> or"
    puts $file "## atom <ResidueName> <CurrentAtomName> <NewAtomName>"
    puts $file "[string repeat "#" 80]\n"

    foreach res $resRenames {
        puts $file "residue $res"
    }
    puts $file "\n"
    foreach atom $atmRenames {
        puts $file "atom $atom"
    }
    close $file
}
####################################################################################
## Rename Residues and Atoms to match what autopsf does with the pdbalias
## ::autopsf::psfaliases. The list should be synchronized between QwikMD and autopsf
####################################################################################
proc QWIKMD::applyDeafultPdbalias {} {
    global env
    set aliasfile "$env(QWIKMDFOLDER)/toppar/pdbaliastable.txt"
    if {[file exists $aliasfile] != 1} {
        tk_messageBox -message "Missing $env(QWIKMDFOLDER)/toppar/pdbaliastable.txt file.\
        Please report this error." -type ok -title "Missing pdbalias" -parent $QWIKMD::topGui
        return
    }
    set file [open "$env(QWIKMDFOLDER)/toppar/pdbaliastable.txt" r]
    set temp [read -nonewline $file]
    close $file
    set temp [split $temp "\n"]
    ## Remove comments and empty lines
    set tempaux [list]
    foreach line $temp {
        set comp [string trim $line " "]
        if {[string length $comp] > 0 && [string index $comp 0] != "#"} {
            lappend tempaux $line 
        } 
    }
    set temp $tempaux
   
    set resRenames [list]
    array set atmRenames ""
    foreach line $temp {
        if {[lindex $line 0] == "residue"} {
            lappend resRenames [lrange $line 1 2]
        } elseif {[lindex $line 0] == "atom"} {
            if {[info exists atmRenames([lindex $line 1])] == 0} {
                set atmRenames([lindex $line 1]) [list]
            }
            lappend atmRenames([lindex $line 1]) [lrange $line 2 3]
        }
    }
    set message "QwikMD renamed the following elements to match the CHARMM36 topologies:\n"
    foreach resid $resRenames {
        set sel [atomselect $QWIKMD::topMol "resname [lindex $resid 0]"]
        if {[$sel num] > 0} {
            ## Collect the names of the residues and atoms to track 
            ## what was changed
            $sel set resname [lindex $resid 1]
            $sel delete
            lappend QWIKMD::autorenameLog $resid
            append message "residue name [lindex $resid 0] to [lindex $resid 1]\n"
            if {[info exists atmRenames([lindex $resid 1])] == 1} {
                foreach atom $atmRenames([lindex $resid 1]) {
                    set selatom [atomselect $QWIKMD::topMol "resname \"[lindex $resid 1]\" and name \"[lindex $atom 0]\""]
                    $selatom set name \"[lindex $atom 1]\"
                    lappend QWIKMD::autorenameLog [list [lindex $resid 1] [join $atom]]
                    append message "atom of the residue name [lindex $resid 1]: [lindex $atom 0] to [lindex $atom 1]\n"
                    $selatom delete
                }
            }
        }
    }
    if {[llength $QWIKMD::autorenameLog] > 0} {
        tk_messageBox -message $message -title "Automatic Residue & Atom Renaming" -icon info\
        -parent $QWIKMD::topGui
    }
}
##############################################
## Orient pulling and anchor residues to the Z-axis
## in case of SMD, otherwise just move to the origin
###############################################
proc QWIKMD::orientMol {structure} {
    set selall [atomselect $structure all]
    set selmove ""
    # set zaxis {0 0 -1}
    set center [measure center $selall]
    set move_dist [transoffset [vecsub {0 0 0} $center]]
    
    $selall move $move_dist
    if {$QWIKMD::membraneFrame != "" && [llength $QWIKMD::advGui(membrane,rotationMaxtrixList)] > 0} {
        $selall move [measure inverse $QWIKMD::advGui(membrane,rotationMaxtrix)]    
    }
    
    if {$QWIKMD::run == "SMD"} {
        set selanchor [atomselect $structure "$QWIKMD::anchorRessel"]
        set selpulling [atomselect $structure "$QWIKMD::pullingRessel"]
        set anchor [measure center $selanchor]
        set pulling [measure center $selpulling]
        
        ## This align the system in two steps: transvecinv rotates the vector
        ## to be along the x axis, and then transaxis rotates about the y axis to
        ## align your vector with z. 
        ## By Peter Freddolino (http://www.ks.uiuc.edu/Research/vmd/mailing_list/vmd-l/6725.html)
        set axis [vecsub $pulling $anchor]
        $selpulling delete
        $selanchor delete
        set M [transvecinv $axis] 
        $selall move $M 
        set M [transaxis y -90] 
        $selall move $M 

    } 
    $selall delete

}

proc QWIKMD::boxSize {structure dist} {

    set sel [atomselect $structure "all"]
    set minmax [measure minmax $sel]
    $sel delete
    set xsp [lindex [lindex $minmax 0] 0]
    set ysp [lindex [lindex $minmax 0] 1]
    set zsp [lindex [lindex $minmax 0] 2]

    set xep [lindex [lindex $minmax 1] 0]
    set yep [lindex [lindex $minmax 1] 1]
    set zep [lindex [lindex $minmax 1] 2]
    
    set xp [expr abs($xep - $xsp)]
    set yp [expr abs($yep - $ysp)]
    set zp [expr abs($zep - $zsp)]

    set xsb  ""
    set ysb  ""
    set zsb  ""

    set xeb  ""
    set yeb  ""
    set zeb  ""

    if {$QWIKMD::run != "SMD"} {
        set dp [expr sqrt($xp*$xp+$yp*$yp+$zp*$zp)]
        set box_length [expr $dp + 2*$dist]
    
        set xsb  [expr $xsp - ($box_length-$xp)/2]
        set ysb  [expr $ysp - ($box_length-$yp)/2]
        set zsb  [expr $zsp - ($box_length-$zp)/2]

        set xeb  [expr $xep + ($box_length-$xp)/2]
        set yeb  [expr $yep + ($box_length-$yp)/2]
        set zeb  [expr $zep + ($box_length-$zp)/2]
    } else {
        set dp [expr sqrt($xp*$xp+$yp*$yp)]
        set box_length [expr $dp + 2*$dist]

        set xsb  [expr $xsp - ($box_length-$xp)/2]
        set ysb  [expr $ysp - ($box_length-$yp)/2]
        set zsb  [expr $zsp - $dist]
  
        set xeb  [expr $xep + ($box_length-$xp)/2]
        set yeb  [expr $yep + ($box_length-$yp)/2]
        set zeb  [expr $zep + $dist + $QWIKMD::basicGui(plength)]
    } 
    

    set boxmin [list $xsb $ysb $zsb]
    set boxmax [list $xeb $yeb $zeb]

    set centerX [expr [expr $xsb + $xeb] /2]
    set centerY [expr [expr $ysb + $yeb] /2]
    set centerZ [expr [expr $zsb + $zeb] /2]

    set cB1 [expr abs($xeb - $xsb)]
    set cB2 [expr abs($yeb - $ysb)]
    set cB3 [expr abs($zeb - $zsb)]

    set center [list [format %.2f $centerX] [format %.2f $centerY] [format %.2f $centerZ]]
    set length [list [format %.2f $cB1] [format %.2f $cB2] [format %.2f $cB3]]
    set QWIKMD::cellDim [list $boxmin $boxmax $center $length]

    mol delete $structure
}


proc QWIKMD::rmsdAlignCalc {sel sel_ref frame} {
    set rmsd 0
    if {$QWIKMD::advGui(analyze,basic,alicheck) == 1} {
        set seltext ""
        if {$QWIKMD::advGui(analyze,basic,alientry) != "" && $QWIKMD::advGui(analyze,basic,alientry) != "Type Selection"} {
            set seltext $QWIKMD::advGui(analyze,basic,alientry)
        } else {
            set seltext $QWIKMD::advGui(analyze,basic,alicombo)
        }
        set alisel [atomselect $QWIKMD::topMol $seltext frame 0]
        set auxsel [atomselect $QWIKMD::topMol $seltext frame $frame]
        set tmatrix [measure fit $auxsel $alisel]
        $alisel delete
        $auxsel delete
        set move_sel [atomselect $QWIKMD::topMol "all" frame $frame]
        
        $move_sel move $tmatrix
        $move_sel delete
    } 
    
    return [measure rmsd $sel $sel_ref]
}

##############################################
## Like the hydrogen bonds calculation proc,
## the general proc (QWIKMD::RmsdCalc) calls the 
## calculator proc (QWIKMD::rmsdAlignCalc) so it is
## possible to call the same calculator proc in two
## instances with slight modifications
###############################################
proc QWIKMD::RmsdCalc {} {
    
    set top $QWIKMD::topMol
    set seltext ""
    if {$QWIKMD::advGui(analyze,basic,alientry) != "" && $QWIKMD::advGui(analyze,basic,alientry) != "Type Selection"} {
        set seltext $QWIKMD::advGui(analyze,basic,alientry)
    } else {
        set seltext $QWIKMD::advGui(analyze,basic,alicombo)
    }

    set sel_ref [atomselect $QWIKMD::topMol $seltext frame 0]
    if {[$sel_ref get index] != ""} {
        set sel [atomselect $top $seltext]
        set frame [molinfo $QWIKMD::topMol get frame]
        set const [expr $QWIKMD::timestep * 1e-6]
        if {$QWIKMD::run == "QM/MM"} {
            set const [expr $const * 1e3]
        }
        $sel frame $frame
        
        lappend QWIKMD::timeXrmsd [expr {$const * $QWIKMD::counterts * $QWIKMD::imdFreq} + $QWIKMD::rmsdprevx]
        lappend QWIKMD::rmsd [QWIKMD::rmsdAlignCalc $sel $sel_ref $frame]
        $QWIKMD::rmsdGui clear
        $QWIKMD::rmsdGui add $QWIKMD::timeXrmsd $QWIKMD::rmsd
        $QWIKMD::rmsdGui replot
        $sel delete
    } 
    $sel_ref delete
}

proc QWIKMD::calcSASA {globaltext restricttext probe samples} {
    
    
    array set residues ""
    set resLis [list]
    set frames [molinfo $QWIKMD::topMol get numframes]
    set residues(total) [list]
    for {set i 0} {$i < $frames} {incr i} {
        set global [atomselect $QWIKMD::topMol $globaltext frame $i]
        set restrict [atomselect $QWIKMD::topMol "\($globaltext\) and \($restricttext\)" frame $i]
        #$restrict frame $i
        set textprev "" 
        foreach resid [$restrict get resid] resname [$restrict get resname] chain [$restrict get chain] {
            set text "$resid $resname $chain"
            if {$text != $textprev} {
                if {[lsearch $resLis ${text}] == -1} {
                    lappend resLis ${text}
                }
                set selaux [atomselect $QWIKMD::topMol "resid \"$resid\" and resname $resname and chain \"$chain\" " frame $i]
                lappend residues(${text}) [measure sasa 1.4 $global -restrict $selaux -samples $samples]
            
                $selaux delete
            }
            set textprev $text
        }

        lappend residues(total) [measure sasa 1.4 $global -restrict $restrict -samples $samples]
        $restrict delete
        $global delete
    }

    # $global delete
    # $restrict delete

    return "{[array get residues]} {$resLis}"
}
#This proc is using a command that will still need to be improved (not in use)
proc QWIKMD::calcSASA2 {globaltext restricttext probe samples} {
    set global [atomselect top $globaltext]
    set restrict [atomselect top "\($globaltext\) and \($restricttext\)"]
    
    
    set textprev ""
    array set residues ""
    set resLis [list]
    set frames [molinfo $QWIKMD::topMol get numframes]
    set residues(total) [list]
    set selList [list]
    foreach resid [$restrict get resid] resname [$restrict get resname] chain [$restrict get chain] {
        set text "$resid $resname $chain"
        if {$text != $textprev} {
            
            lappend resLis ${text}
            
            lappend selList [atomselect $QWIKMD::topMol "resid \"$resid\" and resname $resname and chain \"$chain\" " frame 0]
            set textprev $text
        }
    }
    for {set i 0} {$i < $frames} {incr i} {
        $global frame $i
        $restrict frame $i
            
        foreach sel $selList {
            $sel frame $i
        }
        set val [measure sasalist 1.4 $selList -samples $samples]
        set j 0
        foreach sasa $val {
            lappend residues([lindex $resLis $j]) $sasa
            incr j
        }
        lappend residues(total) [measure sasa 1.4 $global -restrict $restrict -samples $samples]
    }

    $global delete
    $restrict delete
    return "{[array get residues]} {$resLis}"
}


proc QWIKMD::callSASA {} {

    set answer [tk_messageBox -title "SASA calculation" -message "This calculation may take a long time. Do you want to proceed?"\
     -type yesno -icon warning -parent $QWIKMD::topGui]
    if {$answer == "no"} {
        return
    }
    if {$QWIKMD::advGui(analyze,advance,sasaselentry) == "" || $QWIKMD::advGui(analyze,advance,sasaselentry) == "Type Selection"} {
        return
    }

    set restrict $QWIKMD::advGui(analyze,advance,sasarestselentry)
    if {$QWIKMD::advGui(analyze,advance,sasarestselentry) == "Type Selection" || $QWIKMD::advGui(analyze,advance,sasarestselentry) == ""} {
        set restrict $QWIKMD::advGui(analyze,advance,sasaselentry)
    }
    set const 2e-6
    set samples 50
    set probe 1.4
    set sasaResList [QWIKMD::calcSASA $QWIKMD::advGui(analyze,advance,sasaselentry) $restrict $probe $samples]
    array set residues [lindex $sasaResList 0]
    set reslist [lindex $sasaResList 1]
    unset sasaResList
    $QWIKMD::advGui(analyze,advance,sasatb) delete 0 end
    set selall [atomselect $QWIKMD::topMol "all"]
    $selall set user "0.00"
    $selall delete
    for {set i 0} {$i < [llength $reslist]} {incr i} {
        if {[lindex $reslist $i] != "total"} {
            set res [lindex $reslist $i]
            if {[llength $residues($res) ] > 1} {
                set avgstdv [QWIKMD::meanSTDV $residues($res)]
            } else {
                set avgstdv "$residues($res) 0.000"
            }
            $QWIKMD::advGui(analyze,advance,sasatb) insert end "$res [format %.3f [lindex $avgstdv 0]] [format %.3f [lindex $avgstdv 1]]"
            set sel [atomselect $QWIKMD::topMol "resid \"[lindex $res 0]\" and resname [lindex $res 1] and chain [lindex $res 2] "]
            $sel set user [lindex $avgstdv 0]
            $sel delete
            unset avgstdv
        }
    }
    #set resids [$QWIKMD::advGui(analyze,advance,sasatb) getcolumn 0]
    #set minres [QWIKMD::mincalc $resids]
    set total [llength $residues(total)]
    if {[molinfo $QWIKMD::topMol get numframes] > 1} {
        set avgstdv [QWIKMD::meanSTDV $residues(total)]
    } else {
        set avgstdv "$residues(total) 0.000"
    }
    
    set xsasa [list]
    set ysasa [list]
    set j 0
    set do 1
    set const 2e-6
    set increment [expr $const * [expr $QWIKMD::dcdfreq * $QWIKMD::loadstride] ]
    set xtime 0
    for {set i 0} {$i < $total} {incr i} {
        
        if {$i < [lindex $QWIKMD::lastframe $j]} {
            
            if {$do == 1} {
                set logfile [open [lindex $QWIKMD::confFile $j].log r]
                while {[eof $logfile] != 1 } {
                    set line [gets $logfile]

                    if {[lindex $line 0] == "Info:" && [lindex $line 1] == "TIMESTEP"} {
                        set const [expr [lindex $line 2] * 1e-6]
                        if {$QWIKMD::run == "QM/MM"} {
                            set const [expr $const * 1e3]
                        }
                    }

                    if {[lindex $line 0] == "Info:" && [join [lrange $line 1 2]] == "DCD FREQUENCY" } {
                        set QWIKMD::dcdfreq [lindex $line 3]
                        break
                    }
                }
                close $logfile
                set do 0
                set increment [expr $const * [expr $QWIKMD::dcdfreq * $QWIKMD::loadstride] ]
            }       
        } else {
            incr j
            set do 1
        }
        if {$i > 0}  {
            set xtime [expr [lindex $xsasa end] + $increment]
        }
        lappend xsasa $xtime
        lappend ysasa [lindex $residues(total) $i] 
    }
    if {$QWIKMD::SASAGui == ""} {
        set xlab "Time (ns)"
        if {$QWIKMD::run == "QM/MM"} {
            set xlab "Time (ps)"
        }
        set info [QWIKMD::addplot sasa "SASA Plot" "Total SASA vs Time" $xlab "SASA (A\u00b2)"]
        set QWIKMD::SASAGui [lindex $info 0]

        set clear [lindex $info 1]
        set close [lindex $info 2]
        
        $clear entryconfigure 0 -command {
            if {$QWIKMD::sasarep != ""} {
                mol delrep [QWIKMD::getrepnum $QWIKMD::sasarep $QWIKMD::topMol] $QWIKMD::topMol
                set QWIKMD::sasarep ""
            }
                $QWIKMD::SASAGui clear
                $QWIKMD::SASAGui add 0 0
                $QWIKMD::SASAGui replot
        }

        $close entryconfigure 0 -command {
            if {$QWIKMD::sasarep != ""} {
                mol delrep [QWIKMD::getrepnum $QWIKMD::sasarep $QWIKMD::topMol] $QWIKMD::topMol
                set QWIKMD::sasarep ""
                foreach m [molinfo list] {
                    if {[string compare [molinfo $m get name] "{Color Scale Bar}"] == 0} {
                      mol delete $m
                    }
                }
            }
            $QWIKMD::SASAGui quit
            destroy $QWIKMD::advGui(analyze,advance,ntb).sasa
            set QWIKMD::SASAGui ""
        }
        if {[file channels $QWIKMD::textLogfile] == $QWIKMD::textLogfile && $QWIKMD::textLogfile != ""} {
            puts $QWIKMD::textLogfile [QWIKMD::printSASA [lindex $xsasa end] [llength $xsasa] $QWIKMD::advGui(analyze,advance,sasaselentry) $restrict]
            flush $QWIKMD::textLogfile
        }
        
    } else {
        $QWIKMD::SASAGui clear
        $QWIKMD::SASAGui add 0 0
        $QWIKMD::SASAGui replot
    }   
    $QWIKMD::SASAGui clear
    $QWIKMD::SASAGui add $xsasa $ysasa
    $QWIKMD::SASAGui replot
    if {$QWIKMD::sasarep == ""} {
        mol addrep $QWIKMD::topMol
        set val [$QWIKMD::advGui(analyze,advance,sasatb) getcolumns 3]
        set min [QWIKMD::mincalc $val]
        set max [QWIKMD::maxcalc $val]
        set QWIKMD::sasarep [mol repname $QWIKMD::topMol [expr [molinfo $QWIKMD::topMol get numreps] -1] ]
        set repnum [QWIKMD::getrepnum $QWIKMD::sasarep $QWIKMD::topMol]
        mol modcolor $repnum $QWIKMD::topMol "User"
        mol modselect $repnum $QWIKMD::topMol "\($QWIKMD::advGui(analyze,advance,sasaselentry)\) and \($restrict\)"
        mol selupdate $repnum $QWIKMD::topMol on
        set rep $QWIKMD::advGui(analyze,advance,sasarep)
        mol modstyle $repnum $QWIKMD::topMol $rep
        QWIKMD::RenderChgResolution
        if {$min == ""} {
            set min 0
        }
        if {$max == ""} {
            set max 0
        }
        ::ColorScaleBar::color_scale_bar 0.8 0.05 0 1 [expr round($min)] [expr round($max)] 5 white 0 -1.0 0.8 1 $QWIKMD::topMol 0 1 "SASA"
        color scale method BWR
    }
    $QWIKMD::advGui(analyze,advance,sasatb) insert end "#S Total Total [format %.3f [lindex $avgstdv 0]] [format %.3f [lindex $avgstdv 1]]"
    $QWIKMD::advGui(analyze,advance,sasatb) sortbycolumn 0
}

proc QWIKMD::callCSASA {} {
    set answer [tk_messageBox -title "Cont. Surface Area calculation" -message "This calculation may take a long time. Do you want to proceed?" \
    -type yesno -icon warning -parent $QWIKMD::topGui]
    if {$answer == "no"} {
        return
    }
    if {$QWIKMD::advGui(analyze,advance,sasaselentry) == "" || $QWIKMD::advGui(analyze,advance,sasaselentry) == "Type Selection"} {
        return
    }

    if {$QWIKMD::advGui(analyze,advance,sasarestselentry) == "" || $QWIKMD::advGui(analyze,advance,sasarestselentry) == "Type Selection" || $QWIKMD::advGui(analyze,advance,sasarestselentry) == $QWIKMD::advGui(analyze,advance,sasaselentry)} {
        return
    }

    if {$QWIKMD::CSASAGui == ""} {
        if {$QWIKMD::sasarep != ""} {
            mol delrep [QWIKMD::getrepnum $QWIKMD::sasarep $QWIKMD::topMol] $QWIKMD::topMol
            set QWIKMD::sasarep ""
        }
        set xlab "Time (ns)"
        if {$QWIKMD::run == "QM/MM"} {
            set xlab "Time (ps)"
        }
        set info [QWIKMD::addplot csasa "Cont Area Plot" "Total Contact Area vs Time" $xlab "Surface Area (A\u00b2)"]
        set QWIKMD::CSASAGui [lindex $info 0]

        set clear [lindex $info 1]
        set close [lindex $info 2]
        
        $clear entryconfigure 0 -command {
            if {$QWIKMD::sasarep != ""} {
                mol delrep [QWIKMD::getrepnum $QWIKMD::sasarep $QWIKMD::topMol] $QWIKMD::topMol
                set QWIKMD::sasarep ""
            }
            $QWIKMD::CSASAGui clear
            $QWIKMD::CSASAGui add 0 0
            $QWIKMD::CSASAGui replot
        }

        $close entryconfigure 0 -command {
            if {$QWIKMD::sasarep != ""} {
                mol delrep [QWIKMD::getrepnum $QWIKMD::sasarep $QWIKMD::topMol] $QWIKMD::topMol
                set QWIKMD::sasarep ""
                foreach m [molinfo list] {
                    if {[string compare [molinfo $m get name] "{Color Scale Bar}"] == 0} {
                      mol delete $m
                    }
                }
            }
            $QWIKMD::CSASAGui quit
            destroy $QWIKMD::advGui(analyze,advance,ntb).csasa
            set QWIKMD::CSASAGui ""
        }

    } else {
        $QWIKMD::CSASAGui clear
        $QWIKMD::CSASAGui add 0 0
        $QWIKMD::CSASAGui replot
    } 

    set restrict $QWIKMD::advGui(analyze,advance,sasarestselentry)
    if {$QWIKMD::advGui(analyze,advance,sasarestselentry) == "Type Selection"} {
        set restrict $QWIKMD::advGui(analyze,advance,sasaselentry)
    }

    set const 2e-6
    set samples 50
    set probe 1.4
    array set residues1 ""
    array set residues2 ""
    set reslist ""
    set totABAVG0 [list]
    set totAB0 [list]
    set totABAVG1 [list]
    set totAB1 [list]
    $QWIKMD::advGui(analyze,advance,sasatb) delete 0 end
    set all [atomselect $QWIKMD::topMol "all"]
    $all set user 0.000
    $all delete
    set numframe [molinfo $QWIKMD::topMol get numframes]
    for {set j 0} {$j < 2} {incr j} {
        if {$j == 0} {

            set globalsel "\($QWIKMD::advGui(analyze,advance,sasaselentry)\) or \($QWIKMD::advGui(analyze,advance,sasarestselentry)\)"
            set restrictsel "\(within 5 of \($QWIKMD::advGui(analyze,advance,sasarestselentry)\)\) and \($QWIKMD::advGui(analyze,advance,sasaselentry)\)"

            set sasaResList [QWIKMD::calcSASA $globalsel $restrictsel $probe $samples]
            array set residues1 [lindex $sasaResList 0]
            set globalsel "\($QWIKMD::advGui(analyze,advance,sasaselentry)\)"

            set sasaResList [QWIKMD::calcSASA $globalsel $restrictsel $probe $samples]
            array set residues2 [lindex $sasaResList 0]
            set reslist [lindex $sasaResList 1]
        } else {
            set globalsel "\($QWIKMD::advGui(analyze,advance,sasaselentry)\) or \($QWIKMD::advGui(analyze,advance,sasarestselentry)\)"
            set restrictsel "\(within 5 of \($QWIKMD::advGui(analyze,advance,sasaselentry)\)\) and \($QWIKMD::advGui(analyze,advance,sasarestselentry)\)"
            
            set sasaResList [QWIKMD::calcSASA $globalsel $restrictsel $probe $samples]
            array set residues1 [lindex $sasaResList 0]
            set globalsel "\($QWIKMD::advGui(analyze,advance,sasarestselentry)\)"
            set sasaResList [QWIKMD::calcSASA $globalsel $restrictsel $probe $samples]
            array set residues2 [lindex $sasaResList 0]
            set reslist [lindex $sasaResList 1]
        }
        lappend reslist "total"     

        for {set i 0} {$i < [llength $reslist]} {incr i} {
            
                set res [lindex $reslist $i]
                set length [llength $residues1($res)]
                set diff [list]
                for {set index 0} {$index < $length} {incr index} {
                    lappend diff [expr abs([lindex $residues1($res) $index] - [lindex $residues2($res) $index]) ]
                }
                while {[llength $diff] < $numframe} {
                    lappend diff 0.00
                }
                
                if {[llength $diff] > 1} {
                    set avgstdv [QWIKMD::meanSTDV $diff]
                } else {
                    set avgstdv [list $diff 0.0]
                }
                
                if {$res != "total"} {
                    $QWIKMD::advGui(analyze,advance,sasatb) insert end "$res [format %.3f [lindex $avgstdv 0] ] [format %.3f [lindex $avgstdv 1]]"
                    set sel [atomselect $QWIKMD::topMol "resid \"[lindex $res 0]\" and resname [lindex $res 1] and chain [lindex $res 2] "]
                    $sel set user [lindex $avgstdv 0]
                    $sel delete
                } else {
                    set totABAVG$j [list [format %.3f [lindex $avgstdv 0]] [format %.3f [lindex $avgstdv 1]] ]
                    set totAB$j $diff       
                }           
                set avgstdv ""
        }       
        set sasaResList ""
        
    }
    #set resids [$QWIKMD::advGui(analyze,advance,sasatb) getcolumn 0]
    #set minres [QWIKMD::mincalc $resids]
    set total [llength $residues1(total)]
    set xsasa [list]
    set j 0
    set const 2e-6
    set do 1
    set increment [expr $const * [expr $QWIKMD::dcdfreq * $QWIKMD::loadstride] ]
    set xtime 0
    for {set i 0} {$i < $total} {incr i} {
        if {$i < [lindex $QWIKMD::lastframe $j]} {
                    
            if {$do == 1} {
                set logfile [open [lindex $QWIKMD::confFile $j].log r]
                while {[eof $logfile] != 1 } {
                    set line [gets $logfile]

                    if {[lindex $line 0] == "Info:" && [lindex $line 1] == "TIMESTEP"} {
                        set const [expr [lindex $line 2] * 1e-6]
                        if {$QWIKMD::run == "QM/MM"} {
                            set const [expr $const * 1e3]
                        }
                    }

                    if {[lindex $line 0] == "Info:" && [join [lrange $line 1 2]] == "DCD FREQUENCY" } {
                        set QWIKMD::dcdfreq [lindex $line 3]
                        break
                    }
                }
                close $logfile
                set do 0
                set increment [expr $const * [expr $QWIKMD::dcdfreq * $QWIKMD::loadstride] ]
            }       
        } else {
            incr j
            set do 1
        }
        if {$i > 0}  {
            set xtime [expr [lindex $xsasa end] + $increment]
        }
        lappend xsasa $xtime
    }
    $QWIKMD::CSASAGui clear
    $QWIKMD::CSASAGui add $xsasa $totAB0 -legend "Total1_2"
    $QWIKMD::CSASAGui add $xsasa $totAB1 -legend "Total2_1"
    $QWIKMD::CSASAGui replot
    if {$QWIKMD::sasarep == ""} {
        if {[file channels $QWIKMD::textLogfile] == $QWIKMD::textLogfile && $QWIKMD::textLogfile != ""} {
            puts $QWIKMD::textLogfile [QWIKMD::printContSASA [lindex $xsasa end] [llength $xsasa] $QWIKMD::advGui(analyze,advance,sasaselentry) $QWIKMD::advGui(analyze,advance,sasarestselentry)  ]    
            flush $QWIKMD::textLogfile
        }

        mol addrep $QWIKMD::topMol
        set val [$QWIKMD::advGui(analyze,advance,sasatb) getcolumns 3]
        set min [QWIKMD::mincalc $val]
        set max [QWIKMD::maxcalc $val]
        set QWIKMD::sasarep [mol repname $QWIKMD::topMol [expr [molinfo $QWIKMD::topMol get numreps] -1] ]
        set repnum [QWIKMD::getrepnum $QWIKMD::sasarep $QWIKMD::topMol]
        mol modcolor $repnum $QWIKMD::topMol "User"
        
        set seltext "same residue as \(\(\(within 5 of \($QWIKMD::advGui(analyze,advance,sasaselentry)\)\) and \($QWIKMD::advGui(analyze,advance,sasarestselentry)\)\) or \(\(within 5 of \($QWIKMD::advGui(analyze,advance,sasarestselentry)\)\) and \($QWIKMD::advGui(analyze,advance,sasaselentry)\)\)\)"
        mol modselect $repnum $QWIKMD::topMol $seltext
        mol selupdate $repnum $QWIKMD::topMol on
        set rep $QWIKMD::advGui(analyze,advance,sasarep)
        mol modstyle $repnum $QWIKMD::topMol $QWIKMD::advGui(analyze,advance,sasarep)
        QWIKMD::RenderChgResolution
        set color "white"
        if {$QWIKMD::basicGui(desktop) == "white"} {
            set color "black"
        }
        if {$min == ""} {
            set min 0
        }
        if {$max == ""} {
            set max 0
        }
        ::ColorScaleBar::color_scale_bar 0.8 0.05 0 1 [expr round($min)] [expr round($max)] 5 $color 0 -1.0 0.8 1 $QWIKMD::topMol 0 1 "Cont Area"
        color scale method BWR
    }
    $QWIKMD::advGui(analyze,advance,sasatb) insert end "#S1 Total1_2 Total1_2 [format %.3f [lindex $totABAVG0 0 ]] [format %.3f [lindex  $totABAVG0  1]]"

    $QWIKMD::advGui(analyze,advance,sasatb) insert end "#S2 Total2_1 Total2_1 [format %.3f [lindex $totABAVG1 0]] [format %.3f [lindex $totABAVG1  1]]"
    $QWIKMD::advGui(analyze,advance,sasatb) sortbycolumn 0
}

proc QWIKMD::RMSFCalc {} {
    if {$QWIKMD::rmsfGui == ""} {
        set info [QWIKMD::addplot rmsf "RMSF Plot" "RMSF vs Residue Number" "Residue Number" "RMSF (A)"]
        set QWIKMD::rmsfGui [lindex $info 0]

        set clear [lindex $info 1]
        set close [lindex $info 2]
        
        $clear entryconfigure 0 -command {
            if {$QWIKMD::rmsfrep != ""} {
            mol delrep [QWIKMD::getrepnum $QWIKMD::rmsfrep $QWIKMD::topMol] $QWIKMD::topMol
            set QWIKMD::rmsfrep ""
        }
            $QWIKMD::rmsfGui clear
            $QWIKMD::rmsfGui add 0 0
            $QWIKMD::rmsfGui replot
        }

        $close entryconfigure 0 -command {
            if {$QWIKMD::rmsfrep != ""} {
                mol delrep [QWIKMD::getrepnum $QWIKMD::rmsfrep $QWIKMD::topMol] $QWIKMD::topMol
                set QWIKMD::rmsfrep ""
                foreach m [molinfo list] {
                    if {[string compare [molinfo $m get name] "{Color Scale Bar}"] == 0} {
                      mol delete $m
                    }
                }
            }
            $QWIKMD::rmsfGui quit
            destroy $QWIKMD::advGui(analyze,advance,ntb).rmsf
            set QWIKMD::rmsfGui ""
        }

    } else {
        $QWIKMD::rmsfGui clear
        $QWIKMD::rmsfGui add 0 0
        $QWIKMD::rmsfGui replot
    } 

    if {$QWIKMD::load == 1 && $QWIKMD::advGui(analyze,advance,rmsfselentry) != "Type Selection"} {
        set xresid ""
        set rmsf ""
        set numframes [expr {$QWIKMD::advGui(analyze,advance,rmsfto) - $QWIKMD::advGui(analyze,advance,rmsffrom)} / $QWIKMD::advGui(analyze,advance,rmsfskip)]
        set all [atomselect $QWIKMD::topMol "all"]
        $all set user 0.000
        $all delete
        if {$numframes >= 1} {
            set sel [atomselect $QWIKMD::topMol $QWIKMD::advGui(analyze,advance,rmsfselentry)]
            if {$QWIKMD::advGui(analyze,advance,rmsfalicheck) == 1} {
                set numframesaux [molinfo $QWIKMD::topMol get numframes]
                set alignsel ""
                if {$QWIKMD::advGui(analyze,advance,rmsfalignsel) != "" && $QWIKMD::advGui(analyze,advance,rmsfalignsel) != "Type Selection"} {
                    set alignsel $QWIKMD::advGui(analyze,advance,rmsfalignsel)
                } else {
                    set alignsel $QWIKMD::advGui(analyze,advance,rmsfaligncomb)
                }
                set alisel [atomselect $QWIKMD::topMol $alignsel frame $QWIKMD::advGui(analyze,advance,rmsffrom)]
                set move_sel [atomselect $QWIKMD::topMol "all" frame 0]
                
                for {set i 0} {$i < $numframesaux} {incr i} {
                    $move_sel frame $i
                    set auxsel [atomselect $QWIKMD::topMol $alignsel frame $i]
                    set tmatrix [measure fit $auxsel $alisel]
                    $move_sel move $tmatrix
                    $auxsel delete
                }
                $move_sel delete
                $alisel delete
            }
            $sel set user 0.0
            set rmsflist [measure rmsf $sel first $QWIKMD::advGui(analyze,advance,rmsffrom) last $QWIKMD::advGui(analyze,advance,rmsfto) step $QWIKMD::advGui(analyze,advance,rmsfskip)]
            $sel set user $rmsflist

            set straux ""
            set resindex 1
            set min 100
            set max 0
            foreach resid [$sel get resid] chain [$sel get chain] {
                set str ${resid}_${chain}
                if {$str != $straux} {
                    set selcalc [atomselect $QWIKMD::topMol  "resid \"$resid\" and chain \"$chain\""]
                    lappend xresid $resindex
                    set values [$selcalc get user]
                    lappend rmsf [QWIKMD::mean $values]
                    set minaux [QWIKMD::mincalc $values]
                    if {$minaux < $min} {
                        set min $minaux
                    }
                    set maxaux [QWIKMD::maxcalc $values]
                    if {$maxaux > $max} {
                        set max $maxaux
                    }
                    $selcalc delete
                    set straux $str
                    incr resindex
                }
            }
            $sel delete
        }
        $QWIKMD::rmsfGui clear
        $QWIKMD::rmsfGui configure -nolines -raius 5 
        $QWIKMD::rmsfGui add $xresid $rmsf
        $QWIKMD::rmsfGui replot
        if {$QWIKMD::rmsfrep == ""} {
            if {[file channels $QWIKMD::textLogfile] == $QWIKMD::textLogfile && $QWIKMD::textLogfile != ""} {
                puts $QWIKMD::textLogfile [QWIKMD::printRMSF $QWIKMD::advGui(analyze,advance,rmsffrom) $QWIKMD::advGui(analyze,advance,rmsfto) $QWIKMD::advGui(analyze,advance,rmsfskip) $QWIKMD::advGui(analyze,advance,rmsfselentry) ]
                flush $QWIKMD::textLogfile
            }
            mol addrep $QWIKMD::topMol
            set QWIKMD::rmsfrep [mol repname $QWIKMD::topMol [expr [molinfo $QWIKMD::topMol get numreps] -1] ]
            set repnum [QWIKMD::getrepnum $QWIKMD::rmsfrep $QWIKMD::topMol]
            mol modcolor $repnum $QWIKMD::topMol "User"
            mol modselect $repnum $QWIKMD::topMol $QWIKMD::advGui(analyze,advance,rmsfselentry)
            set rep $QWIKMD::advGui(analyze,advance,rmsfrep)
            mol modstyle $repnum $QWIKMD::topMol $rep
            QWIKMD::RenderChgResolution 
            if {$min == ""} {
                set min 0
            }
            if {$max == ""} {
                set max 0
            }
            ::ColorScaleBar::color_scale_bar 0.8 0.05 0 1 [expr round($min)] [expr round($max)] 5 white 0 -1.0 0.8 1 $QWIKMD::topMol 0 1 "RMSF"
            color scale method BWR
        }
    }
}
proc QWIKMD::EneCalc {} {
    set do 1
    set const [expr $QWIKMD::timestep * 1e-6]
    if {$QWIKMD::run == "QM/MM"} {
        set const [expr $const * 1e3]
    }
    set tot 0
    set kin 0
    set elect 0
    set pot 0
    set bond 0
    set angle 0
    set dihedral 0
    set vdw 0
    if {$QWIKMD::energyTotGui != ""} {set tot 1}
    if {$QWIKMD::energyPotGui != ""} {set pot 1}
    if {$QWIKMD::energyElectGui != ""} {set elect 1}
    if {$QWIKMD::energyKineGui != ""} {set kin 1}
    if {$QWIKMD::energyBondGui != ""} {set bond 1}
    if {$QWIKMD::energyAngleGui != ""} {set angle 1}
    if {$QWIKMD::energyDehidralGui != "" } {set dihedral 1}
    if {$QWIKMD::energyVdwGui != ""} {set vdw 1}
    set xtime [QWIKMD::format4Dec  [expr {$const * $QWIKMD::counterts * $QWIKMD::imdFreq} + $QWIKMD::eneprevx]]
    if {$tot == 1} {
        $QWIKMD::energyTotGui clear
    
        lappend QWIKMD::enetotval [molinfo $QWIKMD::topMol get energy]
        lappend QWIKMD::enetotpos $xtime
        $QWIKMD::energyTotGui add $QWIKMD::enetotpos $QWIKMD::enetotval
        if {[lindex $QWIKMD::enetotval 0] == [lindex $QWIKMD::enetotval 1] && [lindex $QWIKMD::enetotval 1] == [lindex $QWIKMD::enetotval end]} {
            $QWIKMD::energyTotGui configure -ymin [expr [lindex $QWIKMD::enetotval 1] -1] -ymax [expr [lindex $QWIKMD::enetotval 1] +1] -xmin auto -xmax auto
        } else {
            $QWIKMD::energyTotGui configure -ymin auto -ymax auto -xmin auto -xmax auto
        }
        $QWIKMD::energyTotGui replot
    
    }

    if {$kin == 1} {
        $QWIKMD::energyKineGui clear
        lappend QWIKMD::enekinval [molinfo $QWIKMD::topMol get kinetic]
        lappend QWIKMD::enekinpos $xtime
        $QWIKMD::energyKineGui add $QWIKMD::enekinpos $QWIKMD::enekinval
        if {[lindex $QWIKMD::enekinval 0] == [lindex $QWIKMD::enekinval 1] && [lindex $QWIKMD::enekinval 1] == [lindex $QWIKMD::enekinval end]} {
            $QWIKMD::energyKineGui configure -ymin [expr [lindex $QWIKMD::enekinval 1] -1] -ymax [expr [lindex $QWIKMD::enekinval 1] +1] -xmin auto -xmax auto
        } else {
            $QWIKMD::energyKineGui configure -ymin auto -ymax auto -xmin auto -xmax auto
        }
        $QWIKMD::energyKineGui replot
    }

    if {$elect == 1} {
        $QWIKMD::energyElectGui clear
        lappend QWIKMD::eneelectval [molinfo $QWIKMD::topMol get electrostatic]
        lappend QWIKMD::eneelectpos $xtime
        $QWIKMD::energyElectGui add $QWIKMD::eneelectpos $QWIKMD::eneelectval
        if {[lindex $QWIKMD::eneelectval 0] == [lindex $QWIKMD::eneelectval 1] && [lindex $QWIKMD::eneelectval 1] == [lindex $QWIKMD::eneelectval end]} {
            $QWIKMD::energyElectGui configure -ymin [expr [lindex $QWIKMD::eneelectval 1] -1] -ymax [expr [lindex $QWIKMD::eneelectval 1] +1] -xmin auto -xmax auto
        } else {
            $QWIKMD::energyElectGui configure -ymin auto -ymax auto -xmin auto -xmax auto
        }
        $QWIKMD::energyElectGui replot
    }

    if {$pot == 1} {
        $QWIKMD::energyPotGui clear
        lappend QWIKMD::enepotval [molinfo $QWIKMD::topMol get potential]
        lappend QWIKMD::enepotpos $xtime
        $QWIKMD::energyPotGui add $QWIKMD::enepotpos $QWIKMD::enepotval
        if {[lindex $QWIKMD::enepotval 0] == [lindex $QWIKMD::enepotval 1] && [lindex $QWIKMD::enepotval 1] == [lindex $QWIKMD::enepotval end]} {
            $QWIKMD::energyPotGui configure -ymin [expr [lindex $QWIKMD::enepotval 1] -1] -ymax [expr [lindex $QWIKMD::enepotval 1] +1] -xmin auto -xmax auto
        } else {
            $QWIKMD::energyPotGui configure -ymin auto -ymax auto -xmin auto -xmax auto
        }
        $QWIKMD::energyPotGui replot
    }


    if {$bond == 1} {
        $QWIKMD::energyBondGui clear
    
        lappend QWIKMD::enebondval [molinfo $QWIKMD::topMol get bond]
        lappend QWIKMD::enebondpos $xtime
        $QWIKMD::energyBondGui add $QWIKMD::enebondpos $QWIKMD::enebondval
        if {[lindex $QWIKMD::enebondval 0] == [lindex $QWIKMD::enebondval 1] && [lindex $QWIKMD::enebondval 1] == [lindex $QWIKMD::enebondval end]} {
            $QWIKMD::energyBondGui configure -ymin [expr [lindex $QWIKMD::enebondval 1] -1] -ymax [expr [lindex $QWIKMD::enebondval 1] +1] -xmin auto -xmax auto
        } else {
            $QWIKMD::energyBondGui configure -ymin auto -ymax auto -xmin auto -xmax auto
        }
        $QWIKMD::energyBondGui replot
    
    }

    if {$angle == 1} {
        $QWIKMD::energyAngleGui clear
        lappend QWIKMD::eneangleval [molinfo $QWIKMD::topMol get angle]
        lappend QWIKMD::eneanglepos $xtime
        $QWIKMD::energyAngleGui add $QWIKMD::eneanglepos $QWIKMD::eneangleval
        if {[lindex $QWIKMD::eneangleval 0] == [lindex $QWIKMD::eneangleval 1] && [lindex $QWIKMD::eneangleval 1] == [lindex $QWIKMD::eneangleval end]} {
            $QWIKMD::energyAngleGui configure -ymin [expr [lindex $QWIKMD::eneangleval 1] -1] -ymax [expr [lindex $QWIKMD::eneangleval 1] +1] -xmin auto -xmax auto
        } else {
            $QWIKMD::energyAngleGui configure -ymin auto -ymax auto -xmin auto -xmax auto
        }
        $QWIKMD::energyAngleGui replot
    }

    if {$dihedral == 1} {
        $QWIKMD::energyDehidralGui clear
        lappend QWIKMD::enedihedralval [molinfo $QWIKMD::topMol get dihedral]
        lappend QWIKMD::enedihedralpos $xtime
        $QWIKMD::energyDehidralGui add $QWIKMD::enedihedralpos $QWIKMD::enedihedralval 
        if {[lindex $QWIKMD::enedihedralval 0] == [lindex $QWIKMD::enedihedralval 1] && [lindex $QWIKMD::enedihedralval 1] == [lindex $QWIKMD::enedihedralval end]} {
            $QWIKMD::energyDehidralGui configure -ymin [expr [lindex $QWIKMD::enedihedralval 1] -1] -ymax [expr [lindex $QWIKMD::enedihedralval 1] +1] -xmin auto -xmax auto
        } else {
            $QWIKMD::energyDehidralGui configure -ymin auto -ymax auto -xmin auto -xmax auto
        }
        $QWIKMD::energyDehidralGui replot
    }

    if {$vdw == 1} {
        $QWIKMD::energyVdwGui clear
        lappend QWIKMD::enevdwval [molinfo $QWIKMD::topMol get vdw]
        lappend QWIKMD::enevdwpos $xtime
        $QWIKMD::energyVdwGui add $QWIKMD::enevdwpos $QWIKMD::enevdwval
        if {[lindex $QWIKMD::enevdwval 0] == [lindex $QWIKMD::enevdwval 1] && [lindex $QWIKMD::enevdwval 1] == [lindex $QWIKMD::enevdwval end]} {
            $QWIKMD::energyVdwGui configure -ymin [expr [lindex $QWIKMD::enevdwval 1] -1] -ymax [expr [lindex $QWIKMD::enevdwval 1] +1] -xmin auto -xmax auto
        } else {
            $QWIKMD::energyVdwGui configure -ymin auto -ymax auto -xmin auto -xmax auto
        }
        $QWIKMD::energyVdwGui replot
    }
    
}

proc QWIKMD::CondCalc {} {
    set do 1
    set const [expr $QWIKMD::timestep * 1e-6]
    if {$QWIKMD::run == "QM/MM"} {
        set const [expr $const * 1e3]
    }   
    set tempaux 0
    set pressaux 0
    set volaux 0
    
    if {$QWIKMD::tempGui != ""} {set tempaux 1}
    if {$QWIKMD::pressGui != ""} {set pressaux 1}
    if {$QWIKMD::volGui != ""} {set volaux 1}
    set xtime [QWIKMD::format4Dec [expr {$const * $QWIKMD::counterts * $QWIKMD::imdFreq} + $QWIKMD::condprevx]]
    if {$tempaux ==1} {
        $QWIKMD::tempGui clear
            
        lappend QWIKMD::tempval [molinfo $QWIKMD::topMol get temperature]
        lappend QWIKMD::temppos $xtime

        $QWIKMD::tempGui add $QWIKMD::temppos $QWIKMD::tempval
        if {[lindex $QWIKMD::tempval 0] == [lindex $QWIKMD::tempval 1] && [lindex $QWIKMD::tempval 1] == [lindex $QWIKMD::tempval end]} {
            $QWIKMD::tempGui configure -ymin [expr [lindex $QWIKMD::tempval 1] -1] -ymax [expr [lindex $QWIKMD::tempval 1] +1] -xmin auto -xmax auto
        } else {
            $QWIKMD::tempGui configure -ymin auto -ymax auto -xmin auto -xmax auto
        }
        $QWIKMD::tempGui replot
        
    }

    if {$pressaux ==1 || $volaux == 1} {
        
        set index [expr $QWIKMD::state -1 ]
        set file "[lindex $QWIKMD::confFile $index].log"
        set prefix ""               
        set timeX "0"
        set const [expr $QWIKMD::timestep * 1e-6]
        set logfile [open $file r]
        seek $logfile $QWIKMD::condcurrentpos
        set dist ""
        set time ""
        set limit [expr $QWIKMD::calcfreq * $QWIKMD::imdFreq]
        set prevts [expr {[expr $QWIKMD::counterts -$QWIKMD::prevcounterts] * $QWIKMD::imdFreq}]
        if {$prevts < 0} {
            set prevts 0
        }
        while {[eof $logfile] != 1 } {
            set line [gets $logfile]
             
            if {[lindex $line 0] == "ENERGY:" && [lindex $line 1] != 0 && [lindex $line 1] < $prevts && $prevts != 0} {
                set line [gets $logfile]
            }
            if {[lindex $line 0] == "ENERGY:" && [lindex $line 1] != 0 && [lindex $line 1] > $QWIKMD::condprevindex} {
                if {$pressaux ==1} {
                    lappend  QWIKMD::pressval [lindex $line 19]
                }
                if {$volaux ==1} {
                    lappend  QWIKMD::volval [lindex $line 18]
                }
                
                set time [lindex $line 1]
                if {[expr $time - $QWIKMD::condprevindex] >= $limit} {
                    set xtime [QWIKMD::format4Dec  [expr {$const * $time} + $QWIKMD::condprevx]]
                    set min 0
                    set QWIKMD::condprevindex $time
                    set QWIKMD::condcurrentpos [tell $logfile ]
                    close $logfile
                    if {$pressaux == 1} {
                        $QWIKMD::pressGui clear
                        if {[llength $QWIKMD::pressvalavg] > 1} {
                            set min [expr int([expr [llength $QWIKMD::pressval] - [expr 1.5 * $QWIKMD::imdFreq] -1])]  
                        }
                        set max [expr [llength $QWIKMD::pressval] -1]
                        lappend QWIKMD::pressvalavg [QWIKMD::mean [lrange $QWIKMD::pressval $min $max]]
                        lappend QWIKMD::presspos $xtime
                        $QWIKMD::pressGui add $QWIKMD::presspos $QWIKMD::pressvalavg
                        if {[llength $QWIKMD::pressvalavg] >= 2} {
                            if {[lindex $QWIKMD::pressvalavg 0] == [lindex $QWIKMD::pressvalavg 1] && [lindex $QWIKMD::pressvalavg 1] == [lindex $QWIKMD::pressvalavg end]} {
                                $QWIKMD::pressGui configure -ymin [expr [lindex $QWIKMD::pressvalavg 1] -1] -ymax [expr [lindex $QWIKMD::pressvalavg 1] +1] -xmin auto -xmax auto
                            } else {
                                $QWIKMD::pressGui configure -ymin auto -ymax auto -xmin auto -xmax auto
                            }
                        } else {
                            $QWIKMD::pressGui configure -ymin auto -ymax auto -xmin auto -xmax auto
                        }
                        
                        $QWIKMD::pressGui replot
                    }
                    set min 0
                    if {$volaux == 1} {
                        $QWIKMD::volGui clear
                        if {[llength $QWIKMD::volvalavg] > 1} {
                            set min [expr int([expr [llength $QWIKMD::volval] - [expr 1.5 * $QWIKMD::imdFreq] -1])]  
                        }
                        set max [expr [llength $QWIKMD::volval] -1]
                        lappend QWIKMD::volvalavg [QWIKMD::mean [lrange $QWIKMD::volval $min $max]]
                        lappend QWIKMD::volpos $xtime
                        $QWIKMD::volGui add $QWIKMD::volpos $QWIKMD::volvalavg
                        if {[llength $QWIKMD::volvalavg] >= 2} {
                            if {[lindex $QWIKMD::volvalavg 0] == [lindex $QWIKMD::volvalavg 1] && [lindex $QWIKMD::volvalavg 1] == [lindex $QWIKMD::volvalavg end]} {
                            $QWIKMD::volGui configure -ymin [expr [lindex $QWIKMD::volvalavg 1] -1] -ymax [expr [lindex $QWIKMD::volvalavg 1] +1] -xmin auto -xmax auto
                            } else {
                                $QWIKMD::volGui configure -ymin auto -ymax auto -xmin auto -xmax auto
                            }
                        } else {
                            $QWIKMD::volGui configure -ymin auto -ymax auto -xmin auto -xmax auto
                        }
                        
                        $QWIKMD::volGui replot
                    } 
                    break
                }
            }
        }
    }           
    #### When these values pass through IMD connection, uncomment
    # if {$pressaux ==1} {
    #   $QWIKMD::pressGui clear

    #   lappend QWIKMD::pressval [molinfo $QWIKMD::topMol get pressure]
    #   lappend QWIKMD::presspos $xtime
    #   $QWIKMD::pressGui add $QWIKMD::presspos $QWIKMD::pressval
    #   if {[lindex $QWIKMD::pressval 0] == [lindex $QWIKMD::pressval 1] && [lindex $QWIKMD::pressval 1] == [lindex $QWIKMD::pressval end]} {
 #              $QWIKMD::pressGui configure -ymin [expr [lindex $QWIKMD::pressval 1] -1] -ymax [expr [lindex $QWIKMD::pressval 1] +1] -xmin auto -xmax auto
 #          } else {
 #              $QWIKMD::pressGui configure -ymin auto -ymax auto -xmin auto -xmax auto
 #          }
    #   $QWIKMD::pressGui replot
    # }

    # if {$volaux == 1} {
    #   $QWIKMD::volGui clear
        
    #   lappend QWIKMD::volval [molinfo $QWIKMD::topMol get volume]
    #   lappend QWIKMD::volpos $xtime
    #   $QWIKMD::volGui add $QWIKMD::volpos $QWIKMD::volval
    #   if {[lindex $QWIKMD::volval 0] == [lindex $QWIKMD::volval 1] && [lindex $QWIKMD::volval 1] == [lindex $QWIKMD::volval end]} {
 #              $QWIKMD::volGui configure -ymin [expr [lindex $QWIKMD::volval 1] -1] -ymax [expr [lindex $QWIKMD::volval 1] +1] -xmin auto -xmax auto
 #          } else {
 #              $QWIKMD::volGui configure -ymin auto -ymax auto -xmin auto -xmax auto
 #          }
    #   $QWIKMD::volGui replot
    # }
    
}
#####################################################################
## Return the QM ID associated with the current QM energies plot
#####################################################################
proc QWIKMD::getqmIDPlot {arg} {
    set qmID ""
    set key "qmmm"
    if {$arg == "orbital"} {
        set key "qmorb"
    }
    regsub $key [lindex [split [$QWIKMD::advGui(analyze,advance,ntb) select] "."] end] "" qmID
    return $qmID
}
#####################################################################
## Plot QM Energies
#####################################################################
proc QWIKMD::callQMEnergies {} {
    set prtcl [list]
    set regionlist [list]
    if {[$QWIKMD::advGui(analyze,advance,qmprtcltbl) size] == 0} {
        return
    }
    for {set i 0} {$i < [llength $QWIKMD::confFile]} {incr i} {
        
        set tblwindw [$QWIKMD::advGui(analyze,advance,qmprtcltbl) windowpath $i,0]
       
        if {[$tblwindw.r state !selected] == "selected"} {
            lappend prtcl [$QWIKMD::advGui(analyze,advance,qmprtcltbl) cellcget $i,1 -text]
            $tblwindw.r state selected
        } else {
            $tblwindw.r state !selected
        }
    }

    for {set qmID 1} {$qmID <= [$QWIKMD::advGui(qmtable) size]} {incr qmID} {
        
        set tblwindw [$QWIKMD::advGui(analyze,advance,qmenertbl) windowpath [expr $qmID - 1],0]
       
        if {[$tblwindw.r state !selected] == "selected"} {
            lappend regionlist $qmID
            $tblwindw.r state selected
        } else {
            $tblwindw.r state !selected
        }
    }


    set ylab "Energy\n(kcal/mol)"
    set xlab "Time (ps)"

    foreach qmID $regionlist {
        set plotname ""
        
        if {[info exist QWIKMD::advGui(analyze,advance,$qmID)] == 0} {
            set title "AVG QM Region $qmID Energy vs Time"
            set info [QWIKMD::addplot "qmmm${qmID}" "QM Ene $qmID" $title $xlab $ylab]
            set QWIKMD::advGui(analyze,advance,plot,$qmID) [lindex $info 0]
            set clear [lindex $info 1]
            set close [lindex $info 2]
            
            $clear entryconfigure 0 -command {
                set qmID [QWIKMD::getqmIDPlot energy]
                $QWIKMD::advGui(analyze,advance,plot,$qmID) clear
                set QWIKMD::advGui(analyze,advance,plot,$qmID,xvals) [list]
                set QWIKMD::advGui(analyze,advance,plot,$qmID,evalsavg) [list]
                $QWIKMD::advGui(analyze,advance,plot,$qmID) add 0 0
                $QWIKMD::advGui(analyze,advance,plot,$qmID) replot
            }

            $close entryconfigure 0 -command {
                set qmID [QWIKMD::getqmIDPlot energy]
                $QWIKMD::advGui(analyze,advance,plot,$qmID) quit
                destroy $QWIKMD::advGui(analyze,advance,ntb).qmmm${qmID}
                set QWIKMD::advGui(analyze,advance,plot,$qmID) ""
            }
            set QWIKMD::advGui(analyze,advance,plot,$qmID,xvals) [list]
            set QWIKMD::advGui(analyze,advance,plot,$qmID,evalsavg) [list]

        } elseif {$QWIKMD::advGui(analyze,advance,$qmID) != ""} {
            $QWIKMD::advGui(analyze,advance,plot,$qmID) clear
            set QWIKMD::advGui(analyze,advance,plot,$qmID,xvals) [list]
            set QWIKMD::advGui(analyze,advance,plot,$qmID,evalsavg) [list]
            $QWIKMD::advGui(analyze,advance,plot,$qmID) add 0 0
            $QWIKMD::advGui(analyze,advance,plot,$qmID) replot
        }
    }

    if {$QWIKMD::load == 1 && $QWIKMD::run == "QM/MM"} {
        if {[llength $regionlist] == 0 || [llength $prtcl] == 0} {
            tk_messageBox -title "Missing QM Region or Protocol" -message "Please select at least one \
            QM Region and one protocol to be analyzed." -type ok -icon warning -parent $QWIKMD::topGui
            return
        }
        set j 0
        array set qmeneraux ""
        foreach qmID $regionlist {
            set QWIKMD::advGui(analyze,advance,plot,$qmID,evalsprevx) 0
            set QWIKMD::advGui(analyze,advance,plot,$qmID,evalsprevindex) 0
            set qmeneraux($qmID) [list]
        }
        set xtime 0
        set limit 10
        set limitaux $limit 
        set print 0
        set energyfreq 1
        set const 2e-6  
        set tstep 0
        set tstepaux 0
        set eneprevindex 0
        set energyfreqaux 1
        set window 10
        set prevxtime 0
        for {set i 0} {$i < [llength $prtcl]} {incr i} {
            set do 0
           
            set confIndex [lsearch $QWIKMD::prevconfFile [lindex  $prtcl $i]]
            set file "${QWIKMD::outPath}/run/[lindex $prtcl $i].log"
            if {$QWIKMD::advGui(protocoltb,$QWIKMD::run,$confIndex,qmmm) == 1 && [file exists $file] ==1} {
                set do 1
            }   
            
            if {$do == 1} {
                set logfile [open $file r]
                set reset 0
                set tmstp 0
                set prevtmstp 0
                while {[eof $logfile] != 1 } {
                    set line [gets $logfile]
                    if {[lindex $line 0] == "Info:" && [lindex $line 1] == "TIMESTEP"} {
                        set aux [lindex $line 2]
                        set const [expr $aux * 1e-6]
                        if {$QWIKMD::run == "QM/MM"} {
                            set const [expr $const * 1e3]
                        } 
                        set tstepaux 0
                    }
                    if {[lindex $line 0] == "Info:" && [join [lrange $line 1 3]] == "ENERGY OUTPUT STEPS" } {
                        set energyfreq [lindex $line 4]
                        set energyfreqaux $energyfreq
                        set tabid [lindex [lindex $QWIKMD::selnotbooks 0] 1]
                        if {$QWIKMD::basicGui(live,$tabid) == 0} {
                            set limit [expr $energyfreq * $window] 
                            set limitaux $limit 
                        }
                    }
                    if {[lindex $line 0] == "TCL:" && [lindex $line 1] == "Minimizing" } {
                        set energyfreq 1
                        set limit $window
                    }
                    if {[lindex $line 0] == "TCL:" && [lindex $line 1] == "Running" && $reset == 0 } {
                        set energyfreq $energyfreqaux
                        set limit $limitaux     
                        set tstepaux 0
                        set reset 1
                    }                    
                    if {[lindex $line 0]  == "QMENERGY:" && [lindex $line 1] != $prevtmstp && [lsearch $regionlist [QWIKMD::format0Dec [lindex $line 2]]] > -1} {
                        lappend qmeneraux([QWIKMD::format0Dec [lindex $line 2]]) [lindex $line 3]
                        incr tstep $energyfreq
                        incr tstepaux $energyfreq
                        if {[lsearch $regionlist [QWIKMD::format0Dec [lindex $line 2]]] == [expr [llength $regionlist] -1]} {
                            set prevtmstp [lindex $line 1]
                        }
                    }
                    if {[expr $tstepaux % $limit] == 0 && $tstep != $eneprevindex} {
                        set xtime [QWIKMD::format4Dec  [expr $const * $tstep ]]
                        foreach qmID $regionlist {
                            if {[llength $qmeneraux($qmID)] == 0} {
                                continue
                            }
                            set min 0
                            set minaux [expr int([expr [llength $qmeneraux($qmID)] - [expr 1.5 * $window] -1])]  
                            if {$minaux > 0} {
                                set min $minaux
                            }
                            
                            set max [expr [llength $qmeneraux($qmID)] -1]
                            lappend QWIKMD::advGui(analyze,advance,plot,$qmID,evalsavg) [QWIKMD::mean [lrange $qmeneraux($qmID) $min $max]]
                            lappend QWIKMD::advGui(analyze,advance,plot,$qmID,xvals) $xtime
                            set print 1
                        }
                        set eneprevindex $tstep
                    }
                }
                if {$print == 1} {
                    set time [expr $xtime - $prevxtime]
                    puts $QWIKMD::textLogfile [QWIKMD::printQMEnergies [lindex $prtcl $i].log $time $limit [expr 1.5 * $window] $energyfreq $const $regionlist]
                    set prevxtime $xtime
                    flush $QWIKMD::textLogfile
                }
                if {$reset == 0} {
                    set qmeneraux($qmID) [list]
                }
                close $logfile      
            }
            
        }
        foreach qmID $regionlist {
            if {[llength $QWIKMD::advGui(analyze,advance,plot,$qmID,xvals)] > 0} {
                $QWIKMD::advGui(analyze,advance,plot,$qmID) clear
                $QWIKMD::advGui(analyze,advance,plot,$qmID) add $QWIKMD::advGui(analyze,advance,plot,$qmID,xvals) $QWIKMD::advGui(analyze,advance,plot,$qmID,evalsavg)
                $QWIKMD::advGui(analyze,advance,plot,$qmID) replot
            }
        }
    } 
}
################################################################################
### list and plot the QM orbitals and energies
################################################################################
proc QWIKMD::callQMOrbitals {} {
    global variable vmd_frame
    set prtcl [list]
    set regionlist [list]

    if {[info exists QWIKMD::advGui(analyze,advance,qmprtcltbl)] == 0 ||
        [$QWIKMD::advGui(analyze,advance,qmprtcltbl) size] == 0} {
        return
    }

    for {set i 0} {$i < [$QWIKMD::advGui(analyze,advance,qmprtcltbl) size]} {incr i} {
        
        set tblwindw [$QWIKMD::advGui(analyze,advance,qmprtcltbl) windowpath $i,0]
       
        if {[$tblwindw.r state !selected] == "selected"} {
            set text [$QWIKMD::advGui(analyze,advance,qmprtcltbl) cellcget $i,1 -text]
            if {$text == "Initial Structure"} {
                set text [file root [lindex $QWIKMD::inputstrct 0]]
            }
            lappend prtcl $text
            $tblwindw.r state selected
        } else {
            $tblwindw.r state !selected
        }
    }


    set ylab "Orbital\nEnergy"
    set xlab "Time (ps)"

    
    set qmID [expr $QWIKMD::curframe +1]

    if {[info exist QWIKMD::advGui(analyze,advance,$qmID)] == 0} {
        set title " QM Region $qmID Orbitals Energy vs Time"
        set info [QWIKMD::addplot "qmorb${qmID}" "QM Orb $qmID" $title $xlab $ylab]
        set QWIKMD::advGui(analyze,advance,plot,qmorbital,$qmID) [lindex $info 0]
        set clear [lindex $info 1]
        set close [lindex $info 2]
        
        $clear entryconfigure 0 -command {
            set qmID [QWIKMD::getqmIDPlot orbital]
            $QWIKMD::advGui(analyze,advance,plot,qmorbital,$qmID) clear
            set QWIKMD::advGui(analyze,advance,plot,qmorbital,$qmID,xvals) [list]
            set QWIKMD::advGui(analyze,advance,plot,qmorbital,$qmID,evals) [list]
            set QWIKMD::advGui(analyze,advance,plot,qmorbital,$qmID,orb) [list]
            set QWIKMD::advGui(analyze,advance,plot,qmorbital,$qmID,frame) [list]
            set QWIKMD::advGui(analyze,advance,plot,qmorbital,$qmID,homoframelist) [list]
            set QWIKMD::advGui(analyze,advance,plot,qmorbital,$qmID,orbselected) [list]
            $QWIKMD::advGui(analyze,advance,plot,qmorbital,$qmID) add 0 0
            $QWIKMD::advGui(analyze,advance,plot,qmorbital,$qmID) replot
            QWIKMD::deletePlotLines $qmID
        }

        $close entryconfigure 0 -command {
            set qmID [QWIKMD::getqmIDPlot orbital]
            $QWIKMD::advGui(analyze,advance,plot,qmorbital,$qmID) quit
            destroy $QWIKMD::advGui(analyze,advance,ntb).qmorb${qmID}
            set QWIKMD::advGui(analyze,advance,plot,qmorbital,$qmID) ""
            set QWIKMD::advGui(analyze,advance,plot,qmorbital,$qmID,xvals) [list]
            set QWIKMD::advGui(analyze,advance,plot,qmorbital,$qmID,evals) [list]
            set QWIKMD::advGui(analyze,advance,plot,qmorbital,$qmID,orb) [list]
            set QWIKMD::advGui(analyze,advance,plot,qmorbital,$qmID,frame) [list]
            set QWIKMD::advGui(analyze,advance,plot,qmorbital,$qmID,homoframelist) [list]
            set QWIKMD::advGui(analyze,advance,plot,qmorbital,$qmID,orbselected) [list]
            set QWIKMD::advGui(analyze,advance,plot,evalsprevx) 0
            set QWIKMD::advGui(analyze,advance,plot,evalsprevindex) 0
            set QWIKMD::qmorbrep [list]
            set QWIKMD::orbprevreplist [list]
            set QWIKMD::qmtslist [list]
            if {$QWIKMD::qmorbmol != -1} {
                mol delete $QWIKMD::qmorbmol
                set QWIKMD::qmorbmol -1
            }
            $QWIKMD::advGui(analyze,qmorb,table) delete 0 end
        }
        set QWIKMD::advGui(analyze,advance,plot,qmorbital,$qmID,xvals) [list]
        set QWIKMD::advGui(analyze,advance,plot,qmorbital,$qmID,evals) [list]
        set QWIKMD::advGui(analyze,advance,plot,qmorbital,$qmID,orb) [list]
        set QWIKMD::advGui(analyze,advance,plot,qmorbital,$qmID,frame) [list]
        set QWIKMD::advGui(analyze,advance,plot,qmorbital,$qmID,orbselected) [list]
        set QWIKMD::advGui(analyze,advance,plot,qmorbital,$qmID,label) [list]
        set QWIKMD::advGui(analyze,advance,plot,qmorbital,$qmID,homoframelist) [list]
    } elseif {$QWIKMD::advGui(analyze,advance,qmorbital,$qmID) != ""} {
        $QWIKMD::advGui(analyze,advance,plot,qmorbital,$qmID) clear
        set QWIKMD::advGui(analyze,advance,plot,qmorbital,$qmID,xvals) [list]
        set QWIKMD::advGui(analyze,advance,plot,qmorbital,$qmID,evals) [list]
        set QWIKMD::advGui(analyze,advance,plot,qmorbital,$qmID,orb) [list]
        set QWIKMD::advGui(analyze,advance,plot,qmorbital,$qmID,frame) [list]
        set QWIKMD::advGui(analyze,advance,plot,qmorbital,$qmID,orbselected) [list]
        set QWIKMD::advGui(analyze,advance,plot,qmorbital,$qmID,label) [list]
        set QWIKMD::advGui(analyze,advance,plot,qmorbital,$qmID,homoframelist) [list]
        $QWIKMD::advGui(analyze,advance,plot,qmorbital,$qmID) add 0 0
        $QWIKMD::advGui(analyze,advance,plot,qmorbital,$qmID) replot
    }
    

    if {$QWIKMD::load == 1 && $QWIKMD::run == "QM/MM"} {
        if {$regionlist == -1 || [llength $prtcl] == 0} {
            tk_messageBox -title "Missing QM Region or Protocol" -message "Please select at least one \
            QM Region and one protocol to be analyzed." -type ok -icon warning -parent $QWIKMD::topGui
            return -1
        }
        set j 0

        set QWIKMD::advGui(analyze,advance,plot,evalsprevx) 0
        set QWIKMD::advGui(analyze,advance,plot,evalsprevindex) 0
        set QWIKMD::qmorbrep [list]
        set QWIKMD::orbprevreplist [list]
        set qmeneraux [list]
        set QWIKMD::qmtslist [list]
        ### Load orbital files
        if {$QWIKMD::qmorbmol != -1} {
            mol delete $QWIKMD::qmorbmol
            set QWIKMD::qmorbmol -1
        }

        for {set i 0} {$i < [llength $prtcl]} {incr i} {
            set orbfile "[lindex  $prtcl $i]_qmout.[expr $qmID -1].out"
            if {[file exists $orbfile] == 0} {
                tk_messageBox -message "Could not find the QM Orbitals file $orbfile "\
                 -title "QM Orbitals file" -icon error -type ok -parent $QWIKMD::topGui
                 return
            }
            set pckg "orca"
            set prtclname [lindex $prtcl $i]
            if {$i == 0 && [lsearch $QWIKMD::confFile $prtclname] == -1} {
                if {[llength $prtcl] == 1} {
                    set prtclname [lindex $QWIKMD::prevconfFile [expr $i +1] ]
                } else {
                    set prtclname [lindex $prtcl [expr $i +1] ]
                }
            }
            if {$QWIKMD::advGui(qmoptions,soft,$prtclname) == "MOPAC"} {
                set pckg "mopac"
            }
            if {$QWIKMD::qmorbmol == -1 || [lsearch [molinfo list] $QWIKMD::qmorbmol] == -1} {
                set QWIKMD::qmorbmol [mol new $orbfile type $pckg waitfor all]
            } else {
               
                mol addfile $orbfile type $pckg waitfor all $QWIKMD::qmorbmol
            }

            ### If loading the qmout of the initial structure, get the timestep from the next run
            set filename "[lindex  $prtcl $i].log"
            if {$i == 0 && [lsearch $QWIKMD::confFile [lindex $prtcl $i]] == -1} {
                if {[llength $prtcl] == 1} {
                    lappend QWIKMD::qmtslist [list 0 [expr 0.5 * 1e-3]]
                    continue 
                } else {
                    set filename "[lindex  $prtcl [expr $i + 1] ].log"
                }   
            }
            set logfile [open $filename r]
            while {[eof $logfile] != 1 } {
                set line [gets $logfile]
                if {[lindex $line 0] == "Info:" && [lindex $line 1] == "TIMESTEP"} {
                    set aux [lindex $line 2]
                    lappend QWIKMD::qmtslist [list [expr [molinfo $QWIKMD::qmorbmol get numframes] -1] [expr $aux * 1e-3]]
                    break
                }
            }
            close $logfile
        }
        
        set nf [molinfo $QWIKMD::qmorbmol get numframes]
        if {$nf != [molinfo $QWIKMD::topMol get numframes]} {
            tk_messageBox -message "The number of frames of the trajectory and of the orbitals files\
            are different. Please make sure that you loaded the same protocols, including the initial structure." \
            -title "Different Number of Frames" -icon warning -type ok -parent $QWIKMD::topGui
            $QWIKMD::advGui(analyze,advance,plot,qmorbital,$qmID) quit
            destroy $QWIKMD::advGui(analyze,advance,ntb).qmmm${qmID}
            set QWIKMD::advGui(analyze,advance,plot,qmorbital,$qmID) ""
            return
        }
        
        set sel [atomselect $QWIKMD::qmorbmol all]
        for {set i 0} {$i < $nf} {incr i} {
            $sel frame $i
            animate goto $i
            set qmcharges [molinfo $QWIKMD::qmorbmol get qmcharges]
            foreach chrg $qmcharges {
              if {[lindex $chrg 0 0] == "Mulliken"} {
                $sel set user [lindex $chrg 0 1]
                break
              }
            }
        }
        $sel delete
        color scale method BWR
        animate goto 0

        mol delrep 0 $QWIKMD::qmorbmol

        mol addrep $QWIKMD::qmorbmol
        set rep [expr [molinfo $QWIKMD::qmorbmol get numreps] -1]
        
        mol modcolor $rep $QWIKMD::qmorbmol Name
        mol modstyle $rep $QWIKMD::qmorbmol "CPK 1.00000 0.500000 12.000000 12.000000"
        mol modselect $rep $QWIKMD::qmorbmol all
        mol modmaterial $rep $QWIKMD::qmorbmol Glossy
        lappend QWIKMD::qmorbrep [concat -1 $rep]
        QWIKMD::updateOrbitalsTable
        QWIKMD::showOrbitals
        QWIKMD::plotOrbitals

        ### Update the table with the orbitals energy values of the current frame
        ### Make sure the the command to be called has arguments or \"args" in the definition
        trace add variable vmd_frame($QWIKMD::qmorbmol) write QWIKMD::updateOrbitalsTable
        mol top $QWIKMD::topMol

    } 
}
################################################################################
### PLot orbitals energies for the current frame
################################################################################
proc QWIKMD::plotOrbitals {} {

    set qmID [expr $QWIKMD::curframe +1]

    if {[info exists QWIKMD::advGui(analyze,advance,plot,qmorbital,$qmID)] == 0 ||
        $QWIKMD::advGui(analyze,advance,plot,qmorbital,$qmID) == ""} {
        if {[QWIKMD::callQMOrbitals] < 0 } {
            return
        }
    }

    set orblist [$QWIKMD::advGui(analyze,qmorb,table) getcolumns 0]
    set descrlist [$QWIKMD::advGui(analyze,qmorb,table) getcolumns 1]
    set energylist [$QWIKMD::advGui(analyze,qmorb,table) getcolumns 2]

    set curframe [molinfo $QWIKMD::qmorbmol get frame]
    set tmstep [lindex [lindex $QWIKMD::qmtslist 0 ] 1]
    set i 0
    while {$curframe > [lindex [lindex $QWIKMD::qmtslist $i] 0] && $i < [llength $QWIKMD::qmtslist]} {
        set tmstep [lindex [lindex $QWIKMD::qmtslist $i] 1]
        incr i
    } 

    if {$i > [llength $QWIKMD::qmtslist]} {
        set tmstep [lindex [lindex $QWIKMD::qmtslist [expr $i -1] ] 1]
    }
    set xval [expr $curframe * $tmstep]
    if {[lsearch $QWIKMD::advGui(analyze,advance,plot,qmorbital,$qmID,frame) $curframe] == -1} {
        foreach energy $energylist orb $orblist descr $descrlist {
            lappend QWIKMD::advGui(analyze,advance,plot,qmorbital,$qmID,xvals) $xval
            lappend QWIKMD::advGui(analyze,advance,plot,qmorbital,$qmID,evals) $energy
            lappend QWIKMD::advGui(analyze,advance,plot,qmorbital,$qmID,orb) $orb
            lappend QWIKMD::advGui(analyze,advance,plot,qmorbital,$qmID,frame) $curframe
            if {$descr == "HOMO"} {
                lappend QWIKMD::advGui(analyze,advance,plot,qmorbital,$qmID,homoframelist) [list $xval $orb $energy]
            }
        }
    }

    set lframes [lsort -unique -real $QWIKMD::advGui(analyze,advance,plot,qmorbital,$qmID,xvals)]
    set framdist 0.5
    if {[llength $lframes] > 1} {
        ### Set frame dist to evaluate the biggest width for energy lines
        ### framdist is so big in the beginning because we want to find the smallest different 
        ### and use 25% of the difference as width
        
        set framdist 999999
        for {set i 1} {$i < [llength $lframes]} {incr i} {
            set dist [expr [lindex $lframes $i] - [lindex $lframes [expr $i -1]] ]
            if {$dist < $framdist} {
                set framdist $dist
            }
        }
       
        set framdist [expr abs($framdist * 0.25)]
    }
    set tbind [$QWIKMD::advGui(analyze,qmorb,table) curselection]
    if {[llength $tbind] == 2 && [lsearch $QWIKMD::advGui(analyze,advance,plot,qmorbital,$qmID,orbselected) "$xval [lindex $energylist [lindex $tbind 0]] [lindex $orblist [lindex $tbind 1]] * * *"] == -1 && [lsearch $QWIKMD::advGui(analyze,advance,plot,qmorbital,$qmID,orbselected) "$xval [lindex $energylist [lindex $tbind 1]] [lindex $orblist [lindex $tbind 0]] * * *"]} {
        ### orbselected stores {xmin ymin xmax ymax} of the selected orbitals
        set orb1 [lindex $orblist [lindex $tbind 0]]
        set orb2 [lindex $orblist [lindex $tbind 1]]
        set ene1 [lindex $energylist [lindex $tbind 0]]
        set ene2 [lindex $energylist [lindex $tbind 1]]
        if {$orb2 < $orb1} {
            set aux $ene1
            set ene1 $ene2
            set ene1 $aux
        }
        lappend QWIKMD::advGui(analyze,advance,plot,qmorbital,$qmID,orbselected) [list $xval $ene1 $ene2 $tbind $curframe $framdist]
        
    }
    


    set xmin [expr [lindex $lframes 0] - 2 * $framdist ]
    set xmax [expr [lindex $lframes end] + 2 * $framdist]

    set ymin [expr [QWIKMD::mincalc $QWIKMD::advGui(analyze,advance,plot,qmorbital,$qmID,evals)] - 0.1]
    set ymax [expr [QWIKMD::maxcalc $QWIKMD::advGui(analyze,advance,plot,qmorbital,$qmID,evals)] + 0.1]

    ### Configure plot axis
    $QWIKMD::advGui(analyze,advance,plot,qmorbital,$qmID) configure -xmin $xmin -xmax $xmax -ymin $ymin -ymax $ymax
    
    ### Clean up lines and data points
    $QWIKMD::advGui(analyze,advance,plot,qmorbital,$qmID) clear
    QWIKMD::deletePlotLines $qmID

    set preframe [lindex $QWIKMD::advGui(analyze,advance,plot,qmorbital,$qmID,frame) 0]
    set xframe [list]
    set yenergy [list]
    
    foreach energy $QWIKMD::advGui(analyze,advance,plot,qmorbital,$qmID,evals) \
    x $QWIKMD::advGui(analyze,advance,plot,qmorbital,$qmID,xvals) \
    orb $QWIKMD::advGui(analyze,advance,plot,qmorbital,$qmID,orb) \
    frame $QWIKMD::advGui(analyze,advance,plot,qmorbital,$qmID,frame) {
        set xminm [expr $x - $framdist]
        set xmaxi [expr $x + $framdist]

        if {$frame != $preframe } {
            $QWIKMD::advGui(analyze,advance,plot,qmorbital,$qmID) add $xframe $yenergy -marker none -nolines
            set index [lsearch -all -index 0 $QWIKMD::advGui(analyze,advance,plot,qmorbital,$qmID,orbselected) [lindex $xframe 0] ]
            foreach ind $index {
                QWIKMD::addQMOrbDeltaLine $qmID [lindex $QWIKMD::advGui(analyze,advance,plot,qmorbital,$qmID,orbselected) $ind] $framdist
            }
            
            set xframe $x
            set yenergy $energy
            set preframe $frame
        } else {
            lappend xframe $x
            lappend yenergy $energy
        }
        set fill black
        if {[lsearch $QWIKMD::advGui(analyze,advance,plot,qmorbital,$qmID,homoframelist) "* $orb $energy" ] != -1} {
            set fill blue
        }
        $QWIKMD::advGui(analyze,advance,plot,qmorbital,$qmID) draw line $xminm $energy $xmaxi $energy -width 2 -fill $fill -tags ${orb}orb$frame
        
        ### Add the binding command to the lines when pressed with the left click mouse
        lappend QWIKMD::advGui(analyze,advance,plot,qmorbital,$qmID,label) ${orb}orb$frame
        
        set text "animate goto $frame;QWIKMD::updateOrbitalsTable;\$QWIKMD::advGui(analyze,qmorb,table) selection clear 0 end;\$QWIKMD::advGui(analyze,qmorb,table) selection set \[lsearch \[\$QWIKMD::advGui(analyze,qmorb,table) getcolumns 0\] $orb\];QWIKMD::showOrbitals"
        eval "$[$QWIKMD::advGui(analyze,advance,plot,qmorbital,$qmID) namespace]::c bind ${orb}orb$frame <Any-ButtonPress> \"$text\""
        
        
    }

    ### connect the homo orbitals energy values
    if {[llength $QWIKMD::advGui(analyze,advance,plot,qmorbital,$qmID,homoframelist)] > 0} {

        set homoframelist [lsort -index 0 $QWIKMD::advGui(analyze,advance,plot,qmorbital,$qmID,homoframelist)]
        for {set i 1} {$i < [llength $homoframelist]} {incr i} {
            set orbframe1 [lindex $homoframelist [expr $i -1]]
            set orbframe2 [lindex $homoframelist $i]

            set frame1 [lindex $orbframe1 0]
            set orb1 [lindex $orbframe1 1]
            set energy1 [lindex $orbframe1 2]

            set frame2 [lindex $orbframe2 0]
            set orb2 [lindex $orbframe2 1]
            set energy2 [lindex $orbframe2 2]
           
            set xmin [expr $frame1 + $framdist]
            set ymin $energy1

            set xmax [expr $frame2 - $framdist]
            set ymax $energy2

            $QWIKMD::advGui(analyze,advance,plot,qmorbital,$qmID) draw line $xmin $ymin $xmax $ymax -width 2 -fill blue -dash - -tags ${frame1}homo$frame2

            lappend QWIKMD::advGui(analyze,advance,plot,qmorbital,$qmID,label) ${frame1}homo$frame2
        }
    }

    ### Add points and text to the plot
    if {[llength $xframe] >0} {
        $QWIKMD::advGui(analyze,advance,plot,qmorbital,$qmID) add $xframe $yenergy -marker none -nolines
        set index [lsearch -all -index 0 $QWIKMD::advGui(analyze,advance,plot,qmorbital,$qmID,orbselected) [lindex $xframe 0] ]
        foreach ind $index {
            QWIKMD::addQMOrbDeltaLine $qmID [lindex $QWIKMD::advGui(analyze,advance,plot,qmorbital,$qmID,orbselected) $ind] $framdist
        }
        set xframe [list]
        set yenergy [list]
    }

    $QWIKMD::advGui(analyze,advance,plot,qmorbital,$qmID) replot
}
################################################################################
### Add delta lines to the plot
################################################################################
proc QWIKMD::addQMOrbDeltaLine {qmID orbselected framdistt} {
    
    set x [lindex $orbselected 0]
    set ymin [lindex $orbselected 2]
    set ymax [lindex $orbselected 1]
    set y [expr $ymax - $ymin]
    set tbind [lindex $orbselected 3]
    set frame [lindex $orbselected 4]
    set framdist [lindex $orbselected 5]

    $QWIKMD::advGui(analyze,advance,plot,qmorbital,$qmID) draw line $x $ymin $x $ymax -width 4 -fill orange -tags deltaline$frame

    lappend QWIKMD::advGui(analyze,advance,plot,qmorbital,$qmID,label) deltaline$frame
    set command "animate goto $frame;QWIKMD::updateOrbitalsTable;\$QWIKMD::advGui(analyze,qmorb,table) selection clear 0 end;\$QWIKMD::advGui(analyze,qmorb,table) selection set [list $tbind];QWIKMD::showOrbitals"
    eval "$[$QWIKMD::advGui(analyze,advance,plot,qmorbital,$qmID) namespace]::c bind deltaline$frame <Any-ButtonPress> \"$command\""

    set text [QWIKMD::format5Dec [expr ([lindex $orbselected 2] - [lindex $orbselected 1])]]
    set position [expr ([lindex $orbselected 2] + [lindex $orbselected 1])/2]
    $QWIKMD::advGui(analyze,advance,plot,qmorbital,$qmID) draw text $x $position -fill black -tags ${ymin}y${ymax}text$frame -text $text -justify center -anchor w

    lappend QWIKMD::advGui(analyze,advance,plot,qmorbital,$qmID,label) ${ymin}y${ymax}text$frame

    eval "$[$QWIKMD::advGui(analyze,advance,plot,qmorbital,$qmID) namespace]::c bind ${ymin}y${ymax}text$frame <Any-ButtonPress> \"$command\""
    
}
################################################################################
### Proc to show the selected orbital
################################################################################
proc QWIKMD::updateOrbitalsTable {args} {
    ### save table selection to be kept after updating the values
    set tableselection [$QWIKMD::advGui(analyze,qmorb,table) curselection]
    for {set qmID 1} {$qmID <= [$QWIKMD::advGui(qmtable) size]} {incr qmID} {
        
        set tblwindw [$QWIKMD::advGui(analyze,advance,qmenertbl) windowpath [expr $qmID - 1],0]
       
        if {[$tblwindw.r state !selected] == "selected"} {
            lappend regionlist $qmID
            $tblwindw.r state selected
        } else {
            $tblwindw.r state !selected
        }
    }

    $QWIKMD::advGui(analyze,qmorb,table) delete 0 end
    set descr ""
    foreach qmID $regionlist {
        
        set norbs [molinfo $QWIKMD::qmorbmol get numorbitals]
        set homo [molinfo $QWIKMD::qmorbmol get homo]

        set lowerlimit 0
        set lowerlimit [expr $homo - $QWIKMD::advGui(analyze,qmorb,span)]
        if {$lowerlimit < 0} {
            set lowerlimit 0
        }

        set uperlimit [expr $homo + $QWIKMD::advGui(analyze,qmorb,span)]
        if {$uperlimit > $norbs} {
            set uperlimit [expr $norbs - 1]
        }

        set energies [lrange [join [lindex [molinfo $QWIKMD::qmorbmol get orbenergies] 0]] $lowerlimit $uperlimit]
        set j 0
        for {set i $lowerlimit} {$i <= $uperlimit} {incr i} {
            set diff [expr abs($homo - $i)]
            if {$i <= [expr $homo -1]} {
                set descr "HOMO-$diff"
            } elseif {$i == $homo} {
                set descr "HOMO"
            } elseif {$i == [expr $homo + 1]} {
                set descr "LUMO"
            } elseif {$i > [expr $homo + 1]} {
                incr diff -1
                set descr "LUMO+$diff"
            }
            $QWIKMD::advGui(analyze,qmorb,table) insert end [list $i $descr [lindex $energies $j]]
            incr j
        }
    }
    $QWIKMD::advGui(analyze,qmorb,table) selection set $tableselection
    return
}
################################################################################
### Proc to display the orbitals representation
################################################################################
proc QWIKMD::showOrbitals {} {
    set tbindex [$QWIKMD::advGui(analyze,qmorb,table) curselection]
    if {$tbindex == -1 || [llength $tbindex] == 0} {
        for {set i 0} {$i < [llength $QWIKMD::orbprevreplist]} {incr i} {
            set index [lsearch -index 0 $QWIKMD::qmorbrep [lindex $QWIKMD::orbprevreplist $i] ]
            if {[lindex [lindex $QWIKMD::qmorbrep $index] 0] == -1} {
                continue
            } 
            foreach repname [lindex [lindex $QWIKMD::qmorbrep $index] 1] {

                mol delrep [QWIKMD::getrepnum $repname $QWIKMD::qmorbmol] $QWIKMD::qmorbmol
            }
        }
        set QWIKMD::orbprevrep [list]
        return
    }
    for {set i 0} {$i < [llength $QWIKMD::orbprevreplist]} {incr i} {
        if {[lsearch $tbindex [lindex $QWIKMD::orbprevreplist $i]] == -1} {
            set index [lsearch -index 0 $QWIKMD::qmorbrep [lindex $QWIKMD::orbprevreplist $i] ] 

            foreach repname [lindex [lindex $QWIKMD::qmorbrep $index] 1] {
                mol delrep [QWIKMD::getrepnum $repname $QWIKMD::qmorbmol] $QWIKMD::qmorbmol
            }
            set QWIKMD::qmorbrep [lreplace $QWIKMD::qmorbrep $index $index]
        }
    }

    set frm [molinfo $QWIKMD::qmorbmol get frame]
    set orlist [list]
    foreach ind $tbindex {
        lappend orblist [$QWIKMD::advGui(analyze,qmorb,table) cellcget $ind,0 -text]
        set orb [lindex $orblist end]
        if {[llength $QWIKMD::qmorbrep] > 0 && [lsearch -index 0 $QWIKMD::qmorbrep $orb] != -1} {
            continue
        }
        set listrep [list]

        mol addrep $QWIKMD::qmorbmol
        set rep [expr [molinfo $QWIKMD::qmorbmol get numreps] -1]
        lappend listrep [mol repname $QWIKMD::qmorbmol $rep]

        mol modcolor $rep $QWIKMD::qmorbmol ColorID 0
        mol modstyle $rep $QWIKMD::qmorbmol "Orbital 0.050000 $orb 0 0 0.125 1 0 0 0 1"
        mol modselect $rep $QWIKMD::qmorbmol all
        mol modmaterial $rep $QWIKMD::qmorbmol Glossy
        
        mol addrep $QWIKMD::qmorbmol
        set rep [expr [molinfo $QWIKMD::qmorbmol get numreps] -1]
        lappend listrep [mol repname $QWIKMD::qmorbmol $rep]

        mol modcolor $rep $QWIKMD::qmorbmol ColorID 3
        mol modstyle $rep $QWIKMD::qmorbmol "Orbital -0.050000 $orb 0 0 0.125 1 0 0 0 1"
        mol modselect $rep $QWIKMD::qmorbmol all
        mol modmaterial $rep $QWIKMD::qmorbmol Glossy

        lappend QWIKMD::qmorbrep [concat $orb [list $listrep] ]
    }

    set QWIKMD::orbprevreplist $orblist
}
################################################################################
### Delete lines from plot of the orbitals
################################################################################
proc QWIKMD::deletePlotLines {qmID} {
    if {[llength $QWIKMD::advGui(analyze,advance,plot,qmorbital,$qmID,label)] > 0} {
        foreach label $QWIKMD::advGui(analyze,advance,plot,qmorbital,$qmID,label) {
            $QWIKMD::advGui(analyze,advance,plot,qmorbital,$qmID) undraw $label
            # eval "$[$QWIKMD::advGui(analyze,advance,plot,qmorbital,$qmID) namespace]::c dtag $label"
            eval "$[$QWIKMD::advGui(analyze,advance,plot,qmorbital,$qmID) namespace]::c delete $label"
            set [$QWIKMD::advGui(analyze,advance,plot,qmorbital,$qmID) namespace]::objectlist {}
        }
        set QWIKMD::advGui(analyze,advance,plot,qmorbital,$qmID,label) [list]
    }
}

proc QWIKMD::SpecificHeatCalc {} {
    

    set title "AVG Total Energy vs Time"
    set ylab "Energy\n(kcal/mol)"
    set xlab "Time (TimeSteps)"
    if {$QWIKMD::SPHGui == ""} {
        set info [QWIKMD::addplot sph "Specific Heat" $title $xlab $ylab]
        set QWIKMD::SPHGui [lindex $info 0]

        set clear [lindex $info 1]
        set close [lindex $info 2]
        
        $clear entryconfigure 0 -command {
            $QWIKMD::SPHGui clear
            
            $QWIKMD::SPHGui add 0 0
            $QWIKMD::SPHGui replot
        }

        $close entryconfigure 0 -command {
            $QWIKMD::SPHGui quit
            destroy $QWIKMD::advGui(analyze,advance,ntb).sph
            set QWIKMD::tempDistGui ""
            set QWIKMD::SPHGui ""
        }
    } else {
        $QWIKMD::SPHGui clear
        $QWIKMD::SPHGui add 0 0
        $QWIKMD::SPHGui replot
    }
    set mol [mol new [lindex  ${QWIKMD::outPath}/run/$QWIKMD::inputstrct 0]]
    mol addfile  ${QWIKMD::outPath}/run/${QWIKMD::radiobtt}.dcd waitfor all
    
    if {[catch {glob *.inp} auxlist] == 0} {
        foreach file $auxlist {
            lappend parlist "-par $file"
        }
    }
    foreach par $QWIKMD::ParameterList {
        lappend parlist "-par ${QWIKMD::outPath}/run/[file tail $par]"
    }
    
    
    set sel ""
    if {[catch {atomselect $mol $QWIKMD::advGui(analyze,advance,selentry)} sel] == 0} {
        set command "namdenergy -sel $sel -all [join $parlist] -ofile ${QWIKMD::outPath}/run/$QWIKMD::radiobtt.namdenergy.dat "
        eval $command
    }
    

    set templatefile [open  ${QWIKMD::outPath}/run/$QWIKMD::radiobtt.namdenergy.dat r]
    set line [read -nonewline $templatefile]
    set line [split $line "\n"]
    close $templatefile
    set enter ""
    set lineIndex [lsearch -exact -all $line $enter]
    set avg 0.0
    set avgsqr 0.0
    set energypos ""
    set energyval ""
    for {set i 1} {$i < [llength $line]} {incr i} {
        set aux [lindex [lindex $line $i] 10]
        set avg [expr $avg + $aux]
        set avgsqr [expr $avgsqr + pow($aux,2)]
        lappend energyval [lindex [lindex $line $i] 10]
        lappend energypos [lindex [lindex $line $i] 0]
    }

    set avg [expr $avg / [expr [llength $line] -1] ]
    set avgsqr [expr $avgsqr / [expr [llength $line] -1] ]
    
    set QWIKMD::advGui(analyze,advance,kcal) [format %.3g [expr [expr $avgsqr - pow($avg,2)] / [expr $QWIKMD::advGui(analyze,advance,bkentry) * pow([expr $QWIKMD::advGui(analyze,advance,tempentry) + 273],2)]]]
    
    set m [expr [vecsum [$sel get mass]] * 1.66e-27] 
    set QWIKMD::advGui(analyze,advance,joul) [format %.3g [expr $QWIKMD::advGui(analyze,advance,kcal) / [expr 1.4386e20 * $m]]]
    $QWIKMD::SPHGui clear
    $QWIKMD::SPHGui add $energypos $energyval
    $QWIKMD::SPHGui replot
    $sel delete
    mol delete $mol
}
proc QWIKMD::TempDistCalc {} {
    set title "Temperature vs Time"
    set ylab "Temperature (K)"
    set xlab "Time (TimeSteps)"
    if {$QWIKMD::tempDistGui == ""} {
        set info [QWIKMD::addplot tmpdist "Temp Distribution" $title $xlab $ylab]
        set QWIKMD::tempDistGui [lindex $info 0]

        set clear [lindex $info 1]
        set close [lindex $info 2]
        
        $clear entryconfigure 0 -command {
            $QWIKMD::tempDistGui clear
            $QWIKMD::tempDistGui add 0 0
            $QWIKMD::tempDistGui replot
        }

        $close entryconfigure 0 -command {
            $QWIKMD::tempDistGui quit
            destroy $QWIKMD::advGui(analyze,advance,ntb).tmpdist
            set QWIKMD::tempDistGui ""
        }
        set QWIKMD::actempGui ""
    } else {
        $QWIKMD::tempDistGui clear
        $QWIKMD::tempDistGui add 0 0
        $QWIKMD::tempDistGui replot
    }
    if {$QWIKMD::load == 1} {
        set tempdistpos ""
        set tempdistval ""
        set templatefile [open "${QWIKMD::radiobtt}.log" r]
        set line [read $templatefile]
        set line [split $line "\n"]
        close $templatefile
        set enter ""
        set index [lsearch -exact -all $line $enter]
        for {set i 0} {$i < [llength $index]} {incr i} {
            lset line [lindex $index $i] "{} {}"
        }

        set index [lsearch -index 0 -all $line "ENERGY:"]
        for {set i 0} {$i < [llength $index]} {incr i} {
            lappend tempdistval [lindex [lindex $line [lindex $index $i]] 15]
            lappend tempdistpos [lindex [lindex $line [lindex $index $i]] 1]
        }
        $QWIKMD::tempDistGui clear
        $QWIKMD::tempDistGui add $tempdistpos $tempdistval
        $QWIKMD::tempDistGui replot
        unset line
    }
}

proc QWIKMD::MBCalC {} {
    set title "kinetic Energy vs Atom Index"
    set ylab "Energy\n(kcal/mol)"
    set xlab "Atom Index"
    if {$QWIKMD::MBGui == ""} {
        set info [QWIKMD::addplot mb "MB Distribution" $title $xlab $ylab]
        set QWIKMD::MBGui [lindex $info 0]

        set clear [lindex $info 1]
        set close [lindex $info 2]
        
        $clear entryconfigure 0 -command {
            $QWIKMD::MBGui clear
            $QWIKMD::MBGui add 0 0
            $QWIKMD::MBGui replot
        }

        $close entryconfigure 0 -command {
            $QWIKMD::MBGui quit
            destroy $QWIKMD::advGui(analyze,advance,ntb).mb
            set QWIKMD::MBGui ""
        }
        set QWIKMD::actempGui ""
    } else {
        $QWIKMD::MBGui clear
        $QWIKMD::MBGui add 0 0
        $QWIKMD::MBGui replot
    } 

    if {$QWIKMD::load == 1} {
        set file "${QWIKMD::radiobtt}.restart.vel"
        if {[file exists $file] !=1} {
            break
        }
        set mol [mol new [lindex $QWIKMD::inputstrct 0]]
        mol addfile $file type namdbin
        set mbpos ""
        set mbval ""
        set all [atomselect top $QWIKMD::advGui(analyze,advance,MBsel)]
        foreach m [$all get mass] v [$all get {x y z}] index [$all get index] {
            lappend mbval [expr 0.5 * $m * [vecdot $v $v] ]
            lappend mbpos $index
        }

        $QWIKMD::MBGui clear
        $QWIKMD::MBGui configure -nolines -raius 5 
        $QWIKMD::MBGui add $mbpos $mbval
        $QWIKMD::MBGui replot
        mol delete $mol
    }


}

proc QWIKMD::QTempCalc {} {
    set title "Temperature vs Time"
    set ylab "Temp (K)"
    set xlab "Time (fs)"
    if {$QWIKMD::qtempGui == ""} {
        set info [QWIKMD::addplot tquench "Temperature Quench" $title $xlab $ylab]
        set QWIKMD::qtempGui [lindex $info 0]

        set clear [lindex $info 1]
        set close [lindex $info 2]
        
        $clear entryconfigure 0 -command {
            $QWIKMD::qtempGui clear
            set QWIKMD::qtemppos ""
            set QWIKMD::qtempval ""
            $QWIKMD::qtempGui add 0 0
            $QWIKMD::qtempGui replot
        }

        $close entryconfigure 0 -command {
            $QWIKMD::qtempGui quit
            destroy $QWIKMD::advGui(analyze,advance,ntb).tquench
            set QWIKMD::qtempGui ""
            set QWIKMD::qtemppos ""
            set QWIKMD::qtempval ""
        }
        set QWIKMD::actempGui ""
    } else {
        $QWIKMD::qtempGui clear
        set QWIKMD::qtemppos ""
        set QWIKMD::qtempval ""
        $QWIKMD::qtempGui add 0 0
        $QWIKMD::qtempGui replot
    } 

    set title "Temperature Autocorrelation Function"
    set ylab "C T,T"
    set xlab "Time (fs)"
    if {$QWIKMD::actempGui == ""} {
        set info [QWIKMD::addplot actquench "Temperature AC" $title $xlab $ylab]
        set QWIKMD::actempGui [lindex $info 0]

        set clear [lindex $info 1]
        set close [lindex $info 2]
        
        $clear entryconfigure 0 -command {
            $QWIKMD::actempGui clear
        set QWIKMD::acqtemppos ""
        set QWIKMD::acqtempval ""
        $QWIKMD::actempGui add 0 0
        $QWIKMD::actempGui replot
        }

        $close entryconfigure 0 -command {
            destroy $QWIKMD::advGui(analyze,advance,ntb).actquench
            set QWIKMD::actempGui ""
            set QWIKMD::acqtemppos ""
            set QWIKMD::acqtempval ""
        }

    } else {
        $QWIKMD::actempGui clear
        set QWIKMD::acqtemppos ""
        set QWIKMD::acqtempval ""
        $QWIKMD::actempGui add 0 0
        $QWIKMD::actempGui replot
    }

    if {$QWIKMD::load == 1} {
        set QWIKMD::qtemprevx 0
        set QWIKMD::qtemppos ""
        set QWIKMD::qtempval ""
        set energyfreq 1
        set const 1
        set countdo 0
        for {set i 0} {$i < [llength $QWIKMD::confFile]} {incr i} {
            set tps 0
            set tblwindw [$QWIKMD::advGui(analyze,advance,qtmeptbl) windowpath $i,0]
            set do 0
            if {[$tblwindw.r state !selected] == "selected"} {
                set do 1
                incr countdo
                $tblwindw.r state selected
            } else {
                set do 0
                $tblwindw.r state !selected
            }

            if {$do == 1} {
                set file "[lindex $QWIKMD::confFile $i].log"
                if {[file exists $file] !=1} {
                    break
                }
                set logfile [open $file r]
                set lineprev ""

                while {[eof $logfile] != 1 } {
                    set line [gets $logfile]
                    if {[lindex $line 0] == "Info:" && [lindex $line 1] == "TIMESTEP"} {
                        set aux [lindex $line 2]
                        set const $aux 
                    }
                    if {[lindex $line 0] == "Info:" && [join [lrange $line 1 3]] == "ENERGY OUTPUT STEPS" } {
                        set energyfreq [lindex $line 4]
                    }
                    if {[lindex $line 0] == "ENERGY:"} {
                        lappend QWIKMD::qtempval [lindex $line 15]  
                        lappend QWIKMD::qtemppos [expr {$tps * $energyfreq * $const} + $QWIKMD::qtemprevx]
                        incr tps
                    } 
                }
                close $logfile
                $QWIKMD::advGui(analyze,advance,qtmeptbl) cellconfigure $i,2 -text [expr $tps -1]
                set QWIKMD::qtemprevx [lindex $QWIKMD::qtemppos end]
            
                if {$countdo == 1} {
                    set previndex [lsearch $QWIKMD::prevconfFile [lindex $QWIKMD::confFile $i]]
                    if {$previndex < 0} {
                        set previndex 0
                    }
                    set QWIKMD::advGui(analyze,advance,tempentry) [$QWIKMD::advGui(protocoltb,$QWIKMD::run) cellcget $previndex,4 -text]

                    set QWIKMD::acqtemppos ""
                    set QWIKMD::acqtempval ""
                    set endlag 25
                    set lc [llength $QWIKMD::qtempval]
                    set temper ""
                    set avg_temp [QWIKMD::mean $QWIKMD::qtempval]
                    set temper_adj ""
                    set data1 ""
                    set data2 ""
                    set data2sq ""
                    set dataprod ""
                    for {set k 0} {$k < $lc} {incr k} {
                        lappend temper_adj [expr [lindex $QWIKMD::qtempval $k] - $avg_temp]
                        lappend data1 0.0
                        lappend data2 0.0
                        lappend data2sq 0.0
                        lappend dataprod 0.0 
                    }

                    for {set lag 0} {$lag <= $endlag} {incr lag} {
                        
                        for {set k 0} {$k < [expr $lc-$lag]} {incr k} {
                            lset data1 $k [lindex $temper_adj $k]
                            lset data2 $k [lindex $temper_adj [expr $k+$lag]]
                            lset data2sq $k [expr [lindex $data2 $k] * [lindex $data2 $k]]
                            lset dataprod $k [expr [lindex $data1 $k] * [lindex $data2 $k]]

                        }
                        set mean1 [QWIKMD::mean $data1]
                        set mean2 [QWIKMD::mean $data2sq]
                        set meanprod [QWIKMD::mean $dataprod]
                        # Calculate the Autocorrelation Function
                        lappend QWIKMD::acqtemppos $lag
                        lappend QWIKMD::acqtempval [expr ($meanprod - $mean1*$mean1)/($mean2 - $mean1*$mean1)]
                    }
                    $QWIKMD::actempGui clear
                    $QWIKMD::actempGui add $QWIKMD::acqtemppos $QWIKMD::acqtempval
                    $QWIKMD::actempGui replot
                } 
            }
        }

        $QWIKMD::qtempGui clear
        $QWIKMD::qtempGui add $QWIKMD::qtemppos $QWIKMD::qtempval
        $QWIKMD::qtempGui replot
        set QWIKMD::qtemprevx [lindex $QWIKMD::qtemppos end]

    } 
    
}
proc QWIKMD::QFindEcho {} {
    set last 0
    for {set i 0} {$i < [llength $QWIKMD::confFile]} {incr i} {
        set tps 0
        set tblwindw [$QWIKMD::advGui(analyze,advance,qtmeptbl) windowpath $i,0]
        set do 0
        if {[$tblwindw.r state !selected] == "selected"} {
            set do 1
            set last $i
            incr countdo
            $tblwindw.r state selected
        } else {
            set do 0
            $tblwindw.r state !selected
        }
    }
    set prevtime [$QWIKMD::advGui(analyze,advance,qtmeptbl) cellcget $last,2 -text]
    set lastquench [expr [llength $QWIKMD::qtempval] - $prevtime]
    set min [expr $lastquench +10]
    set depth [QWIKMD::mincalc [lrange $QWIKMD::qtempval $min end]]
    set avg [QWIKMD::mean [lrange $QWIKMD::qtempval $min end]]
    $QWIKMD::advGui(analyze,advance,echolb) configure -text "[format %.3f [expr $avg - $depth]] K"
    set time [lindex $QWIKMD::qtemppos [lsearch $QWIKMD::qtempval $depth]]
    $QWIKMD::advGui(analyze,advance,echotime) configure -text "[format %.3f $time] fs"

    set tau [$QWIKMD::advGui(analyze,advance,qtmeptbl) cellcget [expr $last -1],2 -text]
    set tau0 $QWIKMD::advGui(analyze,advance,decayentry)    ;# autocorrelation decay time
    set T0 [expr $QWIKMD::advGui(analyze,advance,tempentry) + 273]  ;# initial temperature
    set T1 0    ;# first temperature reassignment
    set T2 0    ;# sedcond temperature reassignment
    set lambda1 [expr sqrt($T1/$T0)]
    set lambda2 [expr sqrt($T2/$T0)]

    set y1 [expr (1 + pow($lambda1,2) + 2*pow($lambda2,2)) / 4]


    set length [llength $QWIKMD::qtemppos]
    set x [list]
    set y [list]
    for {set t $tau} {$t < [expr $tau + $prevtime]} {incr t} {
      set y2 [expr (1 + pow($lambda1,2) - 2*pow($lambda2,2)) / 4 * [expr exp(-($t-$tau)/$tau0)]]
      set y3 [expr $lambda1*$lambda2/2 * [expr exp(-abs($t-3*$tau/2)/$tau0)]]
      set y4 [expr (1 - pow($lambda1,2)) / 8 * [expr exp(-abs($t-2*$tau)/$tau0)]]
      lappend x [expr $lastquench -1 + $t - $tau] 
      lappend y [expr $T0*($y1-$y2-$y3-$y4)]
    }
    $QWIKMD::qtempGui clear
    $QWIKMD::qtempGui add $QWIKMD::qtemppos $QWIKMD::qtempval
    $QWIKMD::qtempGui add $x $y
    $QWIKMD::qtempGui replot
}

proc QWIKMD::callhbondsCalcProc {} {
    #set plot 0
     if {$QWIKMD::hbondsGui == ""} {
        #set plot 1
        set xlab "Time (ns)"
        if {$QWIKMD::run == "QM/MM"} {
            set xlab "Time (ps)"
        }
        set info [QWIKMD::addplot fhbonds "HBonds Plot" "HBonds vs Time" $xlab "No. HBonds"]
        set QWIKMD::hbondsGui [lindex $info 0]

        set clear [lindex $info 1]
        set close [lindex $info 2]
        
        $clear entryconfigure 0 -command {
            if {$QWIKMD::hbondsrepname != ""} {
                mol delrep [QWIKMD::getrepnum $QWIKMD::hbondsrepname $QWIKMD::topMol] $QWIKMD::topMol
                set QWIKMD::hbondsrepname ""
            }
            $QWIKMD::hbondsGui clear
            set QWIKMD::timeXhbonds ""
            set QWIKMD::hbonds ""
            $QWIKMD::hbondsGui add 0 0
            $QWIKMD::hbondsGui replot
        }

        $close entryconfigure 0 -command {
            if {$QWIKMD::hbondsrepname != ""} {
                mol delrep [QWIKMD::getrepnum $QWIKMD::hbondsrepname $QWIKMD::topMol] $QWIKMD::topMol
                set QWIKMD::hbondsrepname ""
            }
            $QWIKMD::hbondsGui quit
            destroy $QWIKMD::advGui(analyze,advance,ntb).fhbonds
            set QWIKMD::hbondsGui ""
        }

    } else {
        $QWIKMD::hbondsGui clear
        set QWIKMD::timeXhbonds ""
        set QWIKMD::hbonds ""
        $QWIKMD::hbondsGui add 0 0
        $QWIKMD::hbondsGui replot
    } 
    if {$QWIKMD::hbondssel == "sel" && ($QWIKMD::advGui(analyze,advance,hbondsel1entry) == "Type Selection" || $QWIKMD::advGui(analyze,advance,hbondsel1entry) == "")} {
        mol delrep [QWIKMD::getrepnum $QWIKMD::hbondsrepname $QWIKMD::topMol] $QWIKMD::topMol
        set QWIKMD::hbondsrepname ""
        return
    }
    if {$QWIKMD::load == 1} {
        set numframes [molinfo $QWIKMD::topMol get numframes]
        
        set j 0
        set hbonds 0
        set const 2e-6 
        set do 1
        set increment [expr $const * [expr $QWIKMD::dcdfreq * $QWIKMD::loadstride] ] 
        set xtime 0
        for {set i 0} {$i < $numframes} {incr i} {
            if {$i < [lindex $QWIKMD::lastframe $j]} {
                if {$do == 1} {
                    set logfile [open [lindex $QWIKMD::confFile $j].log r]
                    while {[eof $logfile] != 1 } {
                        set line [gets $logfile]

                        if {[lindex $line 0] == "Info:" && [lindex $line 1] == "TIMESTEP"} {
                            set const [expr [lindex $line 2] * 1e-6]
                            if {$QWIKMD::run == "QM/MM"} {
                                set const [expr $const * 1e3]
                            }
                        }

                        if {[lindex $line 0] == "Info:" && [join [lrange $line 1 2]] == "DCD FREQUENCY" } {
                            set QWIKMD::dcdfreq [lindex $line 3]
                            break
                        }
                    }
                    close $logfile
                    set do 0
                    set increment [expr $const * [expr $QWIKMD::dcdfreq * $QWIKMD::loadstride] ]
                }   
            } else {
                incr j
                set do 1
            }
            if {$i > 0}  {
                set xtime [expr [lindex $QWIKMD::timeXhbonds end] + $increment]
            }
            lappend QWIKMD::timeXhbonds $xtime
            lappend QWIKMD::hbonds [QWIKMD::hbondsCalcProc $i]
    
        }
        
        QWIKMD::representHbonds
        
        set QWIKMD::hbondsprevx [lindex $QWIKMD::timeXhbonds end]
        if {[file channels $QWIKMD::textLogfile] == $QWIKMD::textLogfile && $QWIKMD::textLogfile != ""} {
            puts $QWIKMD::textLogfile [QWIKMD::printHbonds $numframes]
            flush $QWIKMD::textLogfile
        } 
    } elseif {$QWIKMD::load == 0} {
        QWIKMD::HbondsCalc
    }
}

proc QWIKMD::hbondsCalcProc {frame} {
    set atmsel1 ""
    set atmsel2 ""
    set polar "(name \"N.*\" \"O.*\" \"S.*\" FA F1 F2 F3)"
    if {$QWIKMD::hbondssel == "inter" || $QWIKMD::hbondssel == "intra"} {
        set sel "all and not water and not ions and $polar"
        set atmsel1 [atomselect $QWIKMD::topMol $sel frame $frame]      
    } 
    
    if {$QWIKMD::hbondssel == "inter"} {
        set sel "water"
        set atmsel2 [atomselect $QWIKMD::topMol $sel frame $frame]
    
    } elseif {$QWIKMD::hbondssel == "sel"} {
        set atmsel1 [atomselect $QWIKMD::topMol "$QWIKMD::advGui(analyze,advance,hbondsel1entry) and $polar" frame $frame]
        if {$QWIKMD::advGui(analyze,advance,hbondsel2entry) != "Type Selection" } {
            set atmsel2 [atomselect $QWIKMD::topMol "$QWIKMD::advGui(analyze,advance,hbondsel2entry) and $polar" frame $frame]
        }
        
    }
    set hbonds -1
    if {[$atmsel1 get index] != ""} {   
        if {$atmsel2 == ""} {
            set hbonds [llength [lindex [measure hbonds 3.5 30 $atmsel1] 0]]
        } else {
            set hbonds [llength [lindex [measure hbonds 3.5 30 $atmsel1 $atmsel2] 0] ]
            set hbonds [expr $hbonds + [llength [lindex [measure hbonds 3.5 30 $atmsel2 $atmsel1] 0] ]]
            $atmsel2 delete
        }
        $atmsel1 delete
    }
    return $hbonds
}

proc QWIKMD::representHbonds {} {
    set sel1 "all and not water and not ions and (name \"N.*\" \"O.*\" \"S.*\" FA F1 F2 F3)"
    if {$QWIKMD::hbondssel == "inter"} {
        set sel2 "water"
    }
    set selrep $sel1
    if {$QWIKMD::hbondssel == "inter"} {
        append selrep " or water"
    }
    if {$QWIKMD::hbondsrepname != ""} {
        mol delrep [QWIKMD::getrepnum $QWIKMD::hbondsrepname $QWIKMD::topMol] $QWIKMD::topMol
        set QWIKMD::hbondsrepname ""
    }
    
    if {$QWIKMD::hbondssel == "intra"} {
        mol representation HBonds 3.5 30 10
        mol color Name
        mol selection $selrep
        mol material Opaque
        mol addrep $QWIKMD::topMol
        set QWIKMD::hbondsrepname [mol repname $QWIKMD::topMol [expr [molinfo $QWIKMD::topMol get numreps] -1] ]
    }
    
    $QWIKMD::hbondsGui clear
    $QWIKMD::hbondsGui add $QWIKMD::timeXhbonds $QWIKMD::hbonds
    $QWIKMD::hbondsGui replot
}

proc QWIKMD::HbondsCalc {} {
    set prefix ""
        
    set hbonds [QWIKMD::hbondsCalcProc [molinfo $QWIKMD::topMol get frame]]
    if {$hbonds != -1} {    
        set const [expr $QWIKMD::timestep * 1e-6]
        if {$QWIKMD::run == "QM/MM"} {
            set const [expr $const * 1e3]
        }
        lappend QWIKMD::timeXhbonds [expr {$const * $QWIKMD::counterts * $QWIKMD::imdFreq} + $QWIKMD::hbondsprevx]
        lappend QWIKMD::hbonds $hbonds
        
        QWIKMD::representHbonds
        
    } else {
        tk_messageBox -message "Atom selection is not valid." -title "Hbonds Calculation" -icon info \
        -type ok -parent $QWIKMD::topGui
    }
}

proc QWIKMD::SmdCalc {} {
    if {$QWIKMD::run != "SMD"} {
        return
    }
    set do 0
    set index [expr $QWIKMD::state -1 ]
    set file "[lindex $QWIKMD::confFile $index].log"
    set tabid [lindex [lindex $QWIKMD::selnotbooks 0] 1]
    if {$tabid == 0} {
        if {[file exists $file] ==1 && [string match "*smd*" [lindex  $QWIKMD::confFile $index ] ] > 0} {
            set do 1
        }
        
    } else {
        if {$QWIKMD::advGui(protocoltb,$QWIKMD::run,$index,smd) == 1 && [file exists $file] ==1} {
            set do 1
        }
    }
    if {$do ==1} {

        set prefix ""               
        set timeX "0"
        set const [expr $QWIKMD::timestep * 1e-6]
        set logfile [open $file r]
        seek $logfile $QWIKMD::smdcurrentpos
        set dist ""
        set time ""
        set limit [expr $QWIKMD::calcfreq * $QWIKMD::imdFreq]

        while {[eof $logfile] != 1 } {
            set line [gets $logfile]
            if {[lindex $line 0] == "SMD" && [lindex $line 1] != 0 && [lindex $line 1] > $QWIKMD::smdprevindex} {
                lappend  QWIKMD::smdvals [lindex $line 7]
                set time [lindex $line 1]
                if {$QWIKMD::smdxunit != "time"} {
                    set dist [lindex $line 4]
                    if {$QWIKMD::smdfirstdist == ""} {
                        set QWIKMD::smdfirstdist $dist
                    }
                }
                if {[expr $time - $QWIKMD::smdprevindex] >= $limit} {
                    set min 0
                    if {[llength $QWIKMD::smdvalsavg] > 1} {
                        set min [expr int([expr [llength $QWIKMD::smdvals] - [expr 1.5 * $QWIKMD::imdFreq] -1])]  
                    }
                    set max [expr [llength $QWIKMD::smdvals] -1]
                    lappend QWIKMD::smdvalsavg [QWIKMD::mean [lrange $QWIKMD::smdvals $min $max]]
                    if {$QWIKMD::smdxunit == "time"} {
                        lappend QWIKMD::timeXsmd [expr $const * $time]
                    } else {
                        lappend QWIKMD::timeXsmd [expr $dist - $QWIKMD::smdfirstdist]
                    }
                    set QWIKMD::smdprevindex $time
                    set QWIKMD::smdcurrentpos [tell $logfile ]
                    close $logfile      
                    $QWIKMD::smdGui clear
                    $QWIKMD::smdGui add $QWIKMD::timeXsmd $QWIKMD::smdvalsavg
                    $QWIKMD::smdGui replot   
                    break
                }
            }
        }           
    }
}

proc QWIKMD::callSmdCalc {} {
    
    if {$QWIKMD::smdGui == ""} {
        set title "AVG Force vs Time"
        set xlab "Time (ns)"
        if {$QWIKMD::smdxunit == "distance"} {
            set title "AVG Force vs Distance"
            set xlab "Distance (A)"
        }
        set info [QWIKMD::addplot smd "SMD Plot" $title $xlab "Force (pN)"]
        set QWIKMD::smdGui [lindex $info 0]

        set clear [lindex $info 1]
        set close [lindex $info 2]
        
        $clear entryconfigure 0 -command {
            $QWIKMD::smdGui clear
            set QWIKMD::timeXsmd ""
            set QWIKMD::smdvals ""
            set QWIKMD::smdvalsavg ""
            set QWIKMD::smdfirstdist ""
            $QWIKMD::smdGui add 0 0
            $QWIKMD::smdGui replot
        }

        $close entryconfigure 0 -command {

            destroy $QWIKMD::advGui(analyze,advance,ntb).smd
            $QWIKMD::smdGui quit
            set QWIKMD::smdGui ""
        }

    } else {
        $QWIKMD::smdGui clear
        set QWIKMD::timeXsmd ""
        set QWIKMD::smdvals ""
        set QWIKMD::smdvalsavg ""
        set QWIKMD::smdfirstdist ""
        $QWIKMD::smdGui add 0 0
        $QWIKMD::smdGui replot
    } 
    if {$QWIKMD::load == 1 && $QWIKMD::run == "SMD"} {
        set j 0
        set QWIKMD::smdprevx 0
        set QWIKMD::smdprevindex 0
        set findfirst 1
        set firstdistance 0
        for {set i 0} {$i < [llength $QWIKMD::confFile]} {incr i} {
            set do 0
            set file "[lindex  $QWIKMD::confFile $i].log"
            set tabid [lindex [lindex $QWIKMD::selnotbooks 0] 1]
            if {$tabid == 0} {
                if {[file exists $file] ==1 && [string match "*smd*" $file ] > 0} {
                    set do 1
                }
                
            } else {
                set confIndex [lsearch $QWIKMD::prevconfFile [lindex  $QWIKMD::confFile $i]]
                if {$QWIKMD::advGui(protocoltb,$QWIKMD::run,$confIndex,smd) == 1 && [file exists $file] ==1} {
                    set do 1
                }   
            }
            if {$do == 1} {
                set prefix ""               
                
                set const 2e-6

                set logfile [open $file r]
                set dist ""
                set time ""
                set const 0
                set limit [expr $QWIKMD::calcfreq * $QWIKMD::imdFreq]
                set smdfreq 0
                set tstepaux 0
                set index 0
                set window 10
                while {[eof $logfile] != 1 } {
                    set line [gets $logfile]
                    if {[lindex $line 0] == "Info:" && [lindex $line 1] == "TIMESTEP"} {
                        set aux [lindex $line 2]
                        set const [expr $aux * 1e-6] 
                        set tstepaux 0
                    }
            
                    if {[lindex $line 0] == "Info:" && [join [lrange $line 1 3]] == "SMD OUTPUT FREQUENCY" } {
                        set smdfreq [lindex $line 4]
                        set tabid [lindex [lindex $QWIKMD::selnotbooks 0] 1]
                        if {$QWIKMD::basicGui(live,$tabid) == 0} {
                            set limit [expr $smdfreq * $window] 
                        }
                    }
                    if {[lindex $line 0] == "SMD" && [lindex $line 1] != 0 } {
                        lappend  QWIKMD::smdvals [lindex $line 7]
                
                        if {$QWIKMD::smdxunit == "time"} {
                            set time [lindex $line 1]
                            
                        } else {
                            set dist [lindex $line 4]
                            if {$findfirst == 1} {
                                set firstdistance $dist
                                set findfirst 0
                            }
                        }
                        incr tstepaux $smdfreq
                        incr index $smdfreq
                        if {[expr $tstepaux % $limit] == 0 && $index != $QWIKMD::smdprevindex} {
                            set min 0
                            if {[llength $QWIKMD::smdvalsavg] > 1} {
                                set min [expr int([expr [llength $QWIKMD::smdvals] - [expr 1.5 * $window] -1])]  
                            }
                            set max [expr [llength $QWIKMD::smdvals] -1]
                            lappend QWIKMD::smdvalsavg [QWIKMD::mean [lrange $QWIKMD::smdvals $min $max]]
                            if {$QWIKMD::smdxunit == "time"} {
                                lappend QWIKMD::timeXsmd [expr $const * $time]
                            } else {
                                lappend QWIKMD::timeXsmd [expr $dist - $firstdistance]
                            }
                            set QWIKMD::smdprevx [lindex $QWIKMD::timeXsmd end]
                        
                        }
                     }
                }
                if {[file channels $QWIKMD::textLogfile] == $QWIKMD::textLogfile && $QWIKMD::textLogfile != ""} {
                    puts $QWIKMD::textLogfile [QWIKMD::printSMD $QWIKMD::smdprevx $dist $limit [expr 1.5 * $window] $smdfreq $const]
                    flush $QWIKMD::textLogfile 
                }
                close $logfile      
            }
            
        }
        $QWIKMD::smdGui clear
        $QWIKMD::smdGui add $QWIKMD::timeXsmd $QWIKMD::smdvalsavg
        $QWIKMD::smdGui replot

    } 
    
}


proc QWIKMD::CallTimeLine {} {
    
    menu timeline on
}

proc QWIKMD::AddMBBox {} {
    display resetview
    set sel [atomselect $QWIKMD::topMol "all and not water and not ion"]

    set center [measure center $sel]
    set QWIKMD::advGui(membrane,center,x) [lindex $center 0]
    set QWIKMD::advGui(membrane,center,y) [lindex $center 1]
    set QWIKMD::advGui(membrane,center,z) [lindex $center 2]
    set QWIKMD::advGui(membrane,rotationMaxtrixList) [list]
    $sel delete

    set QWIKMD::advGui(membrane,rotate,x) 0
    set QWIKMD::advGui(membrane,rotate,y) 0
    set QWIKMD::advGui(membrane,rotate,z) 0

    set QWIKMD::advGui(membrane,centerxoffset) 0
    set QWIKMD::advGui(membrane,centeryoffset) 0

    set QWIKMD::advGui(membrane,trans,x) 0
    set QWIKMD::advGui(membrane,trans,y) 0
    set QWIKMD::advGui(membrane,trans,z) 0

    QWIKMD::updateMembraneBox $center
}

proc QWIKMD::updateMembraneBox {center} {
    # if {[llength $QWIKMD::advGui(membrane,rotationMaxtrixList)] > 0} {
    #   set center [list $QWIKMD::advGui(membrane,center,x) $QWIKMD::advGui(membrane,center,y) $QWIKMD::advGui(membrane,center,z)]
    #   set centermover [transoffset [vecscale $center -1]]
    #   set centerback [transoffset $center]
    #   set i 0
    #   foreach coor $QWIKMD::advGui(membrane,boxedges) {
    #       set coor [coordtrans $centermover $coor]
    #       set matrix ""
    #       if {[llength $QWIKMD::advGui(membrane,rotationMaxtrixList)] > 1} {
    #           set matrix [eval transmult [lreverse $QWIKMD::advGui(membrane,rotationMaxtrixList)]]
    #       } else {
    #           set matrix [join $QWIKMD::advGui(membrane,rotationMaxtrixList)]
    #       }
    #       set coor [vectrans [measure inverse $matrix] $coor]
    #       lset QWIKMD::advGui(membrane,boxedges) $i [coordtrans $centerback $coor]
    #       incr i
    #   }
    # }
    set boxW [expr $QWIKMD::advGui(membrane,xsize)/2]
    set boxH [expr $QWIKMD::advGui(membrane,ysize)/2]
    ###Z box dimension from the average of the phosphorus atoms in the membrane popc36_box.pdb and popec36_box.pdb
    set zsize 0.0 ; #(0,0,0)
    if {$QWIKMD::advGui(membrane,lipid) == "POPC"} {
        set zsize 39.0
    } else {
        set zsize 39.4
    }
    set boxD [expr $zsize/2]
    # set QWIKMD::advGui(membrane,xmin) [expr [lindex $center 0]-($boxW) + $QWIKMD::advGui(membrane,centerxoffset)]
    # set QWIKMD::advGui(membrane,xmax) [expr [lindex $center 0]+($boxW) + $QWIKMD::advGui(membrane,centerxoffset)]

    # set QWIKMD::advGui(membrane,ymin) [expr [lindex $center 1]-($boxH) + $QWIKMD::advGui(membrane,centeryoffset)]
    # set QWIKMD::advGui(membrane,ymax) [expr [lindex $center 1]+($boxH) + $QWIKMD::advGui(membrane,centeryoffset)]

    set QWIKMD::advGui(membrane,xmin) [expr [lindex $center 0]-($boxW)]
    set QWIKMD::advGui(membrane,xmax) [expr [lindex $center 0]+($boxW)]

    set QWIKMD::advGui(membrane,ymin) [expr [lindex $center 1]-($boxH)]
    set QWIKMD::advGui(membrane,ymax) [expr [lindex $center 1]+($boxH)]

    set QWIKMD::advGui(membrane,zmin) [expr [lindex $center 2]-($boxD)]
    set QWIKMD::advGui(membrane,zmax) [expr [lindex $center 2]+($boxD)]
    set QWIKMD::advGui(membrane,boxedges) [list]
    lappend QWIKMD::advGui(membrane,boxedges) [list $QWIKMD::advGui(membrane,xmin) $QWIKMD::advGui(membrane,ymin) $QWIKMD::advGui(membrane,zmin)]; #(0,0,0) 0
    lappend QWIKMD::advGui(membrane,boxedges) [list $QWIKMD::advGui(membrane,xmin) $QWIKMD::advGui(membrane,ymin) $QWIKMD::advGui(membrane,zmax)]; #(0,0,1) 1
    lappend QWIKMD::advGui(membrane,boxedges) [list $QWIKMD::advGui(membrane,xmin) $QWIKMD::advGui(membrane,ymax) $QWIKMD::advGui(membrane,zmax)]; #(0,1,1) 2
    lappend QWIKMD::advGui(membrane,boxedges) [list $QWIKMD::advGui(membrane,xmax) $QWIKMD::advGui(membrane,ymax) $QWIKMD::advGui(membrane,zmax)]; #(1,1,1) 3
    lappend QWIKMD::advGui(membrane,boxedges) [list $QWIKMD::advGui(membrane,xmin) $QWIKMD::advGui(membrane,ymax) $QWIKMD::advGui(membrane,zmin)]; #(0,1,0) 4
    lappend QWIKMD::advGui(membrane,boxedges) [list $QWIKMD::advGui(membrane,xmax) $QWIKMD::advGui(membrane,ymin) $QWIKMD::advGui(membrane,zmin)]; #(1,0,0) 5
    lappend QWIKMD::advGui(membrane,boxedges) [list $QWIKMD::advGui(membrane,xmax) $QWIKMD::advGui(membrane,ymax) $QWIKMD::advGui(membrane,zmin)]; #(1,1,0) 6
    lappend QWIKMD::advGui(membrane,boxedges) [list $QWIKMD::advGui(membrane,xmax) $QWIKMD::advGui(membrane,ymin) $QWIKMD::advGui(membrane,zmax)]; #(1,0,1) 7
    


    #update box with dimensions and membrane thickness 
    set i 0
    if {[llength $QWIKMD::advGui(membrane,rotationMaxtrixList)] > 0} {
        set center [list $QWIKMD::advGui(membrane,center,x) $QWIKMD::advGui(membrane,center,y) $QWIKMD::advGui(membrane,center,z)]
        set newcenter [list $QWIKMD::advGui(membrane,centerxoffset) $QWIKMD::advGui(membrane,centeryoffset) 0]
        set centermover [transoffset [vecsub {0 0 0} $center]]
        
        set centerback [transoffset [vecsub $center {0 0 0}]]
        set centermovenew ""
        
        foreach coor $QWIKMD::advGui(membrane,boxedges) {
            set coor [coordtrans $centermover $coor]
            set matrix ""
            if {[llength $QWIKMD::advGui(membrane,rotationMaxtrixList)] > 1} {
                set matrix [eval transmult [lreverse $QWIKMD::advGui(membrane,rotationMaxtrixList)]]
            } else {
                set matrix [join $QWIKMD::advGui(membrane,rotationMaxtrixList)]
            }

            if {$i == 0 && ($QWIKMD::advGui(membrane,centerxoffset) != 0 || $QWIKMD::advGui(membrane,centeryoffset) != 0)} {
                set newcenter [vectrans $matrix $newcenter]
                set newcenter [coordtrans $centerback $newcenter]
                set centermovenew [transoffset [vecsub $newcenter $center]]
                set newcenter [coordtrans $centermovenew $center]
            } 
            set coor [vectrans $matrix $coor]
            set coor [coordtrans $centerback $coor]
            if {$QWIKMD::advGui(membrane,centerxoffset) != 0 || $QWIKMD::advGui(membrane,centeryoffset) != 0} {
                set coor [coordtrans $centermovenew $coor]
            }
            lset QWIKMD::advGui(membrane,boxedges) $i $coor
            incr i
        }
        if {$QWIKMD::advGui(membrane,centerxoffset) != 0 || $QWIKMD::advGui(membrane,centeryoffset) != 0} {

            set QWIKMD::advGui(membrane,center,x) [lindex $newcenter 0]
            set QWIKMD::advGui(membrane,center,y) [lindex $newcenter 1]
            set QWIKMD::advGui(membrane,center,z) [lindex $newcenter 2]
        }
    }
    set QWIKMD::advGui(membrane,centerxoffset) 0
    set QWIKMD::advGui(membrane,centeryoffset) 0
    QWIKMD::DrawBox
}
proc QWIKMD::DrawBox {} {
    
    foreach point $QWIKMD::membranebox {
        graphics $QWIKMD::topMol delete $point  
    }
    set QWIKMD::membranebox [list]
    set width 4

    # box vertices 
    #(0,0,0) 0
    #(0,0,1) 1
    #(0,1,1) 2
    #(1,1,1) 3
    #(0,1,0) 4
    #(1,0,0) 5
    #(1,1,0) 6
    #(1,0,1) 7

    ##### x0(0,0,0) - x1(1,0,0)
    graphics $QWIKMD::topMol color red
    lappend QWIKMD::membranebox [graphics $QWIKMD::topMol line [lindex $QWIKMD::advGui(membrane,boxedges) 0] [lindex $QWIKMD::advGui(membrane,boxedges) 5] width $width ]

    ##### y0(0,0,0) - y1(0,1,0)
    graphics $QWIKMD::topMol color green
    lappend QWIKMD::membranebox [graphics $QWIKMD::topMol line [lindex $QWIKMD::advGui(membrane,boxedges) 0] [lindex $QWIKMD::advGui(membrane,boxedges) 4] width $width ]
    
    ##### z0(0,0,0) - z1(0,0,1)
    graphics $QWIKMD::topMol color blue
    lappend QWIKMD::membranebox [graphics $QWIKMD::topMol line [lindex $QWIKMD::advGui(membrane,boxedges) 0] [lindex $QWIKMD::advGui(membrane,boxedges) 1] width $width ]

    graphics $QWIKMD::topMol color yellow

    incr width -1

    ##### (1,0,0) - (1,0,1)
    lappend QWIKMD::membranebox [graphics $QWIKMD::topMol line [lindex $QWIKMD::advGui(membrane,boxedges) 5] [lindex $QWIKMD::advGui(membrane,boxedges) 7] width $width]

    ##### (1,0,1) -  (0,0,1)
    lappend QWIKMD::membranebox [graphics $QWIKMD::topMol line [lindex $QWIKMD::advGui(membrane,boxedges) 7] [lindex $QWIKMD::advGui(membrane,boxedges) 1] width $width]

    ##### (0,1,0) -  (0,1,1)
    lappend QWIKMD::membranebox [graphics $QWIKMD::topMol line [lindex $QWIKMD::advGui(membrane,boxedges) 4] [lindex $QWIKMD::advGui(membrane,boxedges) 2] width $width]

    ##### (0,1,1) - (0,1,1)
    lappend QWIKMD::membranebox [graphics $QWIKMD::topMol line [lindex $QWIKMD::advGui(membrane,boxedges) 2] [lindex $QWIKMD::advGui(membrane,boxedges) 1] width $width]


    ##### (0,1,1) - (0,0,1)
    lappend QWIKMD::membranebox [graphics $QWIKMD::topMol line [lindex $QWIKMD::advGui(membrane,boxedges) 2] [lindex $QWIKMD::advGui(membrane,boxedges) 3] width $width]

    ##### (1,0,1) - (1,1,1)
    lappend QWIKMD::membranebox [graphics $QWIKMD::topMol line [lindex $QWIKMD::advGui(membrane,boxedges) 7] [lindex $QWIKMD::advGui(membrane,boxedges) 3] width $width]

    ##### (1,1,1) - (1,1,0)
    lappend QWIKMD::membranebox [graphics $QWIKMD::topMol line [lindex $QWIKMD::advGui(membrane,boxedges) 3] [lindex $QWIKMD::advGui(membrane,boxedges) 6] width $width]

    ##### (1,1,0) - (0,1,0)
    lappend QWIKMD::membranebox [graphics $QWIKMD::topMol line [lindex $QWIKMD::advGui(membrane,boxedges) 6] [lindex $QWIKMD::advGui(membrane,boxedges) 4] width $width]

    ##### (1,1,0) - (1,0,0)
    lappend QWIKMD::membranebox [graphics $QWIKMD::topMol line [lindex $QWIKMD::advGui(membrane,boxedges) 6] [lindex $QWIKMD::advGui(membrane,boxedges) 5] width $width]
    
    if {$QWIKMD::membraneFrame == ""} {
        graphics $QWIKMD::topMol materials on
        graphics $QWIKMD::topMol material Transparent

        ### xy lower plane
        
        lappend QWIKMD::membranebox [graphics $QWIKMD::topMol triangle [lindex $QWIKMD::advGui(membrane,boxedges) 0] [lindex $QWIKMD::advGui(membrane,boxedges) 4] [lindex $QWIKMD::advGui(membrane,boxedges) 5] ]
        lappend QWIKMD::membranebox [graphics $QWIKMD::topMol triangle [lindex $QWIKMD::advGui(membrane,boxedges) 4] [lindex $QWIKMD::advGui(membrane,boxedges) 5] [lindex $QWIKMD::advGui(membrane,boxedges) 6] ]

        ### xy upper plane
        
        lappend QWIKMD::membranebox [graphics $QWIKMD::topMol triangle [lindex $QWIKMD::advGui(membrane,boxedges) 1] [lindex $QWIKMD::advGui(membrane,boxedges) 7] [lindex $QWIKMD::advGui(membrane,boxedges) 2] ]
        lappend QWIKMD::membranebox [graphics $QWIKMD::topMol triangle [lindex $QWIKMD::advGui(membrane,boxedges) 2] [lindex $QWIKMD::advGui(membrane,boxedges) 7] [lindex $QWIKMD::advGui(membrane,boxedges) 3] ]
        graphics $QWIKMD::topMol materials off
        #graphics $QWIKMD::topMol material Opaque
    }

}

proc QWIKMD::incrMembrane {sign} {
    if {$QWIKMD::advGui(membrane,efect) == "translate"} {
        set v [list]
        switch $QWIKMD::advGui(membrane,axis) {
            x {
                set v [list ${sign}$QWIKMD::advGui(membrane,multi) 0 0]
            }
            y {
                set v [list 0 ${sign}$QWIKMD::advGui(membrane,multi) 0]
            }
            z {
                set v [list 0 0 ${sign}$QWIKMD::advGui(membrane,multi)]
            }
        }
        set QWIKMD::advGui(membrane,center,$QWIKMD::advGui(membrane,axis)) [expr $QWIKMD::advGui(membrane,center,$QWIKMD::advGui(membrane,axis)) $sign $QWIKMD::advGui(membrane,multi)]
        set QWIKMD::advGui(membrane,trans,$QWIKMD::advGui(membrane,axis)) [expr $QWIKMD::advGui(membrane,trans,$QWIKMD::advGui(membrane,axis)) $sign $QWIKMD::advGui(membrane,multi)]
        set matrix [transoffset $v]
        set i 0
        foreach coor $QWIKMD::advGui(membrane,boxedges) {
            lset QWIKMD::advGui(membrane,boxedges) $i [coordtrans $matrix $coor]
            incr i
        }
    } else {
        set center [list $QWIKMD::advGui(membrane,center,x) $QWIKMD::advGui(membrane,center,y) $QWIKMD::advGui(membrane,center,z)]
        set matrix [trans origin {0.0 0.0 0.0} axis $QWIKMD::advGui(membrane,axis) "${sign}$QWIKMD::advGui(membrane,multi)"  ]
        # if {$QWIKMD::advGui(membrane,rotationMaxtrixList) == 0} {
        #   set QWIKMD::advGui(membrane,rotationMaxtrixList) [list]
        #   lappend QWIKMD::advGui(membrane,rotationMaxtrixList) $matrix
        # } else {
            lappend QWIKMD::advGui(membrane,rotationMaxtrixList) $matrix
        # }
        set i 0
        if {$sign == "+"} {
            set value [expr $QWIKMD::advGui(membrane,rotate,$QWIKMD::advGui(membrane,axis)) + $QWIKMD::advGui(membrane,multi)]
        } else {
            set value [expr $QWIKMD::advGui(membrane,rotate,$QWIKMD::advGui(membrane,axis)) - $QWIKMD::advGui(membrane,multi)]
        }
        set QWIKMD::advGui(membrane,rotate,$QWIKMD::advGui(membrane,axis)) $value
        set centermover [transoffset [vecsub {0 0 0} $center]]
        set centerback [transoffset [vecsub $center {0 0 0}]]
        foreach coor $QWIKMD::advGui(membrane,boxedges) {
            set coor [coordtrans $centermover $coor]
            set coor [vectrans $matrix $coor]
            lset QWIKMD::advGui(membrane,boxedges) $i [coordtrans $centerback $coor]
            incr i
        }
    }
    QWIKMD::updateMembraneBox [list $QWIKMD::advGui(membrane,center,x) $QWIKMD::advGui(membrane,center,y) $QWIKMD::advGui(membrane,center,z)]
}

proc QWIKMD::OptSize {} {


    set center [list $QWIKMD::advGui(membrane,center,x) $QWIKMD::advGui(membrane,center,y) $QWIKMD::advGui(membrane,center,z)]
    set membrane [atomselect $QWIKMD::membraneFrame "all"]
    set centermover [transoffset [vecsub {0 0 0} $center]]  

    $membrane move $centermover
    #set center [measure center $membrane]
    set matrix ""
    if {[llength $QWIKMD::advGui(membrane,rotationMaxtrixList)] > 0} {
        if {[llength $QWIKMD::advGui(membrane,rotationMaxtrixList)] > 1} {
            set matrix [eval transmult [lreverse $QWIKMD::advGui(membrane,rotationMaxtrixList)]]
        } else {
            set matrix [join $QWIKMD::advGui(membrane,rotationMaxtrixList)]
        }
        set inv [measure inverse $matrix]
        $membrane move $inv
    }
    # set matrixCenter [transoffset [vecsub {0 0 0} [measure center $membrane]]]
    # $membrane move $matrixCenter
    #set center [measure center $membrane]

    update idletasks
    set protein [atomselect $QWIKMD::membraneFrame "not water and not ion and not lipid" ]
    set limits [measure minmax $protein]
    $protein delete
    # set all [atomselect $QWIKMD::membraneFrame "all"]
    # set alimits [measure minmax $membrane]
    # $all delete
    $membrane delete
    set xmin [expr [lindex [lindex $limits 0] 0] - 15]
    set xmax [expr [lindex [lindex $limits 1] 0] + 15]

    set ymin [expr [lindex [lindex $limits 0] 1] - 15]
    set ymax [expr [lindex [lindex $limits 1] 1] + 15]

    set pxcenter [expr [expr $xmax + $xmin] /2]
    set pycenter [expr [expr $ymax + $ymin] /2]


    set xlength [expr round(($xmax - $xmin) + 0.5)]
    set ylength [expr round(($ymax - $ymin) + 0.5)]
    
    set QWIKMD::advGui(membrane,xsize) $xlength
    set QWIKMD::advGui(membrane,ysize) $ylength

    ## Calculate the difference (offset) between the center of box and the center of the protein. 
    ## Move the box to the center of x,y axis of the protein 
    if {[llength $QWIKMD::advGui(membrane,rotationMaxtrixList)] > 0} {
        set QWIKMD::advGui(membrane,centerxoffset) $pxcenter
        set QWIKMD::advGui(membrane,centeryoffset) $pycenter
    }

    QWIKMD::updateMembraneBox [list $QWIKMD::advGui(membrane,center,x) $QWIKMD::advGui(membrane,center,y) $QWIKMD::advGui(membrane,center,z)]
    QWIKMD::GenerateMembrane
    QWIKMD::DrawBox
}

proc QWIKMD::GenerateMembrane {} {
    global env
    if {[llength $QWIKMD::membranebox] == 0} {
        QWIKMD::AddMBBox
    }
    QWIKMD::deleteMembrane
    set curlocation [pwd]
    ## generate the membrane.psf and pdb in the QWIKMDTMPDIR folder for easy deletion of the files 
    cd ${env(QWIKMDTMPDIR)}/
    catch {membrane -l $QWIKMD::advGui(membrane,lipid) -x $QWIKMD::advGui(membrane,xsize) -y $QWIKMD::advGui(membrane,ysize) -top c36}
    cd ${curlocation}
    set auxframe [molinfo top]
    set membrane [atomselect $auxframe all]

    set length [expr [array size QWIKMD::chains] /3]
    set txt ""
    for {set i 0} {$i < $length} {incr i} {
        if {$QWIKMD::chains($i,0) == 1} {
            append txt " ([lindex $QWIKMD::index_cmb($QWIKMD::chains($i,1),5)]) or" 
        }
        
    }
    set txt [string trimleft $txt " "]
    set txt [string trimright $txt " or"]
    set topmol [atomselect $QWIKMD::topMol $txt]

    set center [list $QWIKMD::advGui(membrane,center,x) $QWIKMD::advGui(membrane,center,y) $QWIKMD::advGui(membrane,center,z)]

    if {[llength $QWIKMD::advGui(membrane,rotationMaxtrixList)] > 0 } {
        if {[llength $QWIKMD::advGui(membrane,rotationMaxtrixList)] > 1} {
            set QWIKMD::advGui(membrane,rotationMaxtrix) [eval transmult [lreverse $QWIKMD::advGui(membrane,rotationMaxtrixList) ]] 
        } else {
            set QWIKMD::advGui(membrane,rotationMaxtrix) [join $QWIKMD::advGui(membrane,rotationMaxtrixList) ]
        }
        $membrane move $QWIKMD::advGui(membrane,rotationMaxtrix)
    }
    set matrixCenter [transoffset [vecsub $center [measure center $membrane ]]]
    $membrane move $matrixCenter
    update idletasks
    set auxframe2 [::TopoTools::selections2mol "$topmol $membrane"]
    
    $membrane delete
    $topmol delete
    
    set length [expr [array size QWIKMD::chains] /3]
    set txt ""
    for {set i 0} {$i < $length} {incr i} {
        if {$QWIKMD::chains($i,0) == 1} {
            append txt " ([lindex $QWIKMD::index_cmb($QWIKMD::chains($i,1),5)]) or" 
        }
        
    }
    set txt [string trimleft $txt " "]
    set txt [string trimright $txt " or"]
    set seltail "(same residue as ((all within 2 of ($txt)) and not name \"N.*\" \"O.*\" \"P.*\") and chain W L)"
    set selhead "(same residue as ((all within 2.5 of ($txt)) and name \"N.*\" \"O.*\" \"P.*\") and chain W L )"

    set sel [atomselect $auxframe2 "(all and not (($seltail) or ($selhead) ))" ]
    $sel writepdb ${env(QWIKMDTMPDIR)}/membrane.pdb
    $sel delete
    mol delete $auxframe2

    mol new ${env(QWIKMDTMPDIR)}/membrane.pdb waitfor all
    set QWIKMD::membraneFrame [molinfo top]
    mol modselect 0 $QWIKMD::membraneFrame  "chain W L" 
    mol modstyle 0 $QWIKMD::membraneFrame  "Lines"
    mol color Name

    mol delete $auxframe
 
    mol top $QWIKMD::topMol
    $QWIKMD::advGui(solvent,$QWIKMD::run) configure -values "Explicit"
    set QWIKMD::advGui(solvent,$QWIKMD::run,0) "Explicit"
    QWIKMD::ChangeSolvent
    if {[llength $QWIKMD::membranebox] == 16} {
        foreach point [lrange $QWIKMD::membranebox [expr [llength $QWIKMD::membranebox] -4]  end] {
            graphics $QWIKMD::topMol delete $point  
        }
        set QWIKMD::membranebox [lrange $QWIKMD::membranebox 0 [expr [llength $QWIKMD::membranebox] -5]]
    }
 

}
proc QWIKMD::deleteMembrane {} {
    if {$QWIKMD::membraneFrame != ""} {
        mol delete $QWIKMD::membraneFrame
        set QWIKMD::membraneFrame ""
        if {[llength $QWIKMD::membranebox] == 12} {
            QWIKMD::DrawBox
        }   
    }
    set values {"Vacuum" "Implicit" "Explicit"}
    $QWIKMD::advGui(solvent,$QWIKMD::run) configure -values $values
}

##############################################
## Proc to create the table with all ResidueSelect
## and previus modificaitons, such as mutations and protonation
## states. Here, the qwikMD macros are used so the 
## it is possible to change molecule classification
## of VMD by default. 
###############################################
proc QWIKMD::SelResid {} {
    if {[winfo exists $QWIKMD::selResGui] != 1} {
        QWIKMD::SelResidBuild
        wm withdraw $QWIKMD::selResGui
    }
    $QWIKMD::selresTable delete 0 end
    set QWIKMD::rename ""
            

    set tabid [expr [$QWIKMD::topGui.nbinput index current] + 1 ]
    set table $QWIKMD::selresTable
    set maintable "$QWIKMD::topGui.nbinput.f$tabid.tableframe.tb"

    set tbchains [$maintable getcolumns 0]
    set tbtypes [$maintable getcolumns 2]
    
    if {$tbchains != ""} {
        set str ""
        for {set i 0} {$i < [llength $tbchains]} {incr i} {
                set straux ""
                switch [lindex $tbtypes $i] {
                    protein {
                        set straux $QWIKMD::proteinmcr 
                    }
                    nucleic {
                        set straux $QWIKMD::nucleicmcr 
                    }
                    glycan {
                        set straux $QWIKMD::glycanmcr 
                    }
                    lipid {
                        set straux $QWIKMD::lipidmcr 
                    }
                    hetero {
                        set straux $QWIKMD::heteromcr 
                    }
                    water {
                        set straux "water"
                    }
                    default {
                        set straux [lindex $tbtypes $i]
                    }
                }
                append str "(chain \"[lindex $tbchains $i]\" and $straux) or "
        }

        set str [string trimright $str "or "]
        set sel [atomselect top "$str"]

        set str " "
        set i 0
        set macrosstr [list]
        set defVal {protein nucleic glycan lipid hetero}
        foreach macros $QWIKMD::userMacros {
            if {[lsearch $defVal [lindex $macros 0]] == -1 } {
                lappend macrosstr [lindex $macros 0] 
            }   
        }

        set retype 0
        set insertedResidues [list]
        set listMol [list]
        foreach resid [$sel get resid] resname [$sel get resname] chain [$sel get chain]\
         protein [$sel get qwikmd_protein] nucleic [$sel get qwikmd_nucleic] glycan [$sel get qwikmd_glycan] lipid [$sel get qwikmd_lipid] hetero [$sel get qwikmd_hetero] \
         water [$sel get water] macros [$sel get $macrosstr] residue [$sel get residue] {
            lappend listMol [list $resid $resname $chain $protein $nucleic $glycan $lipid $hetero $water $macros $residue]
        }
        set listMol [lsort -unique $listMol]
        set listMol [lsort -index 10 -integer -increasing $listMol]
        foreach listEle $listMol {
            set resid [lindex $listEle 0]
            set resname [lindex $listEle 1]
            set chain [lindex $listEle 2]
            set protein [lindex $listEle 3]
            set nucleic [lindex $listEle 4]
            set glycan [lindex $listEle 5]
            set lipid [lindex $listEle 6]
            set hetero [lindex $listEle 7]
            set water [lindex $listEle 8]
            set macros [lindex $listEle 9]
            set updateMainTable 0
            if {[lsearch $insertedResidues "$resid $resname $chain"] == -1 } {
                
                set type "protein"
                if {$protein == 1} {
                    set type "protein"
                } elseif {$nucleic == 1} {
                    set type "nucleic"
                } elseif {$glycan == 1} {
                    set type "glycan"
                } elseif {$lipid == 1} {
                    set type "lipid"
                } elseif {$water == 1} {
                    set type "water"
                } elseif {$macros == 1} {
                    set macroName [lindex $macrosstr [lsearch $macros 1]]
                    set type $macroName
                    set typesel $macroName
                } elseif {$hetero == 1} {
                    set type "hetero"
                }
            
                $table insert end "$resid $resname $chain $type"
                lappend insertedResidues "$resid $resname $chain"
                set index [lsearch -exact $QWIKMD::mutindex "${resid}_$chain"]
                set newresid ""
                if {$index != -1} {
                    set newresid "[lindex $QWIKMD::mutate(${resid}_${chain}) 0] -> [lindex $QWIKMD::mutate(${resid}_${chain}) 1]"
                    set index [lsearch -exact $QWIKMD::protindex "${resid}_$chain"]
                    if {$index != -1} {
                        append newresid " -> [lindex $QWIKMD::protonate(${resid}_${chain}) 1]"
                    }
                } elseif {[lsearch -exact $QWIKMD::protindex "${resid}_$chain"] != -1} {
                    set newresid "[lindex $QWIKMD::protonate(${resid}_${chain}) 0] -> [lindex $QWIKMD::protonate(${resid}_${chain}) 1]"
                } elseif {[lsearch -exact $QWIKMD::delete "${resid}_$chain"] != -1} {
                    $table rowconfigure $i -background white -foreground grey -selectbackground cyan -selectforeground grey
                }

                if {$newresid != ""} {
                    $table cellconfigure $i,1 -text $newresid
                    $table cellconfigure $i,1 -background #ffe1bb
                }
                if {$type == "protein"} {
                    set selaux [atomselect top "resid \"$resid\" and chain \"$chain\" "]
                    set hexcols [QWIKMD::chooseColor [lindex [$selaux get structure] 0]]
                    
                    set hexred [lindex $hexcols 0]
                    set hexgreen [lindex $hexcols 1]
                    set hexblue [lindex $hexcols 2]
                    set QWIKMD::color($i) "#${hexred}${hexgreen}${hexblue}"
                    $selaux delete
                    $table cellconfigure $i,3 -background $QWIKMD::color($i) -selectbackground $QWIKMD::color($i)
                }
                
                set addToRename 0
                set renameDone 0
                set newresname ""
                if {$type == "nucleic" || $type == "protein"} {
                    
                    if {$type == "nucleic"} {
                        set var $QWIKMD::nucleic
                        if {[lsearch -index 0 $QWIKMD::userMacros $type] > -1} {
                            set var [concat $var [lindex [lindex $QWIKMD::userMacros [lsearch -index 0 $QWIKMD::userMacros $type]] 1]]
                        }
                        set index [lsearch -exact $var $resname]
                        set index2 [lsearch -exact $QWIKMD::renameindex "${resid}_$chain"]
                        if {$index == -1 && $index2 != -1} {
                            $table cellconfigure $i,1 -text $QWIKMD::dorename([lindex $QWIKMD::renameindex $ind])
                            set newresname $QWIKMD::dorename([lindex $QWIKMD::renameindex $ind])
                            set renameDone 1
                        } elseif {$index == -1} {
                            set addToRename 1
                        }
                    }  elseif {$type == "protein"} {
                        set var $QWIKMD::reslist
                        if {[lsearch -index 0 $QWIKMD::userMacros $type] > -1} {
                            set var [concat $var [lindex [lindex $QWIKMD::userMacros [lsearch -index 0 $QWIKMD::userMacros $type]] 1]]
                        }
                        set ind [lsearch -exact $QWIKMD::renameindex "${resid}_$chain"]
                        if {[lsearch -exact $var $resname] == -1 && $ind == -1 && $resname != "HIS"} {
                            set addToRename 1
                        } elseif {[lsearch -exact $var $resname] == -1 & $resname != "HIS"} {
                            $table cellconfigure $i,1 -text $QWIKMD::dorename([lindex $QWIKMD::renameindex $ind])
                            set newresname $QWIKMD::dorename([lindex $QWIKMD::renameindex $ind])
                            set renameDone 1
                        }
                    }
                     
                    
                } else {
                    $table cellconfigure $i,3 -background white -selectbackground cyan
                    if {$type == "hetero"} {
                        set var $QWIKMD::hetero
                        if {[lsearch -index 0 $QWIKMD::userMacros $type] > -1} {
                            set var [concat $var [lindex [lindex $QWIKMD::userMacros [lsearch -index 0 $QWIKMD::userMacros $type]] 1]]
                        } else {
                            set var $QWIKMD::hetero
                        }
                        set index [lsearch -exact $var $resname]
                        set index2 [lsearch -exact $QWIKMD::renameindex "${resid}_$chain"]

                        set var $QWIKMD::heteronames
                        if {[lsearch -index 0 $QWIKMD::userMacros $type] > -1} {
                            set var [concat $var [lindex [lindex $QWIKMD::userMacros [lsearch -index 0 $QWIKMD::userMacros $type]] 2]]
                        } 
                        if {$index == -1 && $index2 == -1} {
                            set addToRename 1
                        } else {
                            if {$index != -1} {
                                $table cellconfigure $i,1 -text [lindex $var $index]
                                set newresname [lindex $var $index]
                                set renameDone 1
                            } else {
                                set index [lsearch -exact $QWIKMD::hetero $QWIKMD::dorename(${resid}_$chain)]
                                $table cellconfigure $i,1 -text [lindex $var $index]
                                set newresname [lindex $var $index]
                                set renameDone 1
                            }
                            
                        }
                    } elseif {$type == "glycan"} {
                        set var $QWIKMD::carb
                        if {[lsearch -index 0 $QWIKMD::userMacros $type] > -1} {
                            set var [concat $var [lindex [lindex $QWIKMD::userMacros [lsearch -index 0 $QWIKMD::userMacros $type]] 1]]
                        } else {
                            set var $QWIKMD::carb
                        }
                        set index [lsearch -exact $var $resname]
                        set index2 [lsearch -exact $QWIKMD::renameindex "${resid}_$chain"]
                        set var $QWIKMD::carbnames
                        if {[lsearch -index 0 $QWIKMD::userMacros $type] > -1} {
                            set var [concat $var [lindex [lindex $QWIKMD::userMacros [lsearch -index 0 $QWIKMD::userMacros $type]] 2]]
                        } 
                        if {$index == -1 && $index2 == -1} {
                            set addToRename 1
                        }  else {
                            if {$index != -1} {
                                $table cellconfigure $i,1 -text [lindex $var $index]
                                set newresname [lindex $var $index]
                                set renameDone 1
                            } else {
                                set index [lsearch -exact $QWIKMD::carb $QWIKMD::dorename(${resid}_$chain)]
                                set newresname [lindex $var $index]
                                $table cellconfigure $i,1 -text $newresname
                                
                                set renameDone 1
                            }
                            
                        }
                    } elseif {$type == "lipid"} {
                        set var $QWIKMD::lipidname
                        if {[lsearch -index 0 $QWIKMD::userMacros $type] > -1} {
                            set var [concat $var [lindex [lindex $QWIKMD::userMacros [lsearch -index 0 $QWIKMD::userMacros $type]] 1]]
                        }
                        set ind [lsearch -exact $QWIKMD::renameindex "${resid}_$chain"]
                        if {[lsearch -exact $var $resname] == -1 && $ind == -1 } {
                            set addToRename 1
                        } elseif {[lsearch -exact $var $resname] == -1} {
                            $table cellconfigure $i,1 -text $QWIKMD::dorename([lindex $QWIKMD::renameindex $ind])
                            set newresname $QWIKMD::dorename([lindex $QWIKMD::renameindex $ind])
                            set renameDone 1
                        }
                    
                    }
                }
                
                if {[lsearch -index 0 $QWIKMD::userMacros $type] > -1 && $renameDone == 0 && $addToRename == 0} {
                    set macro [lindex $QWIKMD::userMacros [lsearch -index 0 $QWIKMD::userMacros $type]]
                    set var [lindex $macro 1]
                    set index [lsearch -exact $var $resname]
                    set index2 [lsearch -exact $QWIKMD::renameindex "${resid}_$chain"]
                    if {$index == -1 && $index2 == -1} {
                        set addToRename 1
                    }  else {
                        if {$index != -1} {
                            $table cellconfigure $i,1 -text [lindex [lindex $macro 2] $index]
                            set newresname [lindex [lindex $macro 2] $index]
                        } else {
                            set index [lsearch -exact $var $QWIKMD::dorename(${resid}_$chain)]
                            set newresname [lindex [lindex $macro 2] $index]
                            $table cellconfigure $i,1 -text $newresname
                        }
                        
                    }
                }
                ## Avoid duplicated residues in the Resid Table
                if {$newresname != ""} {
                    lset insertedResidues $i "$resid $newresname $chain"
                    if {[llength [lsearch -all $insertedResidues "$resid $newresname $chain"]] > 1} {
                        lreplace $insertedResidues $i $i
                        $table delete $i
                        continue
                    }                        
                }

                if {$QWIKMD::prepared == 0} {
                    if {$addToRename == 1 && [lsearch $QWIKMD::delete "${resid}_$chain"] == -1 && $resname != "HIS"} {
                        set listMolecules [list $QWIKMD::reslist $QWIKMD::hetero $QWIKMD::carb $QWIKMD::nucleic $QWIKMD::lipidname]
                        set found 0
                        set indexmacro -1
                        set incrList 0
                        set macro ""
                        foreach var $listMolecules {
                            set index [lsearch -exact $var $resname]
                            if {$index != -1} {
                                set indexlist $incrList
                                set found 1
                                switch $indexlist {
                                    0 {
                                        set macro protein   
                                    }
                                    1 {
                                        set macro hetero
                                    }
                                    2 {
                                        set macro glycan
                                    }
                                    3 {
                                        set macro nucleic
                                    }
                                    4 {
                                        set macro lipid
                                    }
                                }
                                break
                            }
                            incr incrList
                        }
                        if {$found == 0} {
                            foreach mcr $QWIKMD::userMacros {
                                if {[lsearch -exact [lindex $mcr 1] $resname] != -1 && $type != [lindex $mcr 0]} {
                                    set macro [lindex $mcr 0]
                                    set found 1
                                    break
                                }
                            }
                        }
                        if {$found == 1 && $type != $macro} {
                            set txt "and not \(resid \"$resid\" and chain \"$chain\"\)"
                            set txt2 "or \(resid \"$resid\" and chain \"$chain\"\)"
                            QWIKMD::editMacros $type $txt $txt2 old
                            QWIKMD::editMacros $macro $txt $txt2 new
                            set defVal {protein nucleic glycan lipid hetero}
                            if {$macro != "hetero"} { 
                                QWIKMD::editMacros "hetero" $txt $txt2 old
                            }
                            set retype 1
                        } elseif {$found == 0 && $addToRename == 1} {
                            $table rowconfigure $i -background red -selectbackground cyan
                            lappend QWIKMD::rename "${resid}_$chain"
                            set name "$chain and $type"
                            if {$QWIKMD::index_cmb($name,2) != "Throb"} {
                                set QWIKMD::index_cmb($name,2) "Throb"
                                $maintable cellconfigure $QWIKMD::index_cmb($name,3),4 -text [QWIKMD::mainTableCombosEnd $QWIKMD::topGui.nbinput.f$tabid.tableframe.tb $QWIKMD::index_cmb($name,3) 4 "Throb"]
                            }
                        }   
                    }
                }
                incr i
            }
        }
        set insertedResidues [list]
        set listMol [list]
        $sel delete
        if {$retype == 1} {
            QWIKMD::UpdateMolTypes [expr [$QWIKMD::topGui.nbinput index current] +1]
        }
    }
    if {$tabid == 2 && [llength $QWIKMD::patchestr] > 0} {
        set i 1
        foreach patch $QWIKMD::patchestr {
            $QWIKMD::selresPatcheText insert $i.0 "$patch\n"
            incr i
        }
    }
}

proc QWIKMD::editAtom {} {
    set resTable $QWIKMD::selresTable
    set row [lindex [$resTable curselection] 0]
    $QWIKMD::atmsTable delete 0 end
    set prevres ""
    
    set resid [$resTable cellcget $row,0 -text]
    set resname [$resTable cellcget $row,1 -text]
    set chain [$resTable cellcget $row,2 -text]
    set type [$resTable cellcget $row,3 -text]

    set resnameaux [split $resname "->"]
    if {[llength $resnameaux] > 1} {
        if {[lindex $resname 0] == "HIS" && ([lindex $resname 2] == "HSD" || [lindex $resname 2] == "HSE" || [lindex $resname 2] == "HSP")} {
            set resname [lindex $resname 2]
        }
    } 
    
    switch $type {
        hetero {
            set index [lsearch $QWIKMD::heteronames $resname]
            if {$index != -1} {
                set resname [lindex $QWIKMD::hetero $index ]
            }
        }
        glycan {
            set index [lsearch $QWIKMD::carbnames $resname]
            if {$index != -1} {
                set resname [lindex $QWIKMD::carb $index ]
            }
        }
        default {
            set macroindex [lsearch -index 0 $QWIKMD::userMacros $type]
            if {$macroindex > -1 && $type != "protein" && $type != "nucleic"} {
                set typemacro [lindex $QWIKMD::userMacros $macroindex]
                set index [lsearch [lindex $typemacro 2] $resname]
                if {$index != -1} {
                    set resname [lindex [lindex $typemacro 1] $index ]
                }
            }
            
        }
    }

    set sel [atomselect $QWIKMD::topMol "resid \"$resid\" and chain \"$chain\""]
    
    set index 1
    set QWIKMD::atmsOrigNames [list]
    set QWIKMD::atmsOrigResid [list]
    set QWIKMD::atmsOrigIdex [list]
    set QWIKMD::atmsOrigElem [list]
    foreach name [$sel get name] element [$sel get element] atmindex [$sel get index ] atmelemnt [$sel get element ] {
        set prevAtmChangeIndex [lsearch -all -index 1 $QWIKMD::atmsRename $name]
        lappend QWIKMD::atmsOrigNames $name
        lappend QWIKMD::atmsOrigResid $resid
        lappend QWIKMD::atmsOrigIdex $atmindex
        lappend QWIKMD::atmsOrigElem $atmelemnt
        if {$prevAtmChangeIndex > -1} {
            set name [lindex [lindex $QWIKMD::atmsRename $prevAtmChangeIndex] 2]
        }

        set auxList [list $index $resname $resid $chain $name $element $type]
        if {[$QWIKMD::atmsTable columncget 6 -name] == "Charge"} {
            set auxList [list $index $resname $resid $chain $name $element 0.00 $type]
        } 
        $QWIKMD::atmsTable insert end $auxList
        
        incr index
    }
    set QWIKMD::atmsNames [list]
    set str "No Topology Found"
    set isknown [lsearch -exact $QWIKMD::rename "${resid}_$chain"]
    set tabid [$QWIKMD::topGui.nbinput index current]
    if {$isknown != -1 && $tabid == 1} {
        set QWIKMD::topofilename ${resname}.rtf 
    }

    if {($isknown == -1 || [lsearch -exact $QWIKMD::renameindex "${resid}_$chain"] != -1) || ($type != "protein" && $resname != "HIS")} {
        set toposearch [QWIKMD::checkAtomNames $resname]
        set topofile [lindex $toposearch 0]
        foreach name [lindex $toposearch 1] {
            lappend QWIKMD::atmsNames [lindex $name 0]
        }

        set do 1
        if {$topofile != -1} {
            set QWIKMD::topofilename $topofile
            set opentopo [open $topofile r]
        
        
            set str ""
            
            while {[eof $opentopo] != 1 && $do == 1} {
                set line1 [gets $opentopo]
                set line [split $line1]
                    
                if {[lindex $line 0] == "RESI" && [lindex $line 1] ==  $resname} {
                
                        
                    while {[lindex $line 0] != "IC" && [eof $opentopo] != 1 && [lindex $line 0] != "END"} {
                        append str "$line1\n"
                        set line1 [gets $opentopo]
                        set line [split $line1]
                        if {[lindex $line 0] == "RESI"} {
                            break
                        }
                    }
                    set do 0
                    
                }
            }
            close $opentopo
        } 
        if {$do == 0} {
            set str "Topology File: [file tail $topofile]\n${str}"
        }
    }
    if {$type == "protein" && $resname == "HIS" } {
        tk_messageBox -message "Please assign a protonation state to histidine residues" -type ok \
        -icon warning -parent $QWIKMD::editATMSGui
    }
    $QWIKMD::atmsText configure -state normal
    $QWIKMD::atmsText delete 1.0 end
    $QWIKMD::atmsText insert 1.0 [format %s $str]
    
    mol off $QWIKMD::topMol
    if {[lsearch [molinfo list] $QWIKMD::atmsMol] > -1} {
        mol delete $QWIKMD::atmsMol
    }
    set QWIKMD::atmsMol [::TopoTools::selections2mol "$sel"]
    QWIKMD::loadEditAtmsMol
}
#####################################################################################
## Load to molecule in the "Edit Atoms" Mode
#####################################################################################
proc QWIKMD::loadEditAtmsMol {} {
    set selAll [atomselect $QWIKMD::atmsMol all ]
    set resname [lsort -unique [$selAll get resname]]
    mol rename $QWIKMD::atmsMol "Edit_${resname}_Atoms"
    mol modselect 0 $QWIKMD::atmsMol all
    mol modstyle 0 $QWIKMD::atmsMol "CPK 0.500000 0.100000 12.000000 12.000000"
    mol modcolor 0 $QWIKMD::atmsMol "Element"
    display resetview
    
    set QWIKMD::atmsLables [list]
    set indNew 1
    foreach ind [$selAll get index] {
        draw color lime
        set selInd [atomselect $QWIKMD::atmsMol "index $ind"]
        lappend QWIKMD::atmsLables [draw text [vecadd {0.2 0.0 0.0} [join  [$selInd get {x y z}]] ] $indNew size 3]
        incr indNew
        $selInd delete
    }
    $selAll delete

    $QWIKMD::atmsText configure -height 15 
    $QWIKMD::atmsText configure -state disabled
}
#####################################################################################
## Apply changes made on the Edit Atom window
## Change atoms name to match the names on the topology file/
## Renumber the residue in case of, for instance, three residues represented
## as only one in the pdb
#####################################################################################
proc QWIKMD::checkAtomNames {resname} {

    set prevres ""
    set topofile "-1"
    set charmmNames [list]
    foreach topo $QWIKMD::topoinfo {
        if {[file exists [lindex $topo 0]]} {
            set topores [::Toporead::topology_get_resid $topo $resname]
            if {[lindex $topores 1] == $resname} {
                set topofile [lindex $topo 0]
                set charmmNames [::Toporead::topology_get_resid $topo $resname atomlist]
                break
            }
            
        }
        
    }
    return [list ${topofile} $charmmNames]
}
#####################################################################################
## generate a CHARMM topology file based on the molecule JUST FOR QM/MM simulations
#####################################################################################
proc QWIKMD::generateTopology {} {
    global env
    set file [open ${env(QWIKMDTMPDIR)}/tem_top.rtf w+]
    set str ""
    puts $file "\n"

    set straux "read rtf card append\n"
    puts $file $straux
    set elements [$QWIKMD::atmsTable getcolumns 5]

    set foundiron 0
    if {[lsearch $elements "Fe"] != -1} {
        puts $file "MASS -1 FE 55.84700 ! iron\n"
        set foundiron 1
    }

    set resname [$QWIKMD::atmsTable cellcget 0,1 -text]
    set straux "RESI $resname[string repeat " " 9]$QWIKMD::totcharge\n"
    append str "${straux}\n\n"
    puts $file $straux
    for {set i 0} {$i < [$QWIKMD::atmsTable size]} {incr i} {
        set atomname [$QWIKMD::atmsTable cellcget $i,4 -text]
        set element [$QWIKMD::atmsTable cellcget $i,5 -text]
        set atomtype $QWIKMD::element($element)
        set charge [$QWIKMD::atmsTable cellcget $i,6 -text]
        set straux "ATOM [format %-4s $atomname] [format %-5s $atomtype]  [format %.2f $charge]"
        append str "${straux}\n"
        puts $file $straux
    }
    puts $file "end\n"
    if {$foundiron == 1} {
        puts $file "read para card flex append\n"
        puts $file "NONBONDED nbxmod  5 atom cdiel fshift vatom vdistance vfswitch -"
        puts $file "cutnb 14.0 ctofnb 12.0 ctonnb 10.0 eps 1.0 e14fac 1.0 wmin 1.5\n"
        puts $file "FE     0.010000   0.000000     0.650000 ! ALLOW HEM"
        puts $file "end"
    }
    
    $QWIKMD::atmsText configure -state normal
    $QWIKMD::atmsText delete 1.0 end
    $QWIKMD::atmsText insert 1.0 [format %s $str]
    close $file
}
proc QWIKMD::atmStartEdit {tbl row col text} {
    set w [$tbl editwinpath]
    switch [$tbl columncget $col -name] {
        AtmdNAME {
            $w configure -values $QWIKMD::atmsNames -state normal -style protocol.TCombobox -takefocus 0 -exportselection false -justify center
            bind $w <<ComboboxSelected>> {
                $QWIKMD::atmsTable finishediting    
            }
            $w set $text
        }
        Element {
            $w configure -values [lsort -dictionary [array names QWIKMD::element]] -state normal -style protocol.TCombobox -takefocus 0 -exportselection false -justify center
            bind $w <<ComboboxSelected>> {
                $QWIKMD::atmsTable finishediting    
            }
            $w set $text
        }

    }
    return $text
}


proc QWIKMD::atmEndEdit {tbl row col text} {
    if {$text == ""} {
        return [$tbl cellcget $row,$col -text]
    }
    switch [$tbl columncget $col -name] {
        AtmdNAME {
            set do 1
            if {[lsearch $QWIKMD::atmsNames $text ] == -1 && $QWIKMD::advGui(qmoptions,qmgentopo) == 0} {
                tk_messageBox -message "Please choose one atom name from the list." -icon warning \
                -type ok -parent $QWIKMD::editATMSGui
                return [$tbl cellcget $row,$col -text]
            }
            set names [$tbl getcolumns 4]
            set index [lsearch $names $text]
            if {$index != -1 && $QWIKMD::advGui(qmoptions,qmgentopo) == 0} {
                set residfound [$tbl cellcget $index,2 -text]
                set resid [$tbl cellcget $row,2 -text]
                if {$residfound == $resid} {
                    tk_messageBox -message "Atoms' name must be unique." -icon warning \
                    -type ok -parent $QWIKMD::editATMSGui
                    set do 0
                }
            }
            if {[string length $text] > 4 && $QWIKMD::advGui(qmoptions,qmgentopo) == 1} {
                tk_messageBox -message "Atoms' name must be 4 characters long." -icon warning \
                -type ok -parent $QWIKMD::editATMSGui
                set do 0
                return [$tbl cellcget $row,$col -text]
            }
            if {$do == 1} {
                set index [expr [$tbl cellcget $row,0 -text] -1]
                set sel [atomselect top "index $index"]
                $sel set name $text
                $sel delete
            }
        }
        Resname {
            if {[llength $text] > 0 && [QWIKMD::checkresidueTop $text 2 $QWIKMD::editATMSGui] == 1 } {
                set text [$QWIKMD::atmsTable cellcget $row,1 -text]
            } else {
                set reslist [$QWIKMD::atmsTable getcolumns 1]
                set indexes [lsearch -all $reslist [$QWIKMD::atmsTable cellcget $row,1 -text]]
                if {[llength $reslist] > 1 && [llength $indexes] > 1} {
                    set indexes [lreplace $indexes $row $row]
                    set answer [tk_messageBox -message "One or more atoms can be changed based on \
                    the chosen residue name.\nDo you want to change all?" -type yesnocancel\
                    -icon question -parent $QWIKMD::editATMSGui]
                    if {$answer == "cancel"} {
                        set text [$QWIKMD::atmsTable cellcget $row,1 -text]
                    } elseif {$answer == "yes"} {
                        for {set i 0} {$i < [llength $indexes]} {incr i} {
                            $QWIKMD::atmsTable cellconfigure [lindex $indexes $i],1 -text $text
                        }

                    }
                }
            }
        }
        Element {
            if {[lsearch [lsort -dictionary [array names QWIKMD::element]] $text ] == -1} {
                tk_messageBox -message "Please choose one element from the list." -icon warning \
                -type ok -parent $QWIKMD::editATMSGui
                return [$tbl cellcget $row,$col -text]
            }
            set index [expr [$tbl cellcget $row,0 -text] -1]
            set sel [atomselect top "index $index"]
            $sel set element $text
            $sel set name $text
            $tbl cellconfigure $row,4 -text $text
            $sel delete
        }
        Charge {
            if {$text == ""} {
                set text "0.00"
            }
            set text [QWIKMD::format2Dec $text]
            $tbl cellconfigure $row,$col -text $text
            set totaux 0.00
            set i 0 
            foreach chrg [$tbl getcolumns $col] {
                set totaux [expr $totaux + $chrg]
            }
            set QWIKMD::totcharge [QWIKMD::format2Dec $totaux]
        }
        ResID {
            set text [expr int([format %4.0f $text])]
            if {[llength $text] == 0} {
                set text [$QWIKMD::atmsTable cellcget $row,2 -text]
            } else {
                set reslist [$QWIKMD::atmsTable getcolumns 2]
                set indexes [lsearch -all $reslist [$QWIKMD::atmsTable cellcget $row,2 -text]]
                if {[llength $reslist] > 1 && [llength $indexes] > 1} {
                    set answer [tk_messageBox -message "One or more atoms can be changed based on \
                    the chosen residue ID.\nDo you want to change all?" -type yesnocancel\
                    -icon question -parent $QWIKMD::editATMSGui]
                    if {$answer == "cancel"} {
                        set text [$QWIKMD::atmsTable cellcget $row,2 -text]
                    } elseif {$answer == "yes"} {
                        for {set i 0} {$i < [llength $indexes]} {incr i} {
                            $QWIKMD::atmsTable cellconfigure [lindex $indexes $i],2 -text $text
                        }

                    }
                }
            }
        }
    }
    return $text
}
############################################################
## Delete atoms from the Edit Atoms window
############################################################
proc QWIKMD::deleteAtoms {atmindex molID} {
    set atmsel [atomselect $molID "index $atmindex"]
    set atmbonds [join [$atmsel getbonds]]
    $atmsel setbonds [list {}]
    $atmsel set name "QWIKMDDELETE"
    $atmsel set radius 0.0
    $atmsel set resid -9999
    foreach bonds $atmbonds {
        set selaux [atomselect $molID "index $bonds"]
        set bondslist [join [$selaux getbonds]]
        set delindex [lsearch $bondslist $atmindex]
        set newbonds [lreplace $bondslist $delindex $delindex]
        if {[llength $newbonds] == 0} {
            set newbonds {}
        }
        $selaux setbonds [list $newbonds]
        $selaux delete
    }
    $atmsel delete
}

############################################################
## Change the name of the atoms based on the index
############################################################

proc QWIKMD::changeAtomNames {} {
    if {[lindex [$QWIKMD::atmsTable editinfo] 1] != -1 } {
        $QWIKMD::atmsTable finishediting
    }
    if {[$QWIKMD::atmsTable size] == 0} {
        return
    }
    set currentValName [$QWIKMD::atmsTable getcolumns 4]
    set chain [$QWIKMD::atmsTable cellcget 0,3 -text]
    set currentValResid [$QWIKMD::atmsTable getcolumns 2]
    set type [$QWIKMD::atmsTable cellcget 0,6 -text]
    set atmindex [$QWIKMD::atmsTable getcolumns 0]
    set resname [$QWIKMD::atmsTable cellcget 0,1 -text]
    set element [$QWIKMD::atmsTable getcolumns 5]
    foreach name $currentValName {
        if {[lsearch $QWIKMD::atmsNames $name] == -1 && $QWIKMD::advGui(qmoptions,qmgentopo) == 0} {
            tk_messageBox -message "Please assign the correct name to the atom $name." -title "Atom's Name" -icon warning \
            -type ok -parent $QWIKMD::editATMSGui
            return
        }
    }
    if {$QWIKMD::advGui(qmoptions,qmgentopo) == 1 && [lsearch $QWIKMD::TopList */$QWIKMD::topofilename] == -1} {
        tk_messageBox -message "Please save the QM topology file" -type ok -icon warning \
        -title "QM Topology File Not Saved" -parent $QWIKMD::editATMSGui
        return
    }

    ## Delete Atoms
    set PDBresname ""
    if {[llength $QWIKMD::atmsDeleteNames] > 0} {

        set delatmindex [lindex $QWIKMD::atmsDeleteNames 0]
        set selresid  [lindex $QWIKMD::atmsOrigResid $delatmindex ]
        set delatmname [lindex $QWIKMD::atmsOrigNames $delatmindex]
        
        set selresid [atomselect $QWIKMD::topMol "resid \"$selresid\" and chain \"$chain\" and name $delatmname"]
        set PDBresname [lsort -unique [$selresid get resname]]
        $selresid delete
        
        set selresid [atomselect $QWIKMD::topMol "resname $PDBresname and name $delatmname"]
        set delresidlist [lsort -unique [$selresid get resid]]
        $selresid delete
        set numresname [llength $delresidlist]
        set answer "yes"
        if {$numresname > 1} {
            set answer [tk_messageBox -message "The atoms signed to be deleted were found in more than one residue.\
             Do you want to delete in all?" -icon warning -title "Delete Atoms" -type yesnocancel -parent $QWIKMD::editATMSGui]
            if {$answer == "cancel"} {
                return
            } 
        }

        foreach delatmindex $QWIKMD::atmsDeleteNames {
            set selresid  [lindex $QWIKMD::atmsOrigResid $delatmindex ]
            set delatmname [lindex $QWIKMD::atmsOrigNames $delatmindex]
            set sel ""
            if {$answer == "yes"} {
                set sel [atomselect $QWIKMD::topMol "resname $PDBresname and name $delatmname"]
                foreach resid [$sel get resid] chain [$sel get chain] resname [$sel get resname] index [$sel get index] {
                    QWIKMD::deleteAtoms $index $QWIKMD::topMol
                    lappend QWIKMD::atmsDeleteLog [list $resid $resname $chain $delatmname] 
                }
                set QWIKMD::atmsOrigResid [lreplace $QWIKMD::atmsOrigResid $delatmindex $delatmindex]
                set QWIKMD::atmsOrigNames [lreplace $QWIKMD::atmsOrigNames $delatmindex $delatmindex]
                set QWIKMD::atmsOrigIdex [lreplace $QWIKMD::atmsOrigIdex $delatmindex $delatmindex]
            } else {
                set sel [atomselect $QWIKMD::topMol "resid \"$selresid\" and chain \"$chain\" and name $delatmname"]
                QWIKMD::deleteAtoms [$sel get index] $QWIKMD::topMol
                lappend QWIKMD::atmsDeleteLog [list $selresid $PDBresname $chain $delatmname] 
            }
            $sel delete
        }
        set QWIKMD::atmsDeleteNames [list]
    }
    ###Check if there is more than one residue with the same name to apply the same changes

    set originalname [lindex $QWIKMD::atmsOrigNames 0 ]
    set originalresid [lindex $QWIKMD::atmsOrigResid 0 ]
    if {$PDBresname == ""} {
        set selresid [atomselect $QWIKMD::topMol "resid \"$originalresid\" and chain \"$chain\" and name $originalname"]
        set PDBresname [lsort -unique [$selresid get resname]]
        $selresid delete
    }
    set numresname 1
    set answer "no"
    if {$QWIKMD::resallnametype == 1} {
        set selresid [atomselect $QWIKMD::topMol "resname $PDBresname and name $originalname"]
        set residlist [lsort -unique [$selresid get resid]]
        $selresid delete
        set numresname [llength $residlist]
        
        if {$numresname > 1} {
            set answer [tk_messageBox -message "More than one residue can be changed base on this operation.\
             Do you want to apply to all?" -icon warning -title "Atom's Name" -type yesnocancel -parent $QWIKMD::editATMSGui]
            if {$answer == "cancel"} {
                return
            } elseif {$answer == "no"} {
                set numresname 1
            }
        }
    }
    set listindex 0
    set resIdChange 0
    set prevResId [lindex $QWIKMD::atmsOrigResid [expr [lindex $atmindex $listindex] -1] ]
    set prevresidList ""
    set selList [list]
    set newNames [list]
    set newElements [list]
    foreach name $currentValName {
        set atomindex [lindex $atmindex $listindex]
        set originalname [lindex $QWIKMD::atmsOrigNames [expr $atomindex -1] ]
        set originalresid [lindex $QWIKMD::atmsOrigResid [expr $atomindex -1] ]
        set originalindex [lindex $QWIKMD::atmsOrigIdex [expr $atomindex -1] ]
        ## List containing the information "{ {Residue Names} {Residue Number} {Old Atom Name} {New Atom Name}}. "
        ## The change of element will not be included in this list since will be applied only to the QM/MM sim
        set replaceIndex [lsearch $QWIKMD::atmsRename "$resname $originalresid $originalname *" ]
        if {$replaceIndex == -1} {
            lappend QWIKMD::atmsRename [list $resname $originalresid $originalname [lindex $currentValName $listindex] [lindex $currentValResid $listindex] ]
        } else {
            lreplace $QWIKMD::atmsRename $replaceIndex $replaceIndex [list $resname $originalresid $originalname [lindex $currentValName $listindex] [lindex $currentValResid $listindex] ]
        }
        set sel ""
        if {$answer == "yes"} {
            ## the use of the atoms index makes sense only if the user wants to change only the residue in edition.
            ## to apply the changes to all similar residues, one has to use resname and atoms name only. Some
            ## atoms can be missing or in different order/ atom index 
            set sel [atomselect $QWIKMD::topMol "resname $PDBresname and name $originalname"]
            foreach resid [$sel get resid] chain [$sel get chain] {
                if {$originalname != [lindex $currentValName $listindex]} {
                    lappend QWIKMD::atmsRenameLog [list $resid $resname $chain $originalname [lindex $currentValName $listindex]] 
                }
            }
        } else {
            set sel [atomselect $QWIKMD::topMol "resid \"$originalresid\" and chain \"$chain\" and index $originalindex"]
            if {$originalname != [lindex $currentValName $listindex]} {
                lappend QWIKMD::atmsRenameLog [list $originalresid $resname $chain $originalname [lindex $currentValName $listindex]] 
            }
        }
        set nameRepeatList [list]
        set nameRepeatElemList [list]
        set nameRepeatResNameList [list]
        if {$numresname > 1} {
            for {set i 0} {$i < [llength [lsort -unique [$sel get residue]]]} {incr i} {
                lappend nameRepeatList [lindex $currentValName $listindex]
                lappend nameRepeatElemList [lindex $element $listindex]
            }
        } else {
            set nameRepeatList [lindex $currentValName $listindex]
            set nameRepeatElemList [lindex $element $listindex]
        }
        lappend selList $sel
        lappend newNames $nameRepeatList
        lappend newElements $nameRepeatElemList
        set currentResid [lindex $currentValResid $listindex]
        if {$currentResid!= $originalresid} {

            $sel set resid [lindex $currentValResid $listindex]
            ###Check if the residue was marked for renaming and change the type of the new created residues
            if {[info exists QWIKMD::dorename(${originalresid}_$chain)] == 1 && $prevresidList != $currentResid && $prevResId != $currentResid } {

                lappend QWIKMD::atmsReorderLog [list $originalresid $resname $chain $originalresid $currentResid]
                if {[lsearch -exact $QWIKMD::renameindex ${currentResid}_$chain] == -1} {
                    lappend QWIKMD::renameindex ${currentResid}_$chain
                    set QWIKMD::dorename(${currentResid}_$chain) $QWIKMD::dorename(${originalresid}_$chain)
                }
                
                set toresname ""
                set txt "and not \(resid \"${currentResid}\" and chain \"$chain\"\)"
                set txt2 "or \(resid \"${currentResid}\" and chain \"$chain\"\)"

                QWIKMD::checkMacros $type $txt $txt2

                if {$type == "hetero"} {
                    append QWIKMD::heteromcr " $txt2"
                } elseif {$type == "nucleic"} {
                    append QWIKMD::nucleicmcr " $txt2"
                } elseif {$type == "lipid"} {
                    append QWIKMD::lipidmcr " $txt2"
                } elseif {$type == "glycan"} {
                    append QWIKMD::glycanmcr " $txt2"
                } elseif {$type == "protein"} {
                    append QWIKMD::proteinmcr " $txt2"
                } elseif {[lsearch -index 0 $QWIKMD::userMacros $type] > -1} {
                    atomselect macro $type "[atomselect macro $type] $txt2"
                }

                set listOfMacros [concat protein nucleic glycan lipid hetero]
                foreach macroName $listOfMacros {
                    if {$macroName != $type} {
                        QWIKMD::checkMacros $macroName $txt $txt2
                        if {$macroName == "hetero"} {
                            append QWIKMD::heteromcr " $txt"
                        } elseif {$macroName == "nucleic"} {
                            append QWIKMD::nucleicmcr " $txt"
                        } elseif {$macroName == "lipid"} {
                            append QWIKMD::lipidmcr " $txt"
                        } elseif {$macroName == "glycan"} {
                            append QWIKMD::glycanmcr " $txt"
                        } elseif {$macroName == "protein"} {
                            append QWIKMD::proteinmcr " $txt"
                        }
                    }
                }
            }

            set resIdChange 1
            
        }
        set prevresidList [lindex $currentValResid $listindex]
        #$sel delete
        incr listindex
    }
    ## apply the changes in the atoms names.
    ## Doing after the the loop prevents applying changes to atoms already 
    ## changed (e.g. index 1 == CA -> CB, index 2 == CB -> CA)
    set nindex 0
    set topoUpdate 0
    set newresname ""
    if {$QWIKMD::advGui(qmoptions,qmgentopo) == 1} {
        set newresname [$QWIKMD::atmsTable getcolumns 1]
    }
    foreach sel $selList {
        $sel set name [lindex $newNames $nindex]
        if {$QWIKMD::advGui(qmoptions,qmgentopo) == 1} {
            $sel set element [lindex $newElements $nindex]
            $sel set type [lindex $newElements $nindex]
            set tableindex [$QWIKMD::selresTable searchcolumn 2 $chain -check [list QWIKMD::tableSearchCheck [lindex $QWIKMD::atmsOrigResid $nindex] ] ]
            if {[lindex $newresname $nindex] != [$QWIKMD::selresTable cellcget $tableindex,2 -text]} {
                $sel set resname [lindex [$QWIKMD::atmsTable getcolumns 1] $nindex]
            }
            set topoUpdate 1
        }
        $sel delete
        incr nindex
    }
    QWIKMD::deleteAtomGuiProc
    if {$topoUpdate == 1} {
        QWIKMD::reviewTopPar 0
        QWIKMD::loadTopologies
    }
    if {$resIdChange == 1} {
        atomselect macro qwikmd_protein $QWIKMD::proteinmcr
        atomselect macro qwikmd_nucleic $QWIKMD::nucleicmcr
        atomselect macro qwikmd_glycan $QWIKMD::glycanmcr
        atomselect macro qwikmd_lipid $QWIKMD::lipidmcr
        atomselect macro qwikmd_hetero $QWIKMD::heteromcr
    }
    if {$topoUpdate == 1 || $resIdChange == 1} {
        # QWIKMD::messageWindow "Checking Structure" "Checking structure with \
        the new molecule types"
        QWIKMD::UpdateMolTypes $QWIKMD::tabprevmodf
        if {$topoUpdate == 1} {
            QWIKMD::callCheckStructure
        }
        # destroy $QWIKMD::messWinGui
    }
}

proc QWIKMD::cancelAtomNames {} {
    QWIKMD::deleteAtomGuiProc
}

############################################################
## Load the mol2 file to the editAtom Molecule and display
## the topology
############################################################
proc QWIKMD::loadMol2EditAtom {{strfile ""} {molfile ""}} {
    
    if {$strfile == ""} {
        set strfile [tk_getOpenFile -title "Import STR File" -filetypes {{{Stream Files} {.str}}} -defaultextension ".str"]
    }

    if {$strfile != ""} {
        if {$molfile == ""} {
            set molfile [tk_getOpenFile -title "Import MOL2 File" -filetypes {{{MOL2 Files} {.mol2}}} -defaultextension ".mol2"]
        }
        if {$molfile != ""} {
            ### Add topology to the QwiKMD
            catch {QWIKMD::AddTP}
            wm withdraw $QWIKMD::topoPARAMGUI            
            QWIKMD::addTopParm $strfile
            set resname [$QWIKMD::atmsTable cellcget 0,1 -text]
            set type [$QWIKMD::atmsTable cellcget 0,6 -text]
            $QWIKMD::topocombolist($resname) set [$QWIKMD::atmsTable cellcget 0,6 -text]

            ### load the mol2 file as edit atom molecule
            set prevatmsMol $QWIKMD::atmsMol 
            set QWIKMD::atmsMol [mol new $molfile waitfor all]
            QWIKMD::loadEditAtmsMol

            ### Populate the edit atoms table
            set resid [$QWIKMD::atmsTable cellcget 0,2 -text]
            set chain [$QWIKMD::atmsTable cellcget 0,3 -text] 
            set sel [atomselect $QWIKMD::atmsMol "all"]

            topo -molid $QWIKMD::atmsMol -sel "all" guessatom element mass

            $QWIKMD::atmsTable delete 0 end
            
            foreach name [$sel get name] atmtype [$sel get type] index [$sel get index ] {
                $QWIKMD::atmsTable insert end [list $index $resname $resid $chain $name $atmtype $type]
            }
            $QWIKMD::atmsTable columnconfigure 0 -editable false
            $QWIKMD::atmsTable columnconfigure 1 -editable false
            $QWIKMD::atmsTable columnconfigure 2 -editable false 
            $QWIKMD::atmsTable columnconfigure 3 -editable false
            $QWIKMD::atmsTable columnconfigure 4 -editable false
            $QWIKMD::atmsTable columnconfigure 5 -editable false
            

            ### Show the new topology
            $QWIKMD::atmsText configure -state normal
            $QWIKMD::atmsText delete 1.0 end
            set str ""
            set fil [open $strfile r]
            set str [read $fil]
            close $fil
            set str "Topology File: [file tail $strfile]\n${str}"
            $QWIKMD::atmsText insert 1.0 [format %s $str]
            $QWIKMD::atmsText configure -state disabled
            mol delete $prevatmsMol
            set QWIKMD::loadmol2 1
        }
    }
}

############################################################
## Load the mol2 file provided by the user and replace 
## the current editAtoms molecule and the ligand in the 
## topMol by this molecule. Use mol fromsel command
############################################################
proc QWIKMD::loadLigandMol2 {} {
    
    set resid [$QWIKMD::atmsTable cellcget 0,2 -text]
    set chain [$QWIKMD::atmsTable cellcget 0,3 -text]
    set ligandsel [atomselect $QWIKMD::atmsMol "all"]
    $ligandsel set chain $chain
    set protsel [atomselect $QWIKMD::topMol "all and not (resid \"${resid}\" and chain ${chain})"]

    set pretopMol $QWIKMD::topMol
    set newmol [mol fromsels [list $protsel $ligandsel]]
    #### while the return of the mol index is not implemented
    set newmol [lindex [molinfo list] end]
    set QWIKMD::topMol $newmol
    set prevname [molinfo $pretopMol get name]
    topo -molid $newmol -sel "resid \"${resid}\" and chain ${chain}" guessatom element mass
    mol reanalyze $QWIKMD::topMol
    mol rename $QWIKMD::topMol "${prevname}NewLigand"

    update
    QWIKMD::applyTopParm 0
    QWIKMD::UpdateMolTypes [expr [$QWIKMD::topGui.nbinput index current] +1]
    QWIKMD::mainTable [expr [$QWIKMD::topGui.nbinput index current] +1]

    QWIKMD::callCheckStructure
    QWIKMD::deleteAtomGuiProc
}

proc QWIKMD::checkStructur { args } {
    if {[llength $args] == 1 } {
        QWIKMD::messageWindow "Checking Structure" "Checking topologies,\
            sequence gaps, chiral centers, cis-peptide bonds and torsion angles."
    }
    set topoReport [list]
    set topo 0
    set resTable $QWIKMD::selresTable
    if {[llength $QWIKMD::rename] > 0} {
        
        foreach res $QWIKMD::rename {
            set residchain [split $res "_" ]
            set resid [lindex $residchain 0]
            set chain [lindex $residchain end]
            if {[lsearch -exact $QWIKMD::renameindex $res] == -1 \
                && [lsearch -exact $QWIKMD::delete $res] == -1 && [$resTable searchcolumn 2 $chain -check [list QWIKMD::tableSearchCheck $resid] ] > -1 } {
                set str [split $res "_"]
                lappend topoReport "Unknown topology for Residue $resid of the Chain $chain\n"
                incr topo
            }
        }
        
    } else {
        lappend topoReport "No topologies issues found\n"
    }
    set length [expr [array size QWIKMD::chains] /3]
    set txt ""
    if {[lindex $args 0] != "init"} {
        for {set i 0} {$i < $length} {incr i} {
            if {$QWIKMD::chains($i,0) == 1 && ([regexp "protein" $QWIKMD::chains($i,1)] || [regexp "nucleic" $QWIKMD::chains($i,1)] || [regexp "glycan" $QWIKMD::chains($i,1)]) } {
                append txt " ([lindex $QWIKMD::index_cmb($QWIKMD::chains($i,1),5)]) or" 
            }
        }
        set txt [string trimleft $txt " "]
        set txt [string trimright $txt " or"]
        if {$txt != ""} {
            set globalsel [atomselect $QWIKMD::topMol $txt]
            set residues [lsort -unique [$globalsel get residue]]
            $globalsel delete
            set txt "residue [join $residues]"
        }
    } else {
        set txt "not water and not ions and not ($QWIKMD::heteromcr)"
    }
    ### Prevent errors when no protein, nucleic or glycan molecules are present
    if {[string trim $txt] == ""} {
      set txt "all"
    }
    atomselect macro qwikmd_protein $QWIKMD::proteinmcr
    atomselect macro qwikmd_nucleic $QWIKMD::nucleicmcr
    atomselect macro qwikmd_glycan $QWIKMD::glycanmcr
    atomselect macro qwikmd_lipid $QWIKMD::lipidmcr
    atomselect macro qwikmd_hetero $QWIKMD::heteromcr

    set atomselectList [atomselect list]
    set generalchecks [strctcheck -mol $QWIKMD::topMol -selText $txt -qwikmd 1 ]
    set atomselectList2 [atomselect list]
    foreach select $atomselectList2 {
        if {[lsearch $atomselectList $select] == -1} {
            catch {$select delete}
        }
    }
    set QWIKMD::topoerror [list $topo $topoReport]
    if {$topo == 0} {
        set tabid [expr [$QWIKMD::topGui.nbinput index current] + 1 ]
        set maintable "$QWIKMD::topGui.nbinput.f$tabid.tableframe.tb"
        set colColor [$maintable getcolumn 4]
        set index [lsearch -all $colColor "Throb"]
        foreach row $index {
            set name "[$maintable cellcget $row,0 -text] and [$maintable cellcget $row,2 -text]"
            unset QWIKMD::index_cmb($name,2) 
            $maintable cellconfigure $QWIKMD::index_cmb($name,3),4 -text "aux"
            $maintable editcell $QWIKMD::index_cmb($name,3),4
            $maintable finishediting
        }
        
    }
    foreach check $generalchecks {
        switch [lindex $check 0] {
            chiralityerrors {
                set QWIKMD::chirerror [lindex $check 1]
            }
            cispeperrors {
                set QWIKMD::cisperror [lindex $check 1]
            }
            gaps {
                set QWIKMD::gaps [lindex $check 1]
            }
            torsionOutlier {
                set QWIKMD::torsionOutlier [lindex $check 1]
                set QWIKMD::torsionTotalResidue [lindex $check 2]
            }
            torsionMarginal {
                set QWIKMD::torsionMarginal [lindex $check 1]
            }

        }
    }
    QWIKMD::checkUpdate 
    if {[llength $args] == 1 } {
        destroy $QWIKMD::messWinGui
        update
    }
}

proc QWIKMD::checkUpdate {} {
    set do 0
    set QWIKMD::warnresid 0
    set color "green"
    set text "Topologies & Parameters"
    set colortext "black"
    if {[lindex $QWIKMD::topoerror 0] > 0} {
        set color "red"
        append text " \([lindex $QWIKMD::topoerror 0]\)"
        set colortext "blue"
        set do 1

    } 
    $QWIKMD::topolabel configure -text $text -foreground $colortext -cursor hand1
    $QWIKMD::topocolor configure -background $color

    set color "green"
    set text "Chiral Centers"
    set colortext "black"
    set number [lindex $QWIKMD::chirerror 0]
    if {$number == ""} {
        set color "yellow"
        append text " \(Failed\)"
        set colortext "blue"
        set do 1
    } elseif {$number > 0} {
        set color "yellow"
        append text " \($number\)"
        set colortext "blue"
        set do 1
        
    }

    $QWIKMD::chirlabel configure -text $text -foreground $colortext -cursor hand1
    $QWIKMD::chircolor configure -background $color  

    set color "green"
    set text "Cispetide Bond"
    set colortext "black"
    set number [lindex $QWIKMD::cisperror 0]
    if {$number == ""} {
        set color "yellow"
        append text " \(Failed\)"
        set colortext "blue"
        set do 1
    } elseif {$number > 0} {
        set color "yellow"
        append text " \($number\)"
        set colortext "blue"
        set do 1
        
    }
    $QWIKMD::cisplabel configure -text $text -foreground $colortext -cursor hand1
    $QWIKMD::cispcolor configure -background $color  

    set color "green"
    set text "Sequence Gaps"
    set colortext "black"

    if {[llength $QWIKMD::gaps] > 0} {
        set color "red"
        append text " \([llength $QWIKMD::gaps]\)"
        set colortext "blue"
        set do 1
    }
    $QWIKMD::gapslabel configure -text $text -foreground $colortext -cursor hand1
    $QWIKMD::gapscolor configure -background $color 


    ####TO-DO add label color and text for torsion outliers and marginals
    #### Tristan message :
    # This is a fairly standard scheme amongst experimental structural biologists - try running a structure of your choice past the server at http://molprobity.biochem.duke.edu/, for example.
    #  The typical rule of thumb is that a good structure should have 95% of residues in the preferred region, 5% in the allowed/marginal region, and <0.1% outliers.
    #   The actual stats the contours are based on come from a set of very high resolution crystal structures, and the cut-offs are 0.05% 2% for outliers and marginals respectively.
    #  Even if you have no outliers, going much past 5-10% marginals is a pretty good sign your structure still has some issues.
    set color "green"
    set text "Torsion Angles Outliers"
    set colortext "black"
    set numoutlier 0
    set torsionplotFail 0
    if {$QWIKMD::torsionOutlier == "Failed"} {
        set torsionplotFail 1
    }
    foreach outlier $QWIKMD::torsionOutlier {
        if {[llength [lrange $outlier 1 end]] > 0 } {
            incr numoutlier [llength [lrange $outlier 1 end]]
        }
    }
    set perc 0.0
    if {$numoutlier > 0 && $QWIKMD::torsionTotalResidue > 0} {
        set perc [format %0.2f [expr [expr $numoutlier / [expr $QWIKMD::torsionTotalResidue * 1.0]] *100]]
        set colortext "blue"
    }
    if {$torsionplotFail == 1} {
        set text "TorsionPlot Outliers check\n Failed!"
    } else {
        set text "Torsion Angles Outliers\n $perc\% \(Goal < 0.1\%\)"
    }
    #set do 1
    if {$torsionplotFail == 1} {
        set color "red"
    } elseif {$perc > 0} {
        set color "yellow"
        if {$perc >= 5} {
            set color "red"
            set do 1
        }
    }
    $QWIKMD::torsionOutliearlabel configure -text $text -foreground $colortext -cursor hand1
    $QWIKMD::torsionOutliearcolor configure -background $color 


    set color "green"
    set text "Torsion Angles Marginals"
    set colortext "black"
    set nummarginal 0
    
    foreach marginal $QWIKMD::torsionMarginal {
        if {[llength [lrange $marginal 1 end]] > 0 } {
            incr nummarginal [llength [lrange $marginal 1 end]] 
        }
    }
    set perc 0.0
    if {$nummarginal > 0 && $QWIKMD::torsionTotalResidue > 0} {
        set perc [format %0.2f [expr [expr $nummarginal / [expr $QWIKMD::torsionTotalResidue * 1.0] ] *100]]
        set colortext "blue"
    }
    if {$torsionplotFail == 1} {
        set text "TorsionPlot Marginals check\n Failed!"
    } else {
        set text "Torsion Angles Marginals\n $perc\% \(Goal < 5\%\)"
    }
    #set do 1
    if {$torsionplotFail == 1} {
        set color "red"
    } elseif {$perc > 0} {
        set color "yellow"
        if {$perc >= 10} {
            set color "red"
            set do 1
        }
    }

    $QWIKMD::torsionMarginallabel configure -text $text -foreground $colortext -cursor hand1
    $QWIKMD::torsionMarginalcolor configure -background $color
    
    if {$do == 1} {
        tk_messageBox -message "One or more warnings were generated during structure check routines.\
        \nPlease refer to the \"Structure Manipulation/Check\" window to fix them" -title "Structure Check" \
        -parent $QWIKMD::topGui -icon warning -type ok
        set QWIKMD::warnresid 1
    }
}

proc QWIKMD::changecomboType {w} {
    set table $QWIKMD::topoPARAMGUI.f1.tableframe.tb
    set combo $w
    set type [$combo get]
    set row ""

    if {$type == "other..."} {
        
        set frame [string trimright $w ".r"]
        destroy $frame
        set type "other..."
        set names [$table columncget 1 -text]

        for {set i 0} {$i < [llength $names]} {incr i} {
            set charmmres [split [lindex $names $i] "->"]
            set charmmres [string trimright [lindex $charmmres 0]]
            if {$QWIKMD::topocombolist($charmmres) == $w} {
                set row $i
                break
            }
        }
        
        if {[llength $QWIKMD::topparmTable] == 0} {
            $QWIKMD::topoPARAMGUI.f1.tableframe.tb selection set $row
            lappend QWIKMD::topparmTable $row
        }
        
        $QWIKMD::topoPARAMGUI.f1.tableframe.tb selection set $QWIKMD::topparmTable
        $QWIKMD::topoPARAMGUI.f1.tableframe.tb cellconfigure $row,2 -editable true
        $QWIKMD::topoPARAMGUI.f1.tableframe.tb editcell $row,2
    } else {
        set names [$table columncget 1 -text]
        set row [lindex [$table editinfo] 1]
        if {$row == -1} {
            for {set i 0} {$i < [llength $names]} {incr i} {
                set charmmres [split [lindex $names $i] "->"]
                set charmmres [string trimright [lindex $charmmres 0]]
                if {$QWIKMD::topocombolist($charmmres) == $w} {
                    set row $i
                    break
                }
            }
        }
            
        if {[llength $QWIKMD::topparmTable] == 0} {
            $QWIKMD::topoPARAMGUI.f1.tableframe.tb selection set $row
            lappend QWIKMD::topparmTable $row
        }
        if {[string length $type] > 10 || [llength $type] > 1 || $type == ""} {
            tk_messageBox -message "Residue type must be at maximum 10 characters long.\
            \nPlease make sure that spaces characters are not included. Selected residues will\
            set as hetero" -title "Residue Type" -icon info -type ok -parent $QWIKMD::topoPARAMGUI
            set QWIKMD::topparmTableError 1
            set type "hetero"
        }  
        set answer "yes"
        if {$type == "protein" && [$table cellcget $row,0 -text] != [$table cellcget $row,1 -text]} {
            set answer [tk_messageBox -message "Protein residues must have the same denomination as the CHARMM residues names.\n\
            Do you want to continue and change the Residues Denomination?" -title "Residue Type" -icon info -type yesno -parent $QWIKMD::topoPARAMGUI]
            update idletasks 
        }
        for {set i 0} {$i < [llength $QWIKMD::topparmTable]} {incr i} {
            set charmmres [split [lindex $names [lindex $QWIKMD::topparmTable $i]] "->"]
            set charmmres [string trimright [lindex $charmmres 0]]
            if {[winfo exists $QWIKMD::topocombolist($charmmres)] == 0} {
                $table cellconfigure [lindex $QWIKMD::topparmTable $i],2 -window QWIKMD::editType
            }

            $QWIKMD::topocombolist($charmmres) set $type
            $QWIKMD::topocombolist($charmmres) selection clear
            if {$answer == "yes" && $type == "protein"} {
                $table cellconfigure [lindex $QWIKMD::topparmTable $i],0 -text [$table cellcget [lindex $QWIKMD::topparmTable $i],1 -text]
                
            } elseif {$answer == "no"} {
                $QWIKMD::topocombolist($charmmres) set "hetero"
                return
            }
        }
        
        set QWIKMD::topparmTable [list]
        $QWIKMD::topoPARAMGUI.f1.tableframe.tb selection clear 0 end
    }
}
proc QWIKMD::editType {tbl row col w} {
    set type [$tbl cellcget $row,$col -text]
    set values {protein nucleic glycan lipid hetero other...}
    set defVal {protein nucleic glycan lipid hetero}
    if {$QWIKMD::userMacros != ""} {
        set i 0
        foreach aux $QWIKMD::userMacros {
            if {[lsearch $defVal [lindex $aux 0]] ==-1} {
                set values "[lrange $values 0 [expr [llength $values] -2]] [lindex $aux 0] [lindex $values end]"
            }
            incr i
        } 
    }
    grid [ttk::frame $w] -sticky news
    
    ttk::style map resid.TCombobox -fieldbackground [list readonly #ffffff]
    grid [ttk::combobox $w.r -state readonly -style resid.TCombobox -values $values -width 11 -justify center -postcommand {set QWIKMD::topparmTable [$QWIKMD::topoPARAMGUI.f1.tableframe.tb curselection]}] -row 0 -column 0
    
    set txt [$tbl cellcget $row,3 -text]
    set index 0
    set typeindex [lsearch $values $type]
    if {$type > -1 && $type != "type?"} {
        set index $typeindex
    } elseif {[string match "*prot*" $txt] > 0} {
        set index 0
    } elseif {[string match "*na*" $txt] > 0} {
        set index 1
    } elseif {[string match "*carb*" $txt] > 0} {
        set index 2
    } else {
        set index 3
    } 
   
    $w.r set [lindex $values $index]
    $tbl cellconfigure $row,$col -text ""
    $tbl configure -labelcommand ""
    bind $w.r <<ComboboxSelected>> {
        QWIKMD::changecomboType %W
    }
    set QWIKMD::topocombolist([$tbl cellcget $row,1 -text]) $w.r
}
##########################################################
## Review the atomselect macros definition. Reset == 1
## will overwrite the the current definitions 
## gui == 0 allows other plugin to using the topoplogies
##########################################################
proc QWIKMD::reviewTopPar {reset {gui 1} } {
    global env

    if {$reset == 1} {
        set defVal {protein nucleic glycan lipid hetero}
        if {[llength $QWIKMD::userMacros] >0} {
            foreach macro $QWIKMD::userMacros {
                if {[lsearch $defVal [lindex $macro 0]] == -1} {
                    atomselect delmacro [lindex $macro 0]
                }
            }
        }
        set QWIKMD::userMacros ""
    }
    if {[file exists ${env(QWIKMDFOLDER)}/toppar/toppartable.txt] == 1} {
        set toppartable [open ${env(QWIKMDFOLDER)}/toppar/toppartable.txt r]
        set temp [read -nonewline $toppartable ]
        close $toppartable
        set temp [split $temp "\n"]
        ## Remove comments and empty lines
        set tempaux [list]
        foreach line $temp {
            set comp [string trim $line " "]
            if {[string length $comp] > 0 && [string index $comp 0] != "#"} {
                lappend tempaux $line 
            } 
        }
        set temp $tempaux
        if {$reset == 1} {
            foreach line $temp {
                set fileentry [file join ${env(QWIKMDFOLDER)}/toppar [lindex $line 3]]
                if {[lsearch $QWIKMD::TopList ${fileentry}] == -1} {
                    lappend QWIKMD::TopList ${fileentry}
                }
                if {[lsearch $QWIKMD::ParameterList ${fileentry}] == -1 && ([file extension ${fileentry}] == ".str" || [file extension ${fileentry}] == ".prm")} {
                    lappend QWIKMD::ParameterList ${fileentry}
                }
                set typeindex [lsearch $defVal [lindex $line 0]]
                set macroindex [lsearch -index 0 $QWIKMD::userMacros [lindex $line 2]]
                if { $macroindex == -1} {
                    ## text = {<Molecule Type> <CHRAMM Name> <Residue Name> <Topology File Name>}
                    set txt [list [lindex $line 2] [list [lindex $line 1]] [list [lindex $line 0]] [list [lindex $line 3]]]
                    lappend QWIKMD::userMacros $txt
                } elseif {$macroindex != -1} {
                    set aux [lindex $QWIKMD::userMacros $macroindex]
                    set aux [list [lindex $aux 0] [concat [lindex $aux 1] [lindex $line 1]] [concat [lindex $aux 2] [lindex $line 0]] [concat [lindex $aux 3] [lindex $line 3]]]
                    lset QWIKMD::userMacros $macroindex $aux
                }
            }
        }
        foreach macro $QWIKMD::userMacros {
            set textaux ""
            set do 0
            switch [lindex $macro 0] {
                protein {
                    set QWIKMD::proteinmcr [string trimright [string trimleft $QWIKMD::proteinmcr "("] ")"]
                    foreach resname [lindex $macro 1] {
                        if {[lsearch $QWIKMD::proteinmcr ${resname}\)] == -1} {
                            if {$do == 0} {
                                set textaux "$QWIKMD::proteinmcr"
                                set do 1
                            }
                            append textaux " or (resname $resname) "
                        }   
                    }
                    if {$do == 0} {
                        set QWIKMD::proteinmcr "\($QWIKMD::proteinmcr\)"
                    }
                }
                glycan {
                    set QWIKMD::glycanmcr [string trimright [string trimleft $QWIKMD::glycanmcr "("] ")"]
                    foreach resname [lindex $macro 1] {
                        if {[lsearch $QWIKMD::glycanmcr ${resname}\)] ==-1} {
                            if {$do == 0} {
                                append textaux "$QWIKMD::glycanmcr"
                                set do 1
                            }
                            append textaux " or (resname $resname) "
                        }   
                    }
                    if {$do == 0} {
                        set QWIKMD::glycanmcr "\($QWIKMD::glycanmcr\)"
                    }
                }
                lipid {
                    set QWIKMD::lipidmcr [string trimright [string trimleft $QWIKMD::lipidmcr "("] ")"]
                    foreach resname [lindex $macro 1] {
                        if {[lsearch $QWIKMD::lipidmcr ${resname}\)] ==-1} {
                            if {$do == 0} {
                                append textaux "$QWIKMD::lipidmcr"
                                set do 1
                            }
                            append textaux " or (resname $resname) "
                        }   
                    }
                    if {$do == 0} {
                        set QWIKMD::lipidmcr "\($QWIKMD::lipidmcr\)"
                    }
                }
                nucleic {
                    set QWIKMD::nucleicmcr [string trimright [string trimleft $QWIKMD::nucleicmcr "("] ")"]
                    foreach resname [lindex $macro 1] {
                        if {[lsearch $QWIKMD::nucleicmcr ${resname}\)] ==-1} {
                            if {$do == 0} {
                                append textaux "$QWIKMD::nucleicmcr"
                                set do 1
                            }
                            append textaux " or (resname $resname) "
                        }   
                    }
                    if {$do == 0} {
                        set QWIKMD::nucleicmcr "\($QWIKMD::nucleicmcr\)"
                    }
                }
                hetero {
                    set QWIKMD::heteromcr [string trimright [string trimleft $QWIKMD::heteromcr "("] ")"]
                    foreach resname [lindex $macro 1] {
                        if {[lsearch $QWIKMD::heteromcr ${resname}\)] == -1} {
                            if {$do == 0} {
                                append textaux "$QWIKMD::heteromcr"
                                set do 1
                            }
                            append textaux " or (resname $resname) "
                        }   
                    }
                    if {$do == 0} {
                        set QWIKMD::heteromcr "\($QWIKMD::heteromcr\)"
                    }
                }
                default {
                    atomselect macro [lindex $macro 0] "(resname [lindex $macro 1])"
                }

            }
            if {$do == 0} {
                continue
            }
            switch [lindex $macro 0] {
                protein {
                    set QWIKMD::proteinmcr "\($textaux\)"
                }
                glycan {
                    set QWIKMD::glycanmcr "\($textaux\)"
                }
                lipid {
                    set QWIKMD::lipidmcr "\($textaux\)"
                }
                nucleic {
                    set QWIKMD::nucleicmcr "\($textaux\)"
                }
                hetero {
                    set QWIKMD::heteromcr "\($textaux\)"
                }
            }
        }
    }
    
}

proc QWIKMD::deleteTopParm {} {
    global env
    set rowlist [$QWIKMD::topoPARAMGUI.f1.tableframe.tb curselection]
    set filenamelist [list] 
    foreach row $rowlist {
        set newfile [$QWIKMD::topoPARAMGUI.f1.tableframe.tb cellcget $row,3 -text]
        if {[lsearch $filenamelist $newfile] == -1} {
            lappend filenamelist $newfile
        }
    }
    $QWIKMD::topoPARAMGUI.f1.tableframe.tb delete $rowlist

    set currentfilename [lsort -unique [$QWIKMD::topoPARAMGUI.f1.tableframe.tb getcolumns 3]]
    foreach filename $filenamelist {
        if {[lsearch $currentfilename $filename] == -1} {
            if {[file exists ${env(QWIKMDFOLDER)}/toppar/$filename] == 1} {
                file delete -force ${env(QWIKMDFOLDER)}/toppar/$filename
            }
        }
    }
}
     
proc QWIKMD::starteditType {tbl row col txt} {
    if {$col == 1} {
        set entry [split $txt "->"]     
        set txt [string trimright [lindex $entry 0]]
    }
    return $txt
}
proc QWIKMD::editResNameType {tbl row col txt} {
    if {$col == 0 || $col ==1} {
        set resname [$tbl columncget 0 -text]
        if {$col == 1} {
            set resname [list]
            foreach res [$tbl columncget 1 -text] {
                lappend resname [lindex [split $res "->"] end]      
            }
        }
        
        if {$txt == ""} {
            set txt [lindex [split [$tbl cellcget $row,1 -text] "->"] end]
            if {$col == 1} {
                set txt [$tbl cellcget $row,0 -text]
            }
        } else {
            set do 1
            if {[lsearch -all $QWIKMD::carb $txt] > 0 || [lsearch -all $QWIKMD::carbnames $txt] > 0} {
                set do 0
            } elseif {[lsearch -all $QWIKMD::hetero $txt] >= 0  || [lsearch -all $QWIKMD::heteronames $txt] > 0} {
                set do 0
            } elseif {[lsearch -all $QWIKMD::nucleic $txt] >= 0} {
                set do 0
            } elseif {[lsearch -all $QWIKMD::lipidname $txt] >= 0} {
                set do 0
            } elseif {[lsearch -all $QWIKMD::reslist $txt] >= 0} {
                set do 0
            } elseif {[lsearch -all $resname $txt] >= 0 && [lsearch -all $resname $txt] != $row} {
                set do 0
            }
            if {$do == 0} {
                set title "Residue Name"
                if {$col == 1} {
                    set title "CHARMM Name"
                }
                tk_messageBox -message "The name \"$txt\" is already in use.\n Please make sure that the chosen name is unique."\
                 -title $title  -icon info -type ok -parent $QWIKMD::editATMSGui
                set QWIKMD::topparmTableError 1
                set txt [lindex [split [$tbl cellcget $row,1 -text] "->"] end]
                if {$col == 1} {
                    set txt [$tbl cellcget $row,0 -text]
                }
                $tbl selection clear 0 end
            } else {
                set max 10
                set str $txt
                if {$col == 1} {
                    set max 4
                    set str [split $txt "->"]
                    if {[llength $str] > 1} {
                        set str [string trimright [lindex $str 1]]
                    }

                }
                if {( [string length $str] > $max || [llength $str] > 1)} {
                    if {[llength $str] > 1} {
                        set txt [lindex $str 0]
                    }
                    if {[string length $str] > $max} {
                        set txt [string range $str 0 [expr $max -1]]
                    } else {
                        set txt [string range $str 0 end]
                    }
                    tk_messageBox -message "Residue denomination must be at maximum $max characters long.\
                    \n Please make sure that spaces and/or special characters are not included." -title "Residue Name"\
                     -icon info -type ok -parent $QWIKMD::editATMSGui
                    set QWIKMD::topparmTableError 1
                    if {$col == 1} {
                        $tbl cellconfigure $row,1 -background red
                    }

                }
            } 

            if {$do ==1 && $col == 0} {
                set charmmres [split [$tbl cellcget $row,1 -text] "->"]
                set charmmres [string trimright [lindex $charmmres 0]]
                if {([$QWIKMD::topocombolist($charmmres) get] == "protein" || [$QWIKMD::topocombolist($charmmres) get] == "nucleic" || [$QWIKMD::topocombolist($charmmres) get] == "lipid") &&  $txt != [$tbl cellcget $row,1 -text]} {
                    tk_messageBox -message "[$QWIKMD::topocombolist($charmmres) get] residues must have the same name as the CHARMM\
                     residues names.\nPlease change residues denomination" -title "Residue Type" -icon info -type ok -parent $QWIKMD::editATMSGui
                    set QWIKMD::topparmTableError 1
                    update idletasks
                    set txt [$QWIKMD::topoPARAMGUI.f1.tableframe.tb cellcget $row,1 -text]
                    update idletasks
                    return $txt
                }
            } elseif {$do ==1 && $col == 1} {
                set prev [$tbl cellcget $row,$col -text]
                set prev [split $prev "->"]
                set charmmres [split [$tbl cellcget $row,1 -text] "->"]
                set charmmres [string trimright [lindex $charmmres 0]]

                if {$txt != [string trimright [lindex $prev 0]]} {
                    
                    $tbl cellconfigure $row,1 -background white
                    set txt "[string trimright [lindex $prev 0]] -> $txt"
                    
                }
                if {([$QWIKMD::topocombolist($charmmres) get] == "protein" || [$QWIKMD::topocombolist($charmmres) get] == "nucleic" || [$QWIKMD::topocombolist($charmmres) get] == "lipid") &&  $txt != [$tbl cellcget $row,1 -text]} {
                    tk_messageBox -message "[$QWIKMD::topocombolist($charmmres) get] residues must have the same name as\
                     the CHARMM residues names.\nPlease change residues denomination" -title "Residue Type" -icon info -type ok -parent $QWIKMD::topoPARAMGUI
                    set QWIKMD::topparmTableError 1
                    $tbl cellconfigure $row,0 -text [lindex [split $txt "->"] end] 
                }
                return $txt
            }
        }
        $tbl selection clear 0 end
        return $txt
    }  elseif {$col == 2} {
        QWIKMD::changecomboType [$tbl editwinpath]
    }
    
}

proc QWIKMD::addTopParm {fil} {
    if {$fil != ""} {
        set table $QWIKMD::topoPARAMGUI.f1.tableframe.tb
        set infile [open ${fil} r]
        set all [regsub {"} [read $infile] ""]
        set val [split $all "\n"]
        set domessage 0
        for {set i 0} {$i < [llength $val]} {incr i} {
            
            if {[string range [lindex $val $i] 0 0] != "!"} {
                
                if { [lindex [lindex $val $i] 0] == "RESI"} {
                    set do 1
                    set res [lindex [lindex $val $i] 1]
                    if {[QWIKMD::checkresidueTop $res 0 "$QWIKMD::topoPARAMGUI"] == 1} {
                        set do 0
                    } elseif {[lsearch -all [$table columncget 1 -text] $res] >=0} {
                        set do 0
                    }

                    if {$do == 1} {
                        $table insert end "$res $res type? {}"
                        $table cellconfigure end,3 -text ${fil}
                        $table cellconfigure end,2 -window QWIKMD::editType
                        if {[info exists QWIKMD::charmmchange([file tail ${fil}])] != 1} {
                            set QWIKMD::charmmchange([file tail ${fil}],0) [list]
                        }
                        lappend QWIKMD::charmmchange([file tail ${fil}],0) $res
                    }
                    if {[string length $res] > 4} {
                        $table cellconfigure end,1 -background red
                        $table cellconfigure end,1 -editable true -editwindow ttk::entry 
                        $table configure -editstartcommand QWIKMD::starteditType
                        set domessage 1
                    }
                }
            }
        }
        if {$domessage == 1} {
            tk_messageBox -message "Some residue's name contain more than 4 characters (in red).\
            \nPlease choose an unique 4 character residue name." -title "Residue Name" -icon info -type ok -parent $QWIKMD::topoPARAMGUI
        }
        close $infile
    }
}

proc QWIKMD::applyTopParm { {drawwindow 1} } {
    global env
    set table $QWIKMD::topoPARAMGUI.f1.tableframe.tb

    #check if table has any element
    if {[$table size] != 0} {
        # check if the tablelist has an editcell operation in place
        # the command pathname editinfo return {{} -1 -1} if no cell is being edit 
        if {[lindex [$table editinfo] 1] != -1 } {
            $table finishediting
        }

        if {$QWIKMD::topparmTableError == 1} {
            wm deiconify $QWIKMD::topoPARAMGUI
            tk_messageBox -message "An error was generated when applying modifications. Please revise and apply again." \
            -icon error -type ok -parent $QWIKMD::topoPARAMGUI
            set QWIKMD::topparmTableError 0
            return
        }
        if {$drawwindow == 1} {
            set answer [tk_messageBox -message "The topologies and parameters of the molecules listed in the table will be added \
            to \n QwikMD library. Do you want to continue?" -title "Topologies and Parameters" -icon warning -type yesno -parent $QWIKMD::topoPARAMGUI]

            if {$answer == "no"} {
                return
            }
        }
    }

    set resname [$table columncget 0 -text]
    set charmmres [$table columncget 1 -text]
    set tbfile [$table columncget 3 -text]
    set indexes ""
    set i 0
    foreach res $charmmres {
        set prev [split $res "->"]
        if {[llength $prev] == 1 && [string length $prev] > 4} {
            lappend indexes $res
            $table cellconfigure $i,1 -background red
        }
        incr i
    }

    if {$indexes != ""} {
        wm deiconify $QWIKMD::topoPARAMGUI
        tk_messageBox -message "Please change the CHARMM residue names of $indexes." -title "Residue Name" -icon info -type ok -parent $QWIKMD::topoPARAMGUI
        return
    }
    
    set toppartable [open ${env(QWIKMDFOLDER)}/toppar/toppartable.txt w+]
    QWIKMD::printTopParHeader $toppartable
    set i 0

    set prevfile [lindex $tbfile 0]
    set charoriginal [list]
    set charreplace [list]
    foreach res $resname chares ${charmmres} srcfile $tbfile {
        set filename ""
        if {[string first "_qwikmd" [file root [file tail ${srcfile}]]] == -1} {
            set filename  [file root [file tail ${srcfile}]]_qwikmd[file extension ${srcfile}]
        } else {
            set filename  [file root [file tail ${srcfile}]][file extension ${srcfile}]
        }
        
        set prev [split $chares "->"]
        set reoriginal $chares
        set curreplace $chares
        if {[llength $prev] > 1} {
            lappend charoriginal [string trimright [lindex $prev 0]]
            lappend charreplace [string trimleft [lindex $prev end]]
            set reoriginal [lindex $charoriginal end]
            set curreplace [lindex $charreplace end]
        }
        
        if {[file dirname ${srcfile}] != "."} {
            set file ${env(QWIKMDFOLDER)}/toppar/${filename}
            set fileincr 1
            set filenameaux $filename

            while {[file exists $file] == 1} {
                set filenameaux [file root ${filename}]_${fileincr}[file extension ${filename}]
                set file ${env(QWIKMDFOLDER)}/toppar/${filenameaux}
                incr fileincr
            }
            set filename $filenameaux
            puts $toppartable "$res\t$curreplace\t[$QWIKMD::topocombolist($reoriginal) get]\t${filename}"
            incr i
            if {$srcfile != $prevfile || $i == [$table size] } {
                set f [open ${srcfile} "r"]
                set txt [read -nonewline ${f}]
                set txt [split $txt "\n"]
                if {[llength $charoriginal] > 0} {
                    set enter ""
                    set index [lsearch -exact -all $txt $enter]
                    for {set j 0} {$j < [llength $index]} {incr j} {
                        lset txt [lindex $index $j] "{} {}"
                    }
                }           
                set out [open $file w+ ]
                foreach original $charoriginal replace $charreplace {
                    set resi "RESI"
                    set index [lsearch -regexp -all $txt (?i)^$resi]
                    
                    foreach ind $index {
                        if {[lindex [lindex $txt $ind] 1 ] == $original} {
                            set strreplace [lindex $txt $ind]
                            lset strreplace 1 $replace
                            lset txt $ind [join $strreplace]
                        }
                    }
                }
                
                if {[llength $charoriginal] > 0} {
                    set enter "{} {}"
                    set index [lsearch -exact -all $txt $enter]
                    for {set j 0} {$j < [llength $index]} {incr j} {
                        lset txt [lindex $index $j] " "
                    }
                
                }
                for {set j 0 } {$j < [llength $txt]} {incr j} {
                    puts $out [lindex $txt $j]
                }
                close $f
                close $out
                set charoriginal [list]
                set charreplace [list]
            }
        } else {
            puts $toppartable "$res\t$curreplace\t[$QWIKMD::topocombolist($reoriginal) get]\t${filename}"
            incr i
            set prevfile [lindex $tbfile $i]
        }
    }
    close $toppartable
    set QM [lsearch -index 0 $QWIKMD::userMacros "QM"]
    if {$QM != -1} {
        set QMMacro [lindex $QWIKMD::userMacros $QM]
    }
    QWIKMD::reviewTopPar 1
    QWIKMD::loadTopologies
    QWIKMD::addTableTopParm
    if {$QM != -1} {
        set QWIKMD::userMacros [concat $QWIKMD::userMacros [list $QMMacro]]
    }
    if {$drawwindow == 1} {
        tk_messageBox -message "To ensure the proper load of the topologies, please reset QwikMD."\
        -title "Topology Added"  -icon info -type ok -parent $QWIKMD::topoPARAMGUI
    }
}
#############################################################################
## Check if the residue name is already defined in the topology files
## sendMessage checks if a tk_messageBox will be generated and if the command
## was triggered during the topology generation process
## sendMessage == 0, silent check
## sendMessage == 1, applyTopParm command,
## sendMessage == 2, generateTopology
#############################################################################
proc QWIKMD::checkresidueTop {charmmres sendMessage parentwindow} {
    ## check if the residue name already exists
    set found 0
    if {[lsearch $QWIKMD::reslist $charmmres] != -1 || \
        [lsearch $QWIKMD::hetero $charmmres] != -1 ||
        [lsearch $QWIKMD::nucleic $charmmres] != -1 || 
        [lsearch $QWIKMD::lipidname $charmmres] != -1 ||
        [lsearch $QWIKMD::carb $charmmres] != -1} {
            set found 1

    } else {
        foreach macro $QWIKMD::userMacros {
            if {[lsearch [lindex $macro 1] $charmmres] != -1 && [lindex $macro 0] != "QM"} {
                set found 1
                break
            }
        }
    }
    if {$found == 0 && $sendMessage == 2} {
        foreach topo $QWIKMD::topoinfo {
            set reslist [::Toporead::topology_get resnames $topo]
            if {[lsearch $reslist $charmmres] != -1} {
                set found 1
                break
            }
        }
    }
    if {$found ==1} {
        if {$sendMessage >=1} {
            tk_messageBox -message "The name \"$charmmres\" was already used to define a residue or a patch." -title "Residue Name" -icon info -type ok -parent $parentwindow
        }
        return 1
    }

    return 0
}
proc QWIKMD::addTableTopParm {} {
    global env
    if {$QWIKMD::userMacros != ""} {
        set table $QWIKMD::topoPARAMGUI.f1.tableframe.tb
        set toppartable [open ${env(QWIKMDFOLDER)}/toppar/toppartable.txt r]
        $table delete 0 end
        foreach macro $QWIKMD::userMacros {
            foreach res [lindex $macro 2] charres [lindex $macro 1] file [lindex $macro 3] {
                $table insert end [list $res $charres [lindex $macro 0] $file]
                $table cellconfigure end,0 -editable true
                $table cellconfigure end,0 -editwindow ttk::entry
                $table cellconfigure end,2 -window QWIKMD::editType
            }
            
        }
        close $toppartable
    }
}

proc QWIKMD::PrepareStructures {prefix textLogfile} {
    cd $QWIKMD::outPath/setup/
    set structure $QWIKMD::topMol
    set name ""
    set tabid [$QWIKMD::topGui.nbinput index current]

    set solvent ""
    if {$tabid == 0} {
        set solvent $QWIKMD::basicGui(solvent,$QWIKMD::run,0)
    } else {
        set solvent $QWIKMD::advGui(solvent,$QWIKMD::run,0)
    }
    ## If starting from a pdb and not from a previously loaded trajectory
    if {$QWIKMD::load == 0} {
        set length [expr [array size QWIKMD::chains] /3]
        set txt ""
        for {set i 0} {$i < $length} {incr i} {
            if {$QWIKMD::chains($i,0) == 1} {
                append txt " ([lindex $QWIKMD::index_cmb($QWIKMD::chains($i,1),5)]) or" 
            }
            
        }
        set txt [string trimleft $txt " "]
        set txt [string trimright $txt " or"]
        if {$QWIKMD::membraneFrame != ""} {
            set structure $QWIKMD::membraneFrame
            append txt " or \(chain W L\)"  
        }
        set sel [atomselect $structure $txt]
        
        if {[llength $QWIKMD::renameindex] > 0} {
            puts $textLogfile [QWIKMD::renameLog]
        }

        for {set i 0} {$i < [llength $QWIKMD::renameindex]} {incr i} {
            set val [split [lindex $QWIKMD::renameindex $i] "_"]
            
            set sel_rename [atomselect $structure "resid \"[lindex $val 0]\" and chain \"[lindex $val 1]\""]
            $sel_rename set resname $QWIKMD::dorename([lindex $QWIKMD::renameindex $i])
            $sel_rename delete 
        }

        if {$QWIKMD::membraneFrame != ""} {
            
            set lipid [atomselect $structure "chain L and lipid"]
            set resid 1
            set prev ""
            foreach residue [$lipid get residue]  {
                set txt " $residue"
                if {$prev != $txt} {
                    set selaux [atomselect $structure "(residue $residue and chain L and lipid)"]
                    $selaux set resid $resid
                    $selaux set segname "L"
                    incr resid
                    $selaux delete
                    set prev $residue
                }
            }
            $lipid delete
        }
        set topfiles [list]
        foreach files $QWIKMD::TopList {
            lappend topfiles [file tail $files]
        }

        if {[llength $QWIKMD::atmsRenameLog] > 0 || [llength $QWIKMD::atmsReorderLog] > 0 || [llength $QWIKMD::autorenameLog] > 0 || [llength $QWIKMD::atmsDeleteLog] > 0} {
            puts $textLogfile [QWIKMD::renameReorderAtomLog]
        }

        set stfile [lindex [molinfo [molinfo top] get filename] 0]
        set sel_tem "[file tail [file root [lindex $stfile 0] ] ]_sel.pdb"
        $sel set beta 0
        $sel set occupancy 0 

        ## Check if QM molecule types were selected
        set topoqmselected 0
        if {$tabid == 1 && $QWIKMD::run == "MD" && [lsearch -index 0 $QWIKMD::userMacros "QM"] > -1\
         &&  [lindex [lsort -unique -integer [$sel get "QM"]] end] == 1} {
            set topoqmselected 1
            puts $QWIKMD::textLogfile [QWIKMD::printTempTopo]
            flush $QWIKMD::textLogfile 
        }

        $sel writepdb $sel_tem
        $sel delete

        set structure [mol new $sel_tem waitfor all]
        display update on

        display update ui

        set sel_aux [atomselect $structure "qwikmd_protein or qwikmd_nucleic or qwikmd_glycan or qwikmd_lipid"]
        set segments [lsort -unique [$sel_aux get segname]]
        $sel_aux delete
        set mutate ""
        for {set i 0} {$i < [llength $QWIKMD::mutindex]} {incr i} {
            set chain [lindex [split [lindex $QWIKMD::mutindex $i] "_"] end]
            set index [lsearch $segments $chain\*]
            set residchain [split [lindex $QWIKMD::mutindex $i] "_" ]
            lappend mutate "[lindex $residchain 1] [lindex $residchain 0] [lindex $QWIKMD::mutate([lindex $QWIKMD::mutindex $i]) 1]"
        }

        

        if {[llength $QWIKMD::mutindex] > 0} {
            puts $textLogfile [QWIKMD::mutateLog]
        }
        for {set i 0} {$i < [llength $QWIKMD::protindex]} {incr i} {
            if {[lindex $QWIKMD::protonate([lindex $QWIKMD::protindex $i]) 1] == "HSP" || \
                [lindex $QWIKMD::protonate([lindex $QWIKMD::protindex $i]) 1] == "HSE" || [lindex $QWIKMD::protonate([lindex $QWIKMD::protindex $i]) 1] == "HSD" } {

                set chain [lindex [split [lindex $QWIKMD::protindex $i] "_"] end]
                set index [lsearch $segments $chain\*]
                set residchain [split [lindex $QWIKMD::protindex $i] "_" ]
                lappend mutate "[lindex $residchain 1] [lindex $residchain 0] [lindex $QWIKMD::protonate([lindex $QWIKMD::protindex $i]) 1]"
            }
        }
        

        if {$QWIKMD::membraneFrame != ""} {
            puts $textLogfile [QWIKMD::membraneLog]
        }

        if {[llength $QWIKMD::protindex] > 0} {
            puts $textLogfile [QWIKMD::protonateLog]
        }
        set patches [list]

        ################################################################################
        ## the protonation state is now changed through autopsf using the patch flag
        ## and not after autopsf and by QwikMD
        ################################################################################

        for {set i 0} {$i < [llength $QWIKMD::protindex]} {incr i} {
            set residchain [split [lindex $QWIKMD::protindex $i] "_" ]
            set chain [lindex $residchain end]
            set resid [lindex $residchain 0]

            if {[lindex $QWIKMD::protonate([lindex $QWIKMD::protindex $i]) 1] != "HSP" && \
                [lindex $QWIKMD::protonate([lindex $QWIKMD::protindex $i]) 1] != "HSE" && [lindex $QWIKMD::protonate([lindex $QWIKMD::protindex $i]) 1] != "HSD" } {
                lappend patches "[lindex $QWIKMD::protonate([lindex $QWIKMD::protindex $i]) 1] $chain [lindex $residchain 0]"
            }
            
        } 
        if {[llength $QWIKMD::patchestr] > 0} {
            set patches [concat $patches $QWIKMD::patchestr]
            puts $textLogfile [QWIKMD::patchLog]
        }
        # set nlines [expr [lindex [split [${QWIKMD::selresPatche}.text index end] "."] 0] -1]
        # set patchtext [split [${QWIKMD::selresPatche}.text get 1.0 $nlines.end] "\n"]
        # set patchaux [list]
        # if {[lindex $patchtext 0] != ""} {
        #   foreach patch $patchtext {
        #       if {$patch != ""} {
        #           lappend patchaux $patch
        #       }
        #   }
            
        # }

        set hetero $QWIKMD::heteromcr
        set protein $QWIKMD::proteinmcr
        set nucleic $QWIKMD::nucleicmcr
        set glycan $QWIKMD::glycanmcr
        set lipid $QWIKMD::lipidmcr
        if {[llength $QWIKMD::userMacros] >0} {
            foreach macro $QWIKMD::userMacros {
                switch $macro {
                    protein {
                        append QWIKMD::proteinmcr " or [lindex $macro 0]"
                        atomselect macro qwikmd_protein $QWIKMD::proteinmcr
                    }
                    nucleic {
                        append QWIKMD::nucleicmcr " or [lindex $macro 0]"
                        atomselect macro qwikmd_nucleic $QWIKMD::nucleicmcr
                    }
                    glycan {
                        append QWIKMD::glycanmcr " or [lindex $macro 0]"
                        atomselect macro qwikmd_glycan $QWIKMD::glycanmcr
                    }
                    lipid {
                        append QWIKMD::lipidmcr " or [lindex $macro 0]"
                        atomselect macro qwikmd_lipid $QWIKMD::lipidmcr
                    }
                    default {
                        append QWIKMD::heteromcr " or [lindex $macro 0]"
                        atomselect macro qwikmd_hetero $QWIKMD::heteromcr
                    }
                }
            }
        }
        
        set atpsfOk ""
        set autopsfLog ""

        #set atpsfLogFile [open "StructureFile.log" w+]
     
        #set cmd "autopsf -mol ${structure} -prefix ${prefix} -top [lreverse [list ${topfiles}]] -patch [list ${patches}] -regen -mutate [list ${mutate}] -qwikmd"
        
        #set atpsfOk [QWIKMD::redirectPuts $atpsfLogFile $cmd]
        set autopsfLog ""
        set atpsfOk [catch {autopsf -mol ${structure} -prefix ${prefix} -top [join $topfiles] -patch ${patches} -regen -mutate ${mutate} -qwikmd} autopsfLog ]
        #close $atpsfLogFile
        if {$atpsfOk >= 1} {
            return [list 1 "Autopsf error $autopsfLog"]
        }

        if {[llength $QWIKMD::userMacros] > 0} {
            foreach macro $QWIKMD::userMacros {
                switch $macro {
                    protein {
                        set QWIKMD::proteinmcr $protein
                        atomselect macro qwikmd_protein $QWIKMD::proteinmcr
                    }
                    nucleic {
                        set QWIKMD::nucleicmcr $nucleic
                        atomselect macro qwikmd_nucleic $QWIKMD::nucleicmcr
                    }
                    glycan {
                        set QWIKMD::glycanmcr $glycan
                        atomselect macro qwikmd_glycan $QWIKMD::glycanmcr
                    }
                    lipid {
                        set QWIKMD::lipidmcr $lipid
                        atomselect macro qwikmd_lipid $QWIKMD::lipidmcr
                    }
                    default {
                        set QWIKMD::heteromcr $hetero
                        atomselect macro qwikmd_hetero $QWIKMD::heteromcr
                    }
                }
            }
        }

        if {[file exists  ${prefix}_formatted_autopsf.psf] != 1} {
            return [list 1 "Please inspect VMD outputs for more information."]
        }

        file rename ${prefix}_formatted_autopsf.psf ${prefix}.psf
        file rename ${prefix}_formatted_autopsf.pdb ${prefix}.pdb

        mol new $prefix.psf
        mol addfile $prefix.pdb waitfor all
        set stfile [molinfo [molinfo top] get filename]
        set stctFile  [lindex $stfile 0] 
        
        set prefix  [file root [lindex $stctFile 0]]
        set pdb ""
        set psf ""

        # if MDFF protocol is selected, don't bring the structure to the origin. Assume that structure is aligned with
        # the density maps already
        if {$QWIKMD::run != "MDFF"} {
            QWIKMD::orientMol [molinfo top]
        }
        set selall [atomselect [molinfo top] "all"]
        $selall writepdb orient.pdb
        $selall delete
        ################################################################################
        ## In the equilibration MD simulaitons only the backbone is restrain. SMD simulations require
        ## the identification of the anchor residues by the beta column and the pulling residues
        ## by the occupancy collumn. 
        ################################################################################
        
        regsub -all "_formatted_autopsf" [file root [file tail [lindex $stctFile 0] ] ] "" name
        
        
        set constpdb [list]
        if {$solvent == "Explicit"} {
            set membrane 0
            set solv "_solvated"
            set solvateOK ""
            set dimList [list]
            if {$QWIKMD::membraneFrame != ""} {
                set membrane 1
                set lipidsel [atomselect top "chain L and not water"]
                set selall [atomselect top "all"]
                set zminmax [measure minmax $lipidsel]
                set allzminmax [measure minmax $selall]

                set zallmin [lindex [lindex $allzminmax 0] 2]
                set zallmax [lindex [lindex $allzminmax 1] 2]

                set xmin [lindex [lindex $zminmax 0] 0]
                set xmax [lindex [lindex $zminmax 1] 0]
                set ymin [lindex [lindex $zminmax 0] 1]
                set ymax [lindex [lindex $zminmax 1] 1]
                set zmin [lindex [lindex $zminmax 0] 2]
                set zmax [lindex [lindex $zminmax 1] 2]

                set zmintemp [expr $zallmin - $QWIKMD::advGui(solvent,boxbuffer,$QWIKMD::run)]
                lappend dimList [list [list $xmin $ymin $zmintemp] [list $xmax $ymax $zmin]]
                #set cmd "solvate [lindex $stctFile 0] orient.pdb -minmax \{ \{$xmin $ymin $zmintemp\} \{ $xmax $ymax $zmin\} \} -o \"solvateAux\" -s \"WL\""
                #set solvateOK [QWIKMD::redirectPuts $solvateLog $cmd]
                set solvateLog ""
                set solvateOK [catch {solvate [lindex $stctFile 0] orient.pdb -minmax [list [list $xmin $ymin $zmintemp] [list $xmax $ymax $zmin ] ] -o "solvateAux" -s "WL"} solvateLog]

                if {$solvateOK >= 1} {
                    #close $solvateLog
                    return [list 1 $solvateLog]

                }
                set zmaxtemp [expr $zallmax + $QWIKMD::advGui(solvent,boxbuffer,$QWIKMD::run)]

                lappend dimList [list [list $xmin $ymin $zmax] [list $xmax $ymax $zmaxtemp]]
                #set cmd "solvate solvateAux.psf solvateAux.pdb -minmax \{ \{$xmin $ymin $zmax \} \{$xmax $ymax $zmaxtemp\} \} -o $prefix$solv -s \"WU\""
                #set solvateOK [QWIKMD::redirectPuts $solvateLog $cmd]

                set solvateLog ""
                set solvateOK [catch {solvate solvateAux.psf solvateAux.pdb -minmax [list [list $xmin $ymin $zmax] [list $xmax $ymax $zmaxtemp ] ] -o $prefix$solv -s "WU"} solvateLog]

                if {$solvateOK >= 1} {
                    #close $solvateLog
                    return [list 1 "Solvate error $solvateLog"]
                }

                
                if {$QWIKMD::membraneFrame != ""} {
                    set sel [atomselect top "all and water"]
                    set minmax [measure minmax $sel]
                    set xlength [expr [lindex [lindex $minmax 1] 0] - [lindex [lindex $minmax 0] 0] ]
                    set ylength [expr [lindex [lindex $minmax 1] 1] - [lindex [lindex $minmax 0] 1] ]
                    set zlength [expr [lindex [lindex $minmax 1] 2] - [lindex [lindex $minmax 0] 2] ]
                    pbc set [list $xlength $ylength $zlength]
                    $sel delete
                    set sel [atomselect top "all"]
                    $sel writepdb ${prefix}${solv}.pdb
                    $sel delete
                    
                }
                $lipidsel delete
                $selall delete
            } else {
                set dist 7.5
                if {$tabid == 1 && $solvent == "Explicit"} {
                    set dist $QWIKMD::advGui(solvent,boxbuffer,$QWIKMD::run)
                }
                set cmd "solvate [lindex $stctFile 0] orient.pdb "
                if {$QWIKMD::advGui(solvent,minimalbox,$QWIKMD::run) == 0 || $tabid == 0} {
                    QWIKMD::boxSize [molinfo top] $dist
                    append cmd "-minmax \{[lrange $QWIKMD::cellDim 0 1]\} "
                } else {
                    if {$QWIKMD::run == "MD" && $tabid == 1} {
                        append cmd "-rotate "
                    }
                    append cmd "-t $dist "
                }
                append cmd "-o $prefix$solv"
                
                # set cmd "solvate [lindex $stctFile 0] orient.pdb -minmax \{[lrange $QWIKMD::cellDim 0 1]\} -o $prefix$solv"
                #set solvateOK [QWIKMD::redirectPuts $solvateLog $cmd ]

                set solvateLog ""
                set solvateOK [eval catch {$cmd} solvateLog]

                if {$solvateOK >= 1} {
                    #close $solvateLog
                    return [list 1 "Solvate error $solvateLog"]
                }
                if {$QWIKMD::advGui(solvent,minimalbox,$QWIKMD::run) == 1} {
                    set selDim [atomselect top "all"]
                    set minmax [measure minmax $selDim]
                    set xsp [lindex [lindex $minmax 0] 0]
                    set ysp [lindex [lindex $minmax 0] 1]
                    set zsp [lindex [lindex $minmax 0] 2]

                    set xep [lindex [lindex $minmax 1] 0]
                    set yep [lindex [lindex $minmax 1] 1]
                    set zep [lindex [lindex $minmax 1] 2]

                    set boxmin [list $xsp $ysp $zsp]
                    set boxmax [list $xep $yep $zep]

                    set centerX [expr [expr $xsp + $xep] /2]
                    set centerY [expr [expr $ysp + $yep] /2]
                    set centerZ [expr [expr $zsp + $zep] /2]

                    set cB1 [expr abs($xep - $xsp)]
                    set cB2 [expr abs($yep - $ysp)]
                    set cB3 [expr abs($zep - $zsp)]

                    set center [list [format %.2f $centerX] [format %.2f $centerY] [format %.2f $centerZ]]
                    set length [list [format %.2f $cB1] [format %.2f $cB2] [format %.2f $cB3]]
                    set QWIKMD::cellDim [list $boxmin $boxmax $center $length]
                }
                set dimList [lrange $QWIKMD::cellDim 0 1]
            }
            
            puts $textLogfile [QWIKMD::solvateLog $membrane $dimList]

            set cation ""
            set anion ""
            set ions ""
            set saltconc ""
            if {$tabid == 0} {
                set ions $QWIKMD::basicGui(saltions,$QWIKMD::run,0)
                set saltconc $QWIKMD::basicGui(saltconc,$QWIKMD::run,0)
            } else {
                set ions $QWIKMD::advGui(saltions,$QWIKMD::run,0)
                set saltconc $QWIKMD::advGui(saltconc,$QWIKMD::run,0)
            }
            switch $ions {
                NaCl {
                    set cation "SOD"
                    set anion "CLA"
                }
                KCl {
                    set cation "POT"
                    set anion "CLA"
                }
                CsCl {
                    set cation "CES"
                    set anion "CLA"
                }
                MgCl2 {
                    set cation "MG"
                    set anion "CLA"
                }
                CaCl2 {
                    set cation "CAL"
                    set anion "CLA"
                }
                ZnCl2 {
                    set cation "ZN2"
                    set anion "CLA"
                }
            }

            set atIonizeLog ""
            set atIonizeOk [catch {autoionize -psf $prefix$solv.psf -pdb $prefix$solv.pdb -sc $saltconc -o ionized -cation $cation -anion $anion} atIonizeLog ]
            if {$atIonizeOk >= 1} {
                return [list 1 "Autoionize error $atIonizeLog"]
            }
            puts $textLogfile [QWIKMD::ionizeLog $saltconc $cation $anion]
            set constpdb [list ionized.psf ionized.pdb]

        } else {
            set constpdb [list [lindex $stctFile 0] orient.pdb]
        } 
        set mol [mol new [lindex $constpdb 0] ]
        mol addfile [lindex $constpdb 1] waitfor all
    } else {
        set name [file rootname [file tail $QWIKMD::outPath]]
    }

    if {$QWIKMD::run != "MDFF" && $tabid == 0} {
        if {$QWIKMD::basicGui(prtcl,$QWIKMD::run,equi) == 1 } {
            set all [atomselect top "all"]
            set sel [atomselect top "(qwikmd_protein or qwikmd_nucleic or qwikmd_glycan or qwikmd_lipid) and backbone"]

            $all set beta 0
            $sel set beta 1

            $all writepdb [lindex $QWIKMD::confFile 0]_constraints.pdb
            mol delete $mol
            $sel delete
            $all delete
            file copy -force [lindex $QWIKMD::confFile 0]_constraints.pdb ../run/[lindex $QWIKMD::confFile 0]_constraints.pdb
        }
    }
    ### Evaluate the differences between the charges defined in the topology files
    ### and the charge selected by the user in the QM table	
    if {$QWIKMD::run == "QM/MM"} {
        set numqm [$QWIKMD::advGui(qmtable) size]
        set total_differ 0
        for {set i 1} {$i <= $numqm} {incr i} {
            if {$QWIKMD::advGui(qmtable,$i,qmRegionSel) != "Type Selection"} {
                set diffaux [expr $QWIKMD::advGui(qmtable,$i,charge) - $QWIKMD::advGui(qmtable,$i,qmTopoCharge) ]
                set total_differ [expr $total_differ + $diffaux ]
            }
        }
        if {[expr abs($total_differ)] > 0 && ($QWIKMD::advGui(saltions,$QWIKMD::run,0) == "NaCl" || $QWIKMD::advGui(saltions,$QWIKMD::run,0) == "KCl")} {
            set changeCharge [list]
            set replaceIon [list]
            set ions $QWIKMD::advGui(saltions,$QWIKMD::run,0)
            set atomname ""
            set newatom ""
            set newauxatom ""
            set selall [atomselect top "all and not water and not ions"] 
            set centermass [measure center $selall weight mass]
            $selall delete
            if {$total_differ > 0} {
                set atomname "SOD"
                if {$ions == "KCl"} {
                    set atomname "POT"
                }
                if {$total_differ >= 2} {
                    set newatom [list "CLA CLA CLA CL -1 35.4500"]
                } 
                set newauxatom [list "SOD SOD SOD NA 0 22.9898"]
                if {$ions == "KCl"} {
                    set newauxatom [list "POT POT POT K 0 39.0983"]
                }
            } elseif {$total_differ < 0} {
                set atomname "CLA"
                if {$total_differ <= -2} {
                    set newatom [list "SOD SOD SOD NA 1 22.9898"]
                    if {$ions == "KCl"} {
                        set newatom [list "POT POT POT K 1 39.0983"]
                    }
                } 
                set newauxatom [list "CLA CLA CLA CL 0 35.4500"]
            }
            set listDist [list]
            set sel [atomselect top "name $atomname"]
            foreach coor [$sel get {x y z}] index [$sel get index] {
                lappend listDist [list $index [veclength [vecsub $coor $centermass]]]
            }
            $sel delete
            set listDist [lsort -unique -real -decreasing -index 1 $listDist]
            set lim [expr abs($total_differ)]
            set incrdif 0
            while {$lim > 0} {
                set increment 2
                set newatomsel $newatom
                if {[QWIKMD::format2Dec [expr fmod($lim,2)]] != 0.00} {
                    set increment 1
                    set newatomsel $newauxatom
                    lappend changeCharge "$atomname [lindex [lindex $listDist $incrdif] 0] [QWIKMD::format2Dec [lindex [lindex $listDist $incrdif] 1]]"
                } else {
                    lappend replaceIon "$atomname [lindex [lindex $listDist $incrdif] 0] [lindex [lindex $newatom 0] 0] [QWIKMD::format2Dec [lindex [lindex $listDist $incrdif] 1]]"
                }
                set sel [atomselect top "index [lindex [lindex $listDist $incrdif] 0]"]
                $sel set {name type resname element charge mass} $newatomsel
                $sel delete
                set lim [expr $lim - $increment]
                incr incrdif 
            }
            puts $QWIKMD::textLogfile [QWIKMD::printDiffQMCharge $total_differ $replaceIon $changeCharge]
            flush $QWIKMD::textLogfile    
        }
    }

    if {$tabid == 1 && $QWIKMD::run != "MDFF"} {
        set restrains [$QWIKMD::advGui(protocoltb,$QWIKMD::run) getcolumns 2]
        for {set i 0} {$i < [llength $restrains]} {incr i} {
            set do 0
            set text [lindex $restrains $i]
            if {$text != "none"} {
                set do 1
                if {$i > 0} {
                    if {[lindex $restrains $i] == [lindex $restrains [expr $i -1] ]} {
                        set do 0
                    }
                }
            }

            if {$do == 1 } {
                set all [atomselect top "all"]
                set sel [atomselect top $text]
                $all set beta 0
                $sel set beta 1

                $all writepdb [lindex $QWIKMD::confFile $i]_restraints.pdb
                $sel delete
                $all delete
                file copy -force [lindex $QWIKMD::confFile $i]_restraints.pdb ../run/
            }
        }
    }

    set topfilename "ionized.pdb"
    if {$solvent != "Explicit"} {
        set topfilename "orient.pdb"
    }
    ## Create the pdb files declaring the pulling and the anchoring residues
    if {$QWIKMD::run == "SMD"} {   
        set all [atomselect top "all"]
        $all set beta 0
        $all set occupancy 0
        set beta [atomselect top $QWIKMD::anchorRessel]
        set occupancy [atomselect top $QWIKMD::pullingRessel]
        $beta set beta 1
        $occupancy set occupancy 1
        $beta delete
        $occupancy delete

        $all writepdb $topfilename 
        $all delete
    }
    ## Create the pdb files declaring the atoms to be fixed
    ## Only used when QM molecule type exists for QM/MM 
    ## simulations
    set sufix "_QwikMD"
    if {$QWIKMD::run == "MD" && $topoqmselected == 1} {   
        set all [atomselect top "all"]
        $all set beta 0
        $all set occupancy 0
        set fix [atomselect top "same residue as (all within 5 of QM) and not water and not segname ION"]
        $fix set beta 1
        $all writepdb $name${sufix}_fixed.pdb
        $all delete
        file copy -force $name${sufix}_fixed.pdb ../run/

        puts $QWIKMD::textLogfile [QWIKMD::printQMMacroFixAtoms]
        flush $QWIKMD::textLogfile  
    }
    
    if {$QWIKMD::run == "QM/MM"} {
        set ind 0
        foreach prtcl [llength $QWIKMD::confFile] {
            if {$QWIKMD::advGui(protocoltb,$QWIKMD::run,$ind,qmmm) == 1} {
                if {$ind == 0} {
                    ## Create the pdb file declaring the QM region
                    QWIKMD::PrepareQMMM $name$sufix
                }
                break
            }
            incr ind
        }

    }
    if {$QWIKMD::load == 0} {
        if {$solvent != "Explicit"} {
            file copy -force [lindex $stctFile 0] ../run/$name$sufix.psf
            file copy -force orient.pdb ../run/$name$sufix.pdb
        } else {
            file copy -force ionized.psf ../run/$name$sufix.psf
            file copy -force ionized.pdb ../run/$name$sufix.pdb
        }
    } else {
        set pdb $name$sufix.pdb
        set psf $name$sufix.psf
        set all [atomselect top "all"]
        $all writepdb $pdb
        $all writepsf $psf
        $all delete

        file copy -force $psf ../run/
        file copy -force $pdb ../run/
    }
    
    
    set pdb $name$sufix.pdb
    set psf $name$sufix.psf

    set QWIKMD::topMol [molinfo top]
    
    return "$psf $pdb"
}
################################################################################
## Prepare supporting pdbs for the qm/mm calculations 
################################################################################
proc QWIKMD::PrepareQMMM {prefix} {

    if {[file exists ${prefix}_qm-input.pdb] != 1} {
        set all [atomselect top "all" frame now]
        $all set beta 0
        $all set occupancy 0
        # Define QM regions
        for {set qmID 1} {$qmID <= [$QWIKMD::advGui(qmtable) size]} {incr qmID} {
            QWIKMD::getQMMM $qmID $QWIKMD::advGui(qmtable,$qmID,qmRegionSel)
            ## Define the solvent to be included in the QM region
            if {$QWIKMD::advGui(solvent,$QWIKMD::run,0) == "Explicit" && $QWIKMD::advGui(qmtable,$qmID,solvDist) > 0 } {
                set selaux [atomselect top "(same residue as (all pbwithin $QWIKMD::advGui(qmtable,$qmID,solvDist) of (beta == $qmID))) and not qwikmd_protein and not qwikmd_nucleic and not qwikmd_glycan" frame last]
                $selaux set beta $qmID
                $selaux delete
            }

            set selaux [atomselect top "all and beta == $qmID" frame now]
            set numamts [$selaux num]
            if {$QWIKMD::load == 0} {
                set charge ""
                if {$numamts > 1} {
                    set charge [QWIKMD::format2Dec [eval "vecadd [$selaux get charge]"]]
                } elseif {$numamts == 1} {
                    set charge [QWIKMD::format2Dec [$selaux get charge]]
                }
                set QWIKMD::advGui(qmtable,$qmID,charge) $charge
                set QWIKMD::advGui(qmtable,$qmID,qmTopoCharge) $charge
                $QWIKMD::advGui(qmtable) cellconfigure [expr $qmID -1],2 -text $QWIKMD::advGui(qmtable,$qmID,charge)
            }
            set QWIKMD::advGui(qmtable,$qmID,indexes) [$selaux get index]
            ## Make sure the number of atoms are updated when the preparation started without solvent 
            
            $QWIKMD::advGui(qmtable) cellconfigure [expr $qmID -1],1 -text $numamts
            $selaux delete
        }
        topo guessatom element mass
        $all writepdb ${prefix}_qm-input.pdb
        set qmsel [atomselect top "beta > 0"]
        $qmsel writepsf ${prefix}_qm.psf
        $qmsel delete
        file copy -force ${prefix}_qm-input.pdb ../run/
        file copy -force ${prefix}_qm.psf ../run/
        # define Point charges
        set do 0
        foreach prct $QWIKMD::confFile {
            if {$QWIKMD::advGui(qmoptions,cmptcharge,$prct) == "On"} {
                set do 1
            }
        }
        if {$do == 1} {
            for {set qmID 1} {$qmID <= [$QWIKMD::advGui(qmtable) size]} {incr qmID} {
                $all set occupancy 0
                $all set beta 0
                if {$QWIKMD::advGui(qmtable,$qmID,pcDist) > 0} {
                    set selbeta [atomselect top "index $QWIKMD::advGui(qmtable,$qmID,indexes)"]
                    $selbeta set beta $qmID
                    set selaux [atomselect top "(all pbwithin $QWIKMD::advGui(qmtable,$qmID,pcDist) of (all and beta == $qmID)) and not beta == $qmID" frame now]
                    $selaux set occupancy 1
                    $selaux delete
                    $selbeta delete
                    $all writepdb ${prefix}_CustomPC-input-QM${qmID}.pdb
                    file copy -force ${prefix}_CustomPC-input-QM${qmID}.pdb ../run/
                }
            }
        }
        $all delete
        puts $QWIKMD::textLogfile [QWIKMD::printQMRegions] 
        flush $QWIKMD::textLogfile
    }
    
}
################################################################################
## Assign the values to the beta column correspondent to each qm region.
## Done in a separate proc to enable being called from structure preparation and
## from the Gui during region selection
################################################################################
proc QWIKMD::getQMMM {qmID atomsel} {
    set selaux [atomselect top "same residue as ($atomsel)" frame now]
    $selaux set beta $qmID

    set segments ""
    set segkey "segname"
    if {$QWIKMD::load == 1} {
        set segments [lsort -unique [$selaux get segname] ]
    } else {
        set segments [lsort -unique [$selaux get chain] ]
        set segkey "chain"
    }
    
    foreach seg $segments {

        ### Original script by Marcelo C. R. Melo Biophysics and Computational Biology crdsdsr2@illinois.edu
        set qmmm [atomselect top "(qwikmd_protein and name CA) and beta == $qmID and $segkey $seg" frame now]
        set segSel [atomselect top "$segkey $seg and qwikmd_protein" frame now]
        # set listqmmm [lsort -unique -integer -increasing [$qmmm get resid]]
        set listqmmm [lsort -unique -integer -increasing [$qmmm get resid]]
        set cter [lindex [lsort -unique -integer -increasing [$segSel get resid]] end]
        $segSel delete
        $qmmm delete
        set QM1bond ""
        set QM2bond ""

        #Checking N-Terminal-direction QM-MM bonds
        foreach resTest $listqmmm {
            if {[lsearch $listqmmm [expr $resTest -1]] == -1} { 
                append QM1bond \"[expr $resTest -1] \"
            }
        }
        #Checking C-terminal-direction QM-MM bonds
        foreach resTest $listqmmm {
            # If the QM residue is a C terminal, the RESID + 1 won't be found
            # and the QM residue's C and O atoms will be removed from the QM region
            # for no reason, since no QM-MM bonds will be formed.
            # In this case, we just skip this QM residue and check the next.
            if {$resTest == $cter} {
                continue
            }
            if {[lsearch $listqmmm [expr $resTest +1]] == -1} { 
                append QM2bond \"$resTest \"
            }
        }
        # Making changes
        if {$QM2bond != ""} {
            set occ [atomselect top "name CA C and (resid $QM2bond and $segkey $seg)" frame now]
            $occ set occupancy 1
            set bt [atomselect top "name C O and (resid $QM2bond and $segkey $seg)" frame now] 
            $bt set beta 0
            $occ delete
            $bt delete
            set QM2bond ""
        }
        
        if {$QM1bond != ""} {
            set occ [atomselect top "name CA C and (resid $QM1bond and $segkey $seg)" frame now] 
            $occ set occupancy 1
            set bt [atomselect top "name C O and (resid $QM1bond and $segkey $seg)" frame now] 
            $bt set beta $qmID
            $occ delete
            $bt delete
            set QM1bond ""
        }
        

        set qmmm [atomselect top "(qwikmd_nucleic and name P) and beta == $qmID and $segkey $seg" frame now]
        set segSel [atomselect top "$segkey $seg and qwikmd_nucleic" frame now]
        set fiveTer [lindex [lsort -unique -integer [$segSel get resid]] 0]
        $segSel delete
        set listqmmm [$qmmm get resid]
        $qmmm delete
        # Checking 3'-Terminal-direction QM-MM bonds
        foreach resTest $listqmmm {
            if {[lsearch $listqmmm [expr $resTest +1]] == -1} { 
                append QM1bond \"[expr $resTest +1] \"
            }
        }

        # Checking 5'-terminal-direction QM-MM bonds
        foreach resTest $listqmmm {
            # If the QM residue is a 5' terminal, the RESID - 1 won't be found
            # and the QM residue's phosphate group atoms will be removed from the QM region
            # for no reason, since no QM-MM bonds will be formed.
            # In this case, we just skip this QM residue and check the next.
            if { $resTest == $fiveTer} {
                continue
            }
            if {[lsearch $listqmmm [expr $resTest -1]] == -1} { 
                append QM2bond \"$resTest \"
            }
        }
        # Making changes
        if {$QM2bond != ""} {
            set occ [atomselect top "name C4' C5' and (resid $QM2bond and $segkey $seg)" frame now]
            $occ set occupancy 1
            set bt [atomselect top "name P O1P O2P O5' C5' H5' H5'' and (resid $QM2bond and $segkey $seg)" frame now] 
            $bt set beta 0
            $occ delete
            $bt delete
            set QM2bond ""
            unset QM2bond
        } 
        if {$QM1bond != ""} {
            set occ [atomselect top "name C4' C5' and (resid $QM1bond and $segkey $seg)" frame now]
            $occ set occupancy 1
            set bt [atomselect top "name P O1P O2P O5' C5' H5' H5'' and (resid $QM1bond and $segkey $seg)" frame now]
            $bt set beta $qmID
            $occ delete
            $bt delete
            set QM1bond ""
            unset QM1bond
        }
    }    
    
    $selaux delete
}

################################################################################
## Creation of the config file for namd. In this case we have two "templates" for
## for MD and SMD simulaitons. In the next versions more templates will be required,
## so a more inteligent proc will be necessary and less hardcoded variables will be used 
################################################################################
proc QWIKMD::isSMD {filename} {
    set returnval 0
    set templatefile [open "$filename" r]
    set line [read $templatefile]
    set line [split $line "\n"]

    set enter ""
    set lineIndex [lsearch -exact -all $line $enter]
    for {set j 0} {$j < [llength $lineIndex]} {incr j} {
        lset line [lindex $lineIndex $j] "{} {}"
    }
    set smdtxt "SMD on"
    
    set lineIndex [lsearch -regexp $line (?i)$smdtxt$]
    if {$lineIndex != -1} {
        set returnval 1
    }
    close $templatefile
    return $returnval
}

proc QWIKMD::isQMMM {filename} {
    set returnval 0
    set templatefile [open "$filename" r]
    set line [read $templatefile]
    set line [split $line "\n"]

    set enter ""
    set lineIndex [lsearch -exact -all $line $enter]
    for {set j 0} {$j < [llength $lineIndex]} {incr j} {
        lset line [lindex $lineIndex $j] "{} {}"
    }
    set smdtxt "qmForces on"
    
    set lineIndex [lsearch -regexp $line (?i)$smdtxt$]
    if {$lineIndex != -1} {
        set returnval 1
    }
    close $templatefile
    return $returnval
}
############################################################
## Process to manage the generation of the NAMD configuration
## files. 
############################################################
proc QWIKMD::NAMDGenerator {strct step} {
    global env
    
    set tabid [$QWIKMD::topGui.nbinput index current]
    if {$tabid == 0} {      
        set conf [lindex $QWIKMD::confFile $step]   
        QWIKMD::GenerateBasicNamdFiles $strct $step
        set i 0
        while {$i < [llength  $QWIKMD::confFile]} {
            if {[string match "*_production_smd*" [lindex $QWIKMD::confFile $i] ] > 0} {
                break
            }
            incr i
        }

    } else {
        set QWIKMD::confFile [$QWIKMD::advGui(protocoltb,$QWIKMD::run) getcolumns 0]
        set conf [lindex $QWIKMD::confFile $step]
        set restrains [$QWIKMD::advGui(protocoltb,$QWIKMD::run) getcolumns 2]
        set outputfile ""
        set args [$QWIKMD::advGui(protocoltb,$QWIKMD::run) rowcget $step -text]


        set QWIKMD::advGui(protocoltb,$QWIKMD::run,$step,smd) 0
        set location ""
        set tempfilename ""
        set values {Minimization Annealing Equilibration MD SMD QMMM-Min QMMM-Ann QMMM-Equi QMMM}
        set serachindex [lsearch $values [file root $conf] ]
        set location "$env(QWIKMDFOLDER)/templates/"
        if {$serachindex == -1} {
            append location $QWIKMD::advGui(solvent,$QWIKMD::run,0)
        }
        if {[file exists "$env(QWIKMDTMPDIR)/$conf.conf"] != 1 && [file exists "$env(QWIKMDTMPDIR)/[file root $conf].conf"] != 1} {
            if {[file exists "${QWIKMD::outPath}/run/[file root $conf].conf"] == 1 } {
                if {$QWIKMD::run == "SMD"} {
                    if {[QWIKMD::isSMD "$location/[file root $conf].conf"] == 1} {
                        set QWIKMD::advGui(protocoltb,$QWIKMD::run,$step,smd) 1 
                    }
                } elseif {$QWIKMD::run == "QM/MM"} {
                    if {[QWIKMD::isQMMM "$location/[file root $conf].conf"] == 1} {
                        set QWIKMD::advGui(protocoltb,$QWIKMD::run,$step,qmmm) 1 
                    }
                }
                QWIKMD::GenerateNamdFiles "qwikmdTemp.psf qwikmdTemp.pdb" "$location/[file root $conf].conf" [lsearch $QWIKMD::prevconfFile [file root $conf]] [$QWIKMD::advGui(protocoltb,$QWIKMD::run) rowcget [expr $step -1] -text] "$env(QWIKMDTMPDIR)/[file root $conf].conf"
                set location  $env(QWIKMDTMPDIR)/
                set tempfilename [file root $conf].conf
            } else {
                #set location ${env(QWIKMDFOLDER)}/templates/
                set tempfilename [file root $conf].conf
            }
        } else {            
            set location  $env(QWIKMDTMPDIR)
            set tempfilename [file root $conf].conf
            if {[file exists "$env(QWIKMDTMPDIR)/$conf.conf"] != 1} {
                set tempfilename [file root $conf].conf
            } else {
                set tempfilename $conf.conf
            }
            
        }

        if {$QWIKMD::run == "SMD"} {
            if {[QWIKMD::isSMD "$location/$tempfilename"] == 1} {
                set QWIKMD::advGui(protocoltb,$QWIKMD::run,$step,smd) 1 
            }
        } elseif {$QWIKMD::run == "QM/MM"} {
            if {[QWIKMD::isQMMM "$location/$tempfilename"] == 1} {
                set QWIKMD::advGui(protocoltb,$QWIKMD::run,$step,qmmm) 1 
            }
        }


        if {[file exists $env(QWIKMDTMPDIR)/$conf.conf] != 1 } {
            set outputfile ${QWIKMD::outPath}/run/$conf.conf
            QWIKMD::GenerateNamdFiles $strct "$location/$tempfilename" $step $args ${outputfile}
        } else {
            set auxfile [open  $env(QWIKMDTMPDIR)/$conf.conf r]
            set tempList [$QWIKMD::advGui(protocoltb,$QWIKMD::run) getcolumns 4]
            set QWIKMD::line [read $auxfile]
            set QWIKMD::line [split $QWIKMD::line "\n"]
            
            close $auxfile
            # set enter ""
            # set index [lsearch -exact -all $QWIKMD::line $enter]
            # for {set j 0} {$j < [llength $index]} {incr j} {
            #     lset QWIKMD::line [lindex $index $j] "{} {}"
            # }
            # for {set i 0} {$i < [llength $QWIKMD::line]} {incr i} {
            #     lset QWIKMD::line $i [split [lindex $QWIKMD::line $i] " "]
            # }
            for {set i 0} {$i < [llength $QWIKMD::line]} {incr i} {
                if {[string length [lindex $QWIKMD::line $i]] == 0} {
                    lset QWIKMD::line $i ">> >>"
                }
                if {[string index [lindex $QWIKMD::line $i] 0] != "#" && [llength [lindex $QWIKMD::line $i]] == 1} {
                    lset QWIKMD::line $i [split [lindex $QWIKMD::line $i] " "]
                } elseif {[string index [lindex $QWIKMD::line $i] 0] == "#"} {
                    lset QWIKMD::line $i [concat ">>" [list [lindex $QWIKMD::line $i]]]
                }  
            }
            # set index [lsearch -exact -all $QWIKMD::line ","]
            # for {set j 0} {$j < [llength $QWIKMD::line]} {incr j} {
            #     set lineaux ""
            #     regsub -all "," [lindex $QWIKMD::line $j] "" lineaux
            #     lset QWIKMD::line $j $lineaux
            # }
            set auxfile [open ${QWIKMD::outPath}/run/$conf.conf w+]
            QWIKMD::replaceNAMDLine "coordinates" "coordinates [lindex $strct 1]"
            QWIKMD::replaceNAMDLine "structure" "structure [lindex $strct 0]"
            QWIKMD::replaceNAMDLine "fixedAtomsFile" "fixedAtomsFile [file root [lindex $strct 0]]_fixed.pdb"
            #replace the restart files in case of addition of protocols in middle of an already created protocol

            if {$step > 0} {
                set inputname [lindex $QWIKMD::confFile [expr $step -1]]
                set index [lsearch -regexp -index 0 $QWIKMD::line (?i)#binCoordinates$]
                if {$index != -1} {
                    QWIKMD::replaceNAMDLine "#binCoordinates" "binCoordinates $inputname.restart.coor"
                } else {
                    set index [lsearch -regexp -index 0 $QWIKMD::line (?i)binCoordinates$]
                    if {$index != -1} {
                        QWIKMD::replaceNAMDLine "binCoordinates" "binCoordinates $inputname.restart.coor"
                    } else {
                        puts $auxfile "binCoordinates $inputname.restart.coor"
                    }
                }

                set tempdef 0
                if {[lindex $tempList $step] != [lindex $tempList [expr $step - 1]] && $QWIKMD::advGui(protocoltb,$QWIKMD::run,$step,lock) == 0} {
                    set tempdef 1
                }
                if {[file root $inputname] != "Minimization" && $tempdef == 0 && [file root $inputname] != "QMMM-Min"} {
                    QWIKMD::replaceNAMDLine "binVelocities" "binVelocities $inputname.restart.vel"
                } else {
                    set index [lsearch -regexp -index 0 $QWIKMD::line (?i)binVelocities$]
                    if {$index != -1} {
                        QWIKMD::replaceNAMDLine "binVelocities" "#[lindex $QWIKMD::line $index]"
                    } 
                }
                
                 if {$QWIKMD::advGui(solvent,$QWIKMD::run,0) == "Explicit"} {
                    set index [lsearch -regexp -index 0 $QWIKMD::line (?i)#extendedSystem$]
                    if {$index != -1} {
                        QWIKMD::replaceNAMDLine "#extendedSystem" "extendedSystem $inputname.restart.xsc"
                    } else {
                        set index [lsearch -regexp -index 0 $QWIKMD::line (?i)extendedSystem$]
                        if {$index != -1} {
                            QWIKMD::replaceNAMDLine "extendedSystem" "extendedSystem $inputname.restart.xsc"
                        } else {
                            puts $auxfile "extendedSystem $inputname.restart.xsc"
                        }
                    }
                } else {
                    set index [lsearch -regexp -index 0 $QWIKMD::line (?i)extendedSystem$]
                    QWIKMD::replaceNAMDLine "extendedSystem" "#extendedSystem $inputname.restart.xsc"
                }
                if {$QWIKMD::run == "SMD"} {
                    if {[QWIKMD::isSMD "$env(QWIKMDTMPDIR)/$conf.conf"] == 1} {
                        if {$QWIKMD::advGui(protocoltb,$QWIKMD::run,$step,lock) == 1} {
                            set index [lsearch -regexp -index 0 $QWIKMD::line (?i)SMDk$]
                            if {$index != -1} {
                                set QWIKMD::mdProtInfo($inputname,smdk) [string trim [join [lindex [lindex $QWIKMD::line $index] 1]]]
                            }

                            set index [lsearch -regexp -index 0 $QWIKMD::line (?i)SMDVel$]
                            if {$index != -1} {
                                set QWIKMD::basicGui(pspeed) [QWIKMD::format2Dec [expr [expr [string trim [join [lindex [lindex $QWIKMD::line $index] 1]]]  / $QWIKMD::mdProtInfo($inputname,timestep) ] * 1e6 ] ]
                                set QWIKMD::mdProtInfo($inputname,pspeed) $QWIKMD::basicGui(pspeed)
                            }
                        }
                        set i 0
                        while {$i < [llength  $QWIKMD::confFile]} {
                            if {$QWIKMD::advGui(protocoltb,$QWIKMD::run,$i,smd) == 1} {
                                break
                            }
                            incr i
                        }
                        set str ""
                        if {$i == $step} {
                            set str "firstTimestep 0"
                        } else {
                           set str [QWIKMD::addFirstTimeStep $step] 
                        }
                        set index [lsearch -regexp -index 0 $QWIKMD::line (?i)firstTimestep$]
                        if {$index != -1} {
                            QWIKMD::replaceNAMDLine "firstTimestep" "$str"
                        } else {
                            puts $auxfile $str
                        }
                    }
                }
            } elseif {$step == 0} {
                if {$QWIKMD::advGui(solvent,$QWIKMD::run,0) == "Explicit"} {
                    set index [lsearch -regexp -index 0 $QWIKMD::line (?i)extendedSystem$]
                    if { $index != -1} {
                        QWIKMD::replaceNAMDLine "extendedSystem" "extendedSystem $conf.xsc"
                        
                    } else {
                        puts $auxfile "extendedSystem $conf.xsc"
                    }
                } else {
                    set index [lsearch -regexp -index 0 $QWIKMD::line (?i)extendedSystem$]
                    QWIKMD::replaceNAMDLine "extendedSystem" "#[lindex $QWIKMD::line $index]"
                }
                
                set index [lsearch -regexp -index 0 $QWIKMD::line (?i)binCoordinates$]
                QWIKMD::replaceNAMDLine "binCoordinates" "#[lindex $QWIKMD::line $index]"
                
                set index [lsearch -regexp -index 0 $QWIKMD::line (?i)binVelocities$]
                if {$QWIKMD::curframe > 0 && $QWIKMD::load == 1} {
                    set velfile ""
                    catch {glob $QWIKMD::outPath/run/*.vel} velfile
                    set velfile [file tail $velfile]
                    if { $index != -1} {
                        QWIKMD::replaceNAMDLine "binVelocities" "binVelocities $velfile"
                        QWIKMD::replaceNAMDLine "#binVelocities" "binVelocities $velfile"
                    } else {
                        puts $auxfile "binVelocities $velfile"
                    }
                    if {[file root [lindex $QWIKMD::confFile $step]] != "QMMM-Min"} {
                        set index [lsearch -regexp -index 0 $QWIKMD::line (?i)temperature$]
                        QWIKMD::replaceNAMDLine "temperature" "#[lindex $QWIKMD::line $index]"
                    }
                } else {
                    QWIKMD::replaceNAMDLine "binVelocities" "#[lindex $QWIKMD::line $index]"
                } 
            }

            ## Check if the restraints were changed after file edition

            if {[$QWIKMD::advGui(protocoltb,$QWIKMD::run) cellcget $step,2 -text] != "none" && $QWIKMD::advGui(protocoltb,$QWIKMD::run,$step,smd) == 0} {
                #if {$QWIKMD::advGui(protocoltb,$QWIKMD::run,$step,lock) == 0} {
                    set index [lsearch -regexp -index 0 $QWIKMD::line (?i)constraints$]
                    if { $index != -1} {
                        QWIKMD::replaceNAMDLine "constraints" "constraints on"
                        
                    } else {
                        puts $auxfile "constraints on"
                    }
                    set index [lsearch -regexp -index 0 $QWIKMD::line (?i)conskcol$]
                    if { $index != -1} {
                        QWIKMD::replaceNAMDLine "conskcol" "conskcol B"
                        
                    } else {
                        puts $auxfile "conskcol B"
                    }
                #}
                set restrains [$QWIKMD::advGui(protocoltb,$QWIKMD::run) getcolumns 2]
                set index [lsearch $restrains [$QWIKMD::advGui(protocoltb,$QWIKMD::run) cellcget $step,2 -text]]
                set reffile [lindex $QWIKMD::confFile $step]_restraints.pdb
                set constfile [lindex $QWIKMD::confFile $step]_restraints.pdb
                if {$index > -1} {
                    if {$step > 0} {
                        if {[lindex $restrains [expr $step -1]] == [lindex $restrains $step]} {
                            set stepaux $step
                            while {[lindex $restrains [expr $stepaux -1]] == [lindex $restrains $stepaux]} {
                                incr stepaux -1
                                if {$stepaux == 0} {
                                    break
                                }
                            }
                            if {$stepaux >= 1} {
                                set constfile [lindex $QWIKMD::confFile $stepaux]_restraints.pdb
                                set reffile [lindex $QWIKMD::confFile [expr $stepaux -1] ].coor
                            } else {
                                set constfile [lindex $QWIKMD::confFile 0]_restraints.pdb
                                set reffile [lindex $QWIKMD::confFile 0]_restraints.pdb
                            }
                        } else {
                            set reffile [lindex $QWIKMD::confFile [expr $step - 1] ].coor
                        }
                    } 
                } elseif {$step > 0} {
                    set reffile [lindex $QWIKMD::confFile [expr $step - 1] ].coor
                }
                set index [lsearch -regexp -index 0 $QWIKMD::line (?i)consref$]
                if { $index != -1} {
                    QWIKMD::replaceNAMDLine "consref" "consref $reffile"
                    
                } else {
                    puts $auxfile "consref $reffile"
                }
                
                set index [lsearch -regexp -index 0 $QWIKMD::line (?i)conskfile$]
                if { $index != -1} {
                    QWIKMD::replaceNAMDLine "conskfile" "conskfile $constfile"
                } else {
                    puts $auxfile "conskfile $constfile"
                }
                set QWIKMD::mdProtInfo($conf,const) 1
                set QWIKMD::mdProtInfo($conf,constsel) [$QWIKMD::advGui(protocoltb,$QWIKMD::run) cellcget $step,2 -text]
            } elseif {$QWIKMD::advGui(protocoltb,$QWIKMD::run,$step,smd) == 0} {
                set QWIKMD::mdProtInfo($conf,const) 0
                QWIKMD::replaceNAMDLine "constraints" "constraints off"
            }
            if {$QWIKMD::run == "QM/MM"} {
                QWIKMD::QMMMConfOpt $auxfile [file root [lindex $strct 0]] $step
            }
            if {$QWIKMD::basicGui(live,$tabid) == 1} {
                set index [lsearch -regexp $QWIKMD::line "IMDon on"]
                if {$index == -1} {
                    puts $auxfile  "# IMD Parameters"
                    puts $auxfile  "IMDon on    ;#"
                    puts $auxfile  "IMDport 3000    ;# port number (enter it in VMD)"
                    puts $auxfile  "IMDfreq 10  ;# send every 10 frame"
                    puts $auxfile  "IMDwait yes ;# wait for VMD to connect before running?"
                    set opt "yes"
                    if {$tabid == 1 && $QWIKMD::advGui(ignoreforces) == 0} {
                        set opt "no"
                    }
                    puts $auxfile  "IMDignoreForces $opt ;#monitor without the possibility of perturbing the simulation\n\n"
                }
            }
            # set enter "{} {}"
            # set index [lsearch -exact -all $QWIKMD::line $enter]
            # for {set i 0} {$i < [llength $index]} {incr i} {
            #     lset QWIKMD::line [lindex $index $i] [join [lindex $QWIKMD::line [lindex $index $i]]]
            #     lset QWIKMD::line [lindex $index $i] "\n"
            # }
            for {set i 0 } {$i < [llength $QWIKMD::line]} {incr i} {
                set line [lindex $QWIKMD::line $i]
                if { $line == ">> >>"} {
                    puts $auxfile ""
                } elseif {[regexp -all  {\[|\]} $line] == 0 && [lindex $line 0] == ">>"} {
                    puts $auxfile [lindex $line 1]
                } else {
                    puts $auxfile [lindex $QWIKMD::line $i]
                }
            }
            # for {set i 0 } {$i < [llength $QWIKMD::line]} {incr i} {
            #     if {[catch {join [lindex $QWIKMD::line $i]}] == 0} {
            #         if {[join [lindex $QWIKMD::line $i]] ==  "{} {}"} {
            #             puts $auxfile ""
            #         } else {
            #             puts $auxfile [join [lindex $QWIKMD::line $i]]
            #         } 
            #     } else {
            #         puts $auxfile [lindex $QWIKMD::line $i]
            #     }
            # }
            
            close $auxfile
            set outputfile ${QWIKMD::outPath}/run/$conf.conf

        }
        
    
        if {$QWIKMD::advGui(protocoltb,$QWIKMD::run,$step,saveAsTemplate) == 1} {
            file copy -force ${env(QWIKMDTMPDIR)}/$conf.conf ${env(QWIKMDFOLDER)}/templates/$QWIKMD::advGui(solvent,$QWIKMD::run,0)
        }
        set index [lsearch $restrains [lindex $args 2]]
        set tbline $step
        
        set i 0
        while {$i < $step} {
            if {$QWIKMD::advGui(protocoltb,$QWIKMD::run,$i,smd) == 1} {
                break
            }
            incr i
        }
        if {$QWIKMD::run == "SMD" && $QWIKMD::advGui(protocoltb,$QWIKMD::run,$step,smd) == 1 && $i == $step} {
            set tbline $index
        }

        QWIKMD::addNAMDCheck $step
    
        if {$QWIKMD::advGui(solvent,$QWIKMD::run,0) == "Explicit" && $step == 0 && $QWIKMD::curframe <= 0} {
            set file ${QWIKMD::outPath}/run/[lindex $QWIKMD::confFile 0].xsc
            pbc writexst $file
            pbc writexst ${QWIKMD::outPath}/run/[lindex $QWIKMD::confFile 0].xsc
            set xst [open $file r]
            set line [read -nonewline $xst]
            close $xst
            set line [split $line "\n"]
            set values [lindex $line 2]
            set sel [atomselect top "all"]
            set center [measure center $sel]
            $sel delete
            lset values 10 [lindex $center 0]
            lset values 11 [lindex $center 1]
            lset values 12 [lindex $center 2]
            lset line 2 $values

            set xst [open $file w+]
            puts $xst [lindex $line 0]
            puts $xst [lindex $line 1]
            puts $xst [lindex $line 2]
            close $xst
        }

    }

}

proc QWIKMD::GenerateBasicNamdFiles {strct step} {
    cd ${QWIKMD::outPath}/run
    
    set prefix [lindex $QWIKMD::confFile $step]

    set QWIKMD::mdProtInfo($prefix,temp) 0
    set QWIKMD::mdProtInfo($prefix,const) 0
    set QWIKMD::mdProtInfo($prefix,constsel) "protein and backbone"
    set QWIKMD::mdProtInfo($prefix,minimize) 0
    set QWIKMD::mdProtInfo($prefix,smd) 0
    set QWIKMD::mdProtInfo($prefix,smdk) 7.0
    set QWIKMD::mdProtInfo($prefix,ramp) 0
    set QWIKMD::mdProtInfo($prefix,timestep) 2
    set QWIKMD::mdProtInfo($prefix,vdw) 1
    set QWIKMD::mdProtInfo($prefix,electro) 2
    set QWIKMD::mdProtInfo($prefix,cutoff) 12.0
    set QWIKMD::mdProtInfo($prefix,pairlist) 14.0
    set QWIKMD::mdProtInfo($prefix,switch) 10.0
    set QWIKMD::mdProtInfo($prefix,switching) 1
    set QWIKMD::mdProtInfo($prefix,gbis) 0
    set QWIKMD::mdProtInfo($prefix,alphacut) 14.0
    set QWIKMD::mdProtInfo($prefix,solvDie) 80.0
    set QWIKMD::mdProtInfo($prefix,sasa) 0
    set QWIKMD::mdProtInfo($prefix,rampList) [list]
    set QWIKMD::mdProtInfo($prefix,ensemble) "NpT"
    set QWIKMD::mdProtInfo($prefix,run) 0
    set QWIKMD::mdProtInfo($prefix,thermostat) 0
    set QWIKMD::mdProtInfo($prefix,barostat) 0
    set QWIKMD::mdProtInfo($prefix,qmmm) 0
    if {[llength $QWIKMD::maxSteps] == $step} {
        lappend QWIKMD::maxSteps 0
    }
    set namdfile [open $prefix.conf w+]
    set temp [QWIKMD::format2Dec [expr $QWIKMD::basicGui(temperature,$QWIKMD::run,0) + 273]]
    
    puts $namdfile [string repeat "#" 20]
    puts $namdfile [string repeat "#\n" 10]
    puts $namdfile [string repeat "#" 20]

    puts $namdfile "# Initial pdb and pdf files\n"
    puts $namdfile "coordinates [lindex $strct 1]"
    puts $namdfile "structure [lindex $strct 0]\n\n"
    if {$step > 0 } {
        puts $namdfile "set inputname      [lindex $QWIKMD::confFile [expr $step -1]]"
        puts $namdfile "binCoordinates     \$inputname.restart.coor"
        puts $namdfile "binVelocities      \$inputname.restart.vel" 
        puts $namdfile "extendedSystem     \$inputname.restart.xsc\n\n"
    }
    
    puts $namdfile "# Simulation conditions"
    puts $namdfile "set temperature $temp; # Conversion of $QWIKMD::basicGui(temperature,$QWIKMD::run,0) degrees Celsius + 273"

    set QWIKMD::mdProtInfo($prefix,temp) $temp

    if {$step == 0} {
        if {[string match "*equilibration*" [lindex $QWIKMD::confFile $step]] > 0} {
            puts $namdfile "temperature 0\n\n"
        } else {
            puts $namdfile "temperature $temp\n\n"
        }
    } else {
        puts $namdfile "\n"
    }
    set QWIKMD::mdProtInfo($prefix,const) 0
    if {[string match "*_equilibration*" [lindex $QWIKMD::confFile $step] ] > 0 || $QWIKMD::run == "SMD" && [string match "*_production_smd*" [lindex $QWIKMD::confFile $step] ] > 0} {
        puts $namdfile "# Harmonic constraints\n"
        puts $namdfile "constraints on"
        set QWIKMD::mdProtInfo($prefix,const) 1
        if {$QWIKMD::run == "SMD" && [string match "*_production_smd*" [lindex $QWIKMD::confFile $step] ] > 0} {
            
            if {$step > 0} {
                set index [lindex [lsearch -all $QWIKMD::confFile "*_production_smd*"] 0]
                puts $namdfile "consref [lindex $QWIKMD::confFile [expr $index -1 ]].coor"
                puts $namdfile "conskfile [lindex $QWIKMD::confFile [expr $index -1 ]].coor"
            } else {
                puts $namdfile "consref [lindex $strct 1]"
                puts $namdfile "conskfile [lindex $strct 1]"
            }
            
            puts $namdfile "constraintScaling 10"
            puts $namdfile "consexp 2"
        } else {
            puts $namdfile "consref [lindex $QWIKMD::confFile 0]_constraints.pdb"
            puts $namdfile "conskfile [lindex $QWIKMD::confFile 0]_constraints.pdb"
            puts $namdfile "constraintScaling 2"
            puts $namdfile "consexp 2"
            set QWIKMD::mdProtInfo($prefix,constsel) "protein and backbone"
        }
        
        puts $namdfile "conskcol B\n\n"
        
    }
    if {$QWIKMD::run == "SMD" && [string match "*_production_smd*" [lindex $QWIKMD::confFile $step] ] > 0 } {
        puts $namdfile "# steered dynamics"
        puts $namdfile "SMD on"
        set QWIKMD::mdProtInfo($prefix,smd) 1
        if {$step > 0} {
            set index [lindex [lsearch -all $QWIKMD::confFile "*_production_smd*"] 0] 
            puts $namdfile "SMDFile [lindex $QWIKMD::confFile [expr $index -1 ]].coor"
        } else {
            puts $namdfile "SMDFile [lindex $strct 1]"
        }
        set QWIKMD::mdProtInfo($prefix,smdk) 7.0
        set QWIKMD::mdProtInfo($prefix,pspeed) $QWIKMD::basicGui(pspeed)
        puts $namdfile "SMDk 7.0"
        puts $namdfile "SMDVel [format %.3g [expr $QWIKMD::basicGui(pspeed) * 2e-6]]"
        puts $namdfile "SMDDir 0.0 0.0 1.0"
        puts $namdfile "SMDOutputFreq $QWIKMD::smdfreq"
        set i 0
        while {$i < [llength  $QWIKMD::confFile]} {
            if {[string match "*_production_smd*" [lindex $QWIKMD::confFile $i] ] > 0} {
                break
            }
            incr i
        }

        if {$i == $step} {
            puts $namdfile "firstTimestep 0"
        } else {
            puts $namdfile [QWIKMD::addFirstTimeStep $step]
        }
        
    }

    puts $namdfile "# Output Parameters\n"
    puts $namdfile  "binaryoutput no"
    puts $namdfile  "outputname $prefix"
    set freq $QWIKMD::smdfreq
    set tabid [$QWIKMD::topGui.nbinput index current]
    if {$QWIKMD::basicGui(live,$tabid) == 0} {
        set freq [expr $QWIKMD::smdfreq * 10]
    }
    puts $namdfile  "outputenergies $freq"
    puts $namdfile  "outputtiming $freq"
    puts $namdfile  "outputpressure $freq"
    
    set freq $QWIKMD::dcdfreq
    puts $namdfile  "binaryrestart yes"
    puts $namdfile  "dcdfile $prefix.dcd"
    puts $namdfile  "dcdfreq $freq"
    puts $namdfile  "XSTFreq $freq"
    puts $namdfile  "restartfreq $freq"

    puts $namdfile  "restartname $prefix.restart\n\n"
    set QWIKMD::mdProtInfo($prefix,ensemble) NpT 
    if {$step == 0 && $QWIKMD::basicGui(solvent,$QWIKMD::run,0) == "Explicit"} {
        puts $namdfile  "# Periodic Boundary Conditions"
        set length [lindex $QWIKMD::cellDim 3]
        set center [lindex $QWIKMD::cellDim 2]
        puts $namdfile  "cellBasisVector1     [lindex $length 0]   0.0   0.0"
        puts $namdfile  "cellBasisVector2     0.0   [lindex $length 1]   0.0"
        puts $namdfile  "cellBasisVector3     0.0    0     [lindex $length 2]"
        puts $namdfile  "cellOrigin           [lindex $center 0]  [lindex $center 1]  [lindex $center 2]\n\n"

    }

    if {$QWIKMD::basicGui(solvent,$QWIKMD::run,0) == "Explicit"} {
        set QWIKMD::mdProtInfo($prefix,PME) 1
        puts $namdfile  "# PME Parameters\n"
        puts $namdfile  "PME on"
        puts $namdfile  "PMEGridspacing 1\n\n"
    }
    set QWIKMD::mdProtInfo($prefix,thermostat) Langevin
    puts $namdfile  "# Thermostat Parameters\n"
    puts $namdfile  "langevin on"
    if {$QWIKMD::basicGui(prtcl,$QWIKMD::run,equi) ==1 && $step == 0} {
        puts $namdfile  "langevintemp 60"
    } else {
        puts $namdfile  "langevintemp \$temperature"
        
    }

    puts $namdfile  "langevinHydrogen    off"
    puts $namdfile  "langevindamping 1\n\n"
    
    if {$QWIKMD::basicGui(solvent,$QWIKMD::run,0) == "Explicit"} {
        set QWIKMD::mdProtInfo($prefix,barostat) Langevin
        set QWIKMD::mdProtInfo($prefix,press) 1
        puts $namdfile  "# Barostat Parameters\n"
        puts $namdfile  "usegrouppressure yes"
        puts $namdfile  "useflexiblecell no"
        puts $namdfile  "useConstantArea no"
        puts $namdfile  "langevinpiston on"
        puts $namdfile  "langevinpistontarget 1.01325"
        puts $namdfile  "langevinpistonperiod 200"
        puts $namdfile  "langevinpistondecay 100"
        if {$QWIKMD::basicGui(prtcl,$QWIKMD::run,equi) ==1 && $step == 0} {
            puts $namdfile  "langevinpistontemp 60\n\n"
        } else {
            puts $namdfile  "langevinpistontemp \$temperature\n\n"
        }
        puts $namdfile  "wrapAll on"
        puts $namdfile  "wrapWater on\n\n"
    }
    

    puts $namdfile  "# Integrator Parameters\n"
    puts $namdfile  "timestep 2"
    puts $namdfile  "fullElectFrequency 2"
    puts $namdfile  "nonbondedfreq 1\n\n"

    set QWIKMD::mdProtInfo($prefix,timestep) 2
    set QWIKMD::mdProtInfo($prefix,vdw) 1
    set QWIKMD::mdProtInfo($prefix,electro) 2

    puts $namdfile  "# Force Field Parameters\n"
    puts $namdfile  "paratypecharmm on"
    set parfiles [glob *.prm]
    set parfiles [concat $parfiles [glob *.str]]
    for {set i 0} {$i < [llength $parfiles]} {incr i} {
        puts $namdfile "parameters [file tail [lindex $parfiles $i]]"
    }
    puts $namdfile  "exclude scaled1-4"
    puts $namdfile  "1-4scaling 1.0"
    puts $namdfile  "rigidbonds all"
    
    if {$QWIKMD::basicGui(solvent,$QWIKMD::run,0) == "Explicit"} {
        set QWIKMD::mdProtInfo($prefix,cutoff) 12.0
        set QWIKMD::mdProtInfo($prefix,pairlist) 14.0
        set QWIKMD::mdProtInfo($prefix,switch) 10.0
        set QWIKMD::mdProtInfo($prefix,switching) 1
        puts $namdfile  "cutoff 12.0"
        puts $namdfile  "pairlistdist 14.0"
        puts $namdfile  "stepspercycle 10"
        puts $namdfile  "switching on"
        puts $namdfile  "switchdist 10.0\n\n"
    } else {
        set QWIKMD::mdProtInfo($prefix,ensemble) NVE
        set QWIKMD::mdProtInfo($prefix,gbis) 1
        set QWIKMD::mdProtInfo($prefix,cutoff) 16.0
        set QWIKMD::mdProtInfo($prefix,pairlist) 18.0
        set QWIKMD::mdProtInfo($prefix,switch) 15.0
        set QWIKMD::mdProtInfo($prefix,switching) 1
        set QWIKMD::mdProtInfo($prefix,alphacut) 14.0
        set QWIKMD::mdProtInfo($prefix,solvDie) 80.0
        set QWIKMD::mdProtInfo($prefix,sasa) 1
        puts $namdfile  "#Implicit Solvent Parameters\n"
        puts $namdfile  "gbis                on"
        puts $namdfile  "alphaCutoff         14.0"
        puts $namdfile  "ionConcentration    $QWIKMD::basicGui(saltconc,$QWIKMD::run,0)"

        puts $namdfile  "switching  on"
        puts $namdfile  "switchdist 15"
        puts $namdfile  "cutoff     16"
        puts $namdfile  "solventDielectric   80.0"
        puts $namdfile  "sasa                on"
        puts $namdfile  "pairlistdist 18\n\n"
    }

    if {$QWIKMD::basicGui(live,$tabid) == 1} {
        puts $namdfile  "# IMD Parameters"
        puts $namdfile  "IMDon  on  ;#"
        puts $namdfile  "IMDport    3000    ;# port number (enter it in VMD)"
        puts $namdfile  "IMDfreq    10  ;# send every 10 frame"
        puts $namdfile  "IMDwait    yes ;# wait for VMD to connect before running?"
        set opt "yes"
        if {$tabid == 1 && $QWIKMD::advGui(ignoreforces) == 0} {
            set opt "no"
        }
        puts $namdfile  "IMDignoreForces $opt ;#monitor without the possibility of perturbing the simulation\n\n"
    }

    puts $namdfile  "# Script\n"
    set auxMaxstep 0 
    set QWIKMD::mdProtInfo($prefix,minimize) 0
    set QWIKMD::mdProtInfo($prefix,smd) 0
    set QWIKMD::mdProtInfo($prefix,ramp) 0
    if {$QWIKMD::basicGui(prtcl,$QWIKMD::run,equi) == 1 && [string match "*_equilibration*" [lindex $QWIKMD::confFile $step] ] > 0} {
            puts $namdfile  "minimize 1000"
            set QWIKMD::mdProtInfo($prefix,minimize) 1000
            incr auxMaxstep 1000
            puts $namdfile  "reinitvels 60"
    }
    if {[string match "*_equilibration*" [lindex  $QWIKMD::confFile $step] ] > 0} {
        if {$QWIKMD::basicGui(prtcl,$QWIKMD::run,equi) ==1 && $step == 0} {
            set QWIKMD::mdProtInfo($prefix,ramp) 1
            set QWIKMD::mdProtInfo($prefix,rampList) [list 60 $QWIKMD::mdProtInfo($prefix,temp) [QWIKMD::format2Dec [expr 500 * [expr $temp - 60] *2e-6]]]  
            puts $namdfile  "for \{set t 60\} \{\$t <= \$temperature\} \{incr t\} \{"
            if {$QWIKMD::basicGui(solvent,$QWIKMD::run,0) == "Explicit"} {
                puts $namdfile  "\tlangevinpistontemp \$t"
            }
            puts $namdfile  "\trun 500"
            puts $namdfile  "\tlangevintemp \$t"
            puts $namdfile  "\}"
            incr auxMaxstep [expr round(500 * [expr $temp - 60])]
        }
        set QWIKMD::mdProtInfo($prefix,run) [QWIKMD::format2Dec [expr round( 500000 *2e-6)]] 
        puts $namdfile  "run 500000"
        set val 500000
        incr auxMaxstep $val
    } elseif {$QWIKMD::run == "SMD" && [string match "*_production_smd*" [lindex $QWIKMD::confFile $step] ] > 0 } { 
        set val [QWIKMD::format0Dec [expr $QWIKMD::basicGui(mdtime,1) / 2e-6 ]]
        set QWIKMD::mdProtInfo($prefix,run) $QWIKMD::basicGui(mdtime,1)
        set QWIKMD::mdProtInfo($prefix,smd) 1
        puts $namdfile  "run $val"
        incr auxMaxstep $val
    }   elseif {[string match "*_production*" [lindex $QWIKMD::confFile $step] ] > 0 } {
        set val [QWIKMD::format0Dec [expr $QWIKMD::basicGui(mdtime,0) / 2e-6 ]]
        set QWIKMD::mdProtInfo($prefix,run) $QWIKMD::basicGui(mdtime,0)
        puts $namdfile  "run $val"
        incr auxMaxstep $val
        
    }
    # if {$QWIKMD::basicGui(live) == 1 } {
    lset QWIKMD::maxSteps $step $auxMaxstep
    # }

    ################################################################################
    ## The next if statements force the evaluation of the normal termination, and
    ## writes to a check file to if the MD simulation terminated withh success and
    ## it is possible to restart the new simulation of if any of the restart files
    ## files to write and then it is not possible to restart from this point. In this case,
    ## the QWIKMD::state is decremented one step, and the current simulation starts from 
    ## the beginning 
    ################################################################################
    # set file "[lindex $QWIKMD::confFile $step].check"

    # puts $namdfile  "set file \[open $file w+\]"

    # puts $namdfile "set done 1"
    # set str $QWIKMD::run
    
    # puts $namdfile "set run $str"
    # puts $namdfile "if \{\[file exists $prefix.restart.coor\] != 1 || \[file exists $prefix.restart.vel\] != 1 || \[file exists $prefix.restart.xsc\] != 1 \} \{"
    # puts $namdfile "\t set done 0"
    # puts $namdfile "\}"

    # puts $namdfile "if \{\$done == 1\} \{"
    # puts $namdfile "\tputs \$file \"DONE\"\n    flush \$file\n  close \$file"
    # puts $namdfile "\} else \{"
    # puts $namdfile "\tputs \$file \"One or more files filed to be written\"\n   flush \$file\n  close \$file"
    # puts $namdfile "\}"
    close $namdfile
    QWIKMD::addNAMDCheck $step
    return 
}
proc QWIKMD::replaceNAMDLine {strcompare strreplace} {
    set index [lsearch -regexp -index 0 $QWIKMD::line (?i)^$strcompare$]
    
    if { $index != -1} {
        lset QWIKMD::line $index "${strreplace}"
    }
}
proc QWIKMD::GenerateNamdFiles {strct template step args outputfile} {
    global env

    set namdfile ""
    set prefix [lindex $QWIKMD::confFile $step]

    set QWIKMD::mdProtInfo($prefix,temp) 0
    set QWIKMD::mdProtInfo($prefix,const) 0
    set QWIKMD::mdProtInfo($prefix,constsel) "protein and backbone"
    set QWIKMD::mdProtInfo($prefix,minimize) 0
    set QWIKMD::mdProtInfo($prefix,smd) 0
    set QWIKMD::mdProtInfo($prefix,smdk) 7.0
    set QWIKMD::mdProtInfo($prefix,ramp) 0
    set QWIKMD::mdProtInfo($prefix,timestep) 2
    set QWIKMD::mdProtInfo($prefix,vdw) 1
    set QWIKMD::mdProtInfo($prefix,electro) 2
    set QWIKMD::mdProtInfo($prefix,cutoff) 12.0
    set QWIKMD::mdProtInfo($prefix,pairlist) 14.0
    set QWIKMD::mdProtInfo($prefix,switch) 10.0
    set QWIKMD::mdProtInfo($prefix,switching) 1
    set QWIKMD::mdProtInfo($prefix,gbis) 0
    set QWIKMD::mdProtInfo($prefix,alphacut) 14.0
    set QWIKMD::mdProtInfo($prefix,solvDie) 80.0
    set QWIKMD::mdProtInfo($prefix,sasa) 0
    set QWIKMD::mdProtInfo($prefix,rampList) [list]
    set QWIKMD::mdProtInfo($prefix,ensemble) [lindex $args 3]
    set QWIKMD::mdProtInfo($prefix,run) 0
    set QWIKMD::mdProtInfo($prefix,thermostat) 0
    set QWIKMD::mdProtInfo($prefix,barostat) 0
    set QWIKMD::mdProtInfo($prefix,qmmm) 0
    set templatefile [open ${template} r]
    set QWIKMD::line [read $templatefile]
    set QWIKMD::line [split $QWIKMD::line "\n"]
    
    close $templatefile

    # set enter "\n"
    # set index [lsearch -exact -all $QWIKMD::line $enter]
    # for {set i 0} {$i < [llength $index]} {incr i} {
    #     lset QWIKMD::line [lindex $index $i] ">> >>"
    # }

    
    for {set i 0} {$i < [llength $QWIKMD::line]} {incr i} {

        if {[string length [lindex $QWIKMD::line $i]] == 0} {
            lset QWIKMD::line $i ">> >>"
        }
        if {([string index [lindex $QWIKMD::line $i] 0] != "#" && [llength [lindex $QWIKMD::line $i]] == 1)} {
            lset QWIKMD::line $i [split [lindex $QWIKMD::line $i] " "]
        } elseif {[string index [lindex $QWIKMD::line $i] 0] == "#"} {
            lset QWIKMD::line $i [concat ">>" [list [lindex $QWIKMD::line $i]]]
        }  
    }

    # for {set i 0} {$i < [llength $QWIKMD::line]} {incr i} {
    #     lset QWIKMD::line $i [split [lindex $QWIKMD::line $i] " "]
    # }
    # set index [lsearch -exact -all $QWIKMD::line ","]
    # for {set j 0} {$j < [llength $QWIKMD::line]} {incr j} {
    #     set lineaux ""
    #     regsub -all "," [lindex $QWIKMD::line $j] "" lineaux
    #     puts "DEBUG $lineaux"
    #     lset QWIKMD::line $j $lineaux
    # }

    set namdfile [open $outputfile w+]
        
    set temp [expr [lindex $args 4] + 273]
    set tempList [$QWIKMD::advGui(protocoltb,$QWIKMD::run) getcolumns 4]
    set  QWIKMD::mdProtInfo($prefix,temp) [QWIKMD::format0Dec $temp]
    
    QWIKMD::replaceNAMDLine "structure" "structure [lindex $strct 0]"
    QWIKMD::replaceNAMDLine "coordinates" "coordinates [lindex $strct 1]"
    set index [lsearch -regexp -index 0 $QWIKMD::line (?i)structure$]
    
    if {$index == -1} {
        puts $namdfile "structure [lindex $strct 0]"
    }

    set index [lsearch -regexp -index 0 $QWIKMD::line (?i)coordinates$]
    if {$index == -1} {
        puts $namdfile "coordinates [lindex $strct 1]"
    }
    set tempaux 0
    if {$prefix == "Annealing" || $prefix == "QMMM-Ann"} {
        set tempaux 60
        set QWIKMD::mdProtInfo($prefix,ramp) 1

        set str "set nSteps"
        set index [lsearch -regexp $QWIKMD::line (?i)^$str]
        set val 1
        if {$index != -1} {
            set val [lindex [lindex $QWIKMD::line $index] 2]
        }
        set intstep 2
        if {$prefix == "QMMM-Ann"} {
            set intstep 0.5
        }
        set totalrun [QWIKMD::format2Dec [expr $val * [expr $temp - 60] *${intstep}e-6]]
        set QWIKMD::mdProtInfo($prefix,rampList) [list 60 $QWIKMD::mdProtInfo($prefix,temp) $totalrun]
    } elseif {[file root $prefix] != "Minimization" && [file root $prefix] != "QMMM-Min"} {
        set tempaux $temp
    }

    set newtempline ""
    if {$step > 0 || ($step == 0 && $QWIKMD::curframe > 0)} {
        set do 1
        if {$step > 0 && ([file root [lindex $QWIKMD::confFile [expr $step - 1]]] == "Minimization" || [file root [lindex $QWIKMD::confFile [expr $step - 1]]] == "QMMM-Min") || ($step == 0 && [file root [lindex $QWIKMD::confFile $step]] == "QMMM-Min")} {
            set do 0
        } 
        if {($step > 0 && [lindex $tempList $step] != [lindex $tempList [expr $step - 1]] && [llength $tempList] > 1) || [lsearch -index 0 $QWIKMD::userMacros "QM"] > -1} {
            set do 0
        }
        if {$do == 1} {
            set index [lsearch -regexp -index 0 $QWIKMD::line (?i)temperature$]
            QWIKMD::replaceNAMDLine "temperature" "#[lindex $QWIKMD::line $index]"
        } else {
            set newtempline "temperature $tempaux"
        }
    } else {
        set newtempline "temperature $tempaux"
    }
    QWIKMD::replaceNAMDLine "temperature" ${newtempline}
    if {$QWIKMD::advGui(protocoltb,$QWIKMD::run,$step,lock) == 0} {
        
    
        if {$QWIKMD::advGui(solvent,$QWIKMD::run,0) == "Explicit"} {

            set indexcutt [lsearch -regexp -index 0 $QWIKMD::line (?i)^cutoff$]
            if {$indexcutt == -1} {
                puts $namdfile "cutoff 12.0"
                puts $namdfile "pairlistdist 14.0"
                puts $namdfile "switching on"
                puts $namdfile "switchdist 10.0"
                set QWIKMD::mdProtInfo($prefix,cutoff) 12.0
                set QWIKMD::mdProtInfo($prefix,pairlist) 14.0
                set QWIKMD::mdProtInfo($prefix,switch) 10.0
                set QWIKMD::mdProtInfo($prefix,switching) 1
            } else {
                set QWIKMD::mdProtInfo($prefix,cutoff) [lindex [lindex $QWIKMD::line $indexcutt] 1]

                set indexcutt [lsearch -regexp -index 0 $QWIKMD::line (?i)^pairlistdist$]
                if {$indexcutt != -1} {
                    set QWIKMD::mdProtInfo($prefix,pairlist) [lindex [lindex $QWIKMD::line $indexcutt] 1]
                }

                set indexcutt [lsearch -regexp -index 0 $QWIKMD::line (?i)^switchdist$]
                if {$indexcutt != -1} {
                    set QWIKMD::mdProtInfo($prefix,switch) [lindex [lindex $QWIKMD::line $indexcutt] 1]
                }

            }
            
            QWIKMD::replaceNAMDLine "gbis"  "gbis off"
            set QWIKMD::mdProtInfo($prefix,gbis) 0

            set index [lsearch -regexp -index 0 $QWIKMD::line (?i)PME$]
            if { $index == -1} {
                puts $namdfile  "PME on"
                set QWIKMD::mdProtInfo($prefix,PME) 1
            } else {
                if {[lrange [lindex $QWIKMD::line $index] 1 end] == "on"} {
                    set QWIKMD::mdProtInfo($prefix,PME) 1
                } else {
                    set QWIKMD::mdProtInfo($prefix,PME) 0
                }
                
            } 
            
            set index [lsearch -regexp -index 0 $QWIKMD::line (?i)PMEGridspacing$]
            if {$index == -1} {
                puts $namdfile  "PMEGridspacing 1"
            } 
            
            if {$QWIKMD::membraneFrame != "" && $step < 2} {
                set index [lsearch -regexp -index 0 $QWIKMD::line (?i)margin$]
                if { $index == -1} {
                    puts $namdfile  "margin 2.5"
                } 
            }

            set index [lsearch -regexp -index 0 $QWIKMD::line (?i)wrapAll$]
            if { $index == -1} {
                puts $namdfile  "wrapAll on"
            } 
            
            set index [lsearch -regexp -index 0 $QWIKMD::line (?i)wrapWater$]
            if { $index == -1} {
                puts $namdfile  "wrapWater on"
            } 
            
            # QWIKMD::replaceNAMDLine "dielectric" "dielectric 1"

            if {$QWIKMD::membraneFrame != ""} {
                set index [lsearch -regexp -index 0 $QWIKMD::line (?i)useflexiblecell$]
                if { $index == -1} {
                    puts $namdfile  "useflexiblecell yes"
                } else {
                    QWIKMD::replaceNAMDLine "useflexiblecell"  "useflexiblecell yes"
                }

                set index [lsearch -regexp -index 0 $QWIKMD::line (?i)useConstantRatio$]
                if { $index == -1} {
                    puts $namdfile  "useConstantRatio yes"
                } else {
                    QWIKMD::replaceNAMDLine "useConstantRatio"  "useConstantRatio yes"
                }
            }
        } else {
            set indexcutt [lsearch -regexp -index 0 $QWIKMD::line (?i)^cutoff$]
            
            if {$indexcutt == -1} {
                puts $namdfile "cutoff 16"
                puts $namdfile "pairlistdist 18.0"
                puts $namdfile "switching on"
                puts $namdfile "switchdist 15"
                set QWIKMD::mdProtInfo($prefix,cutoff) 16.0
                set QWIKMD::mdProtInfo($prefix,pairlist) 18.0
                set QWIKMD::mdProtInfo($prefix,switch) 15.0
                set QWIKMD::mdProtInfo($prefix,switching) 1
            } else {
                set QWIKMD::mdProtInfo($prefix,cutoff) [lindex [lindex $QWIKMD::line $indexcutt] 1]

                set indexcutt [lsearch -regexp -index 0 $QWIKMD::line (?i)^pairlistdist$]
                if {$indexcutt != -1} {
                    set QWIKMD::mdProtInfo($prefix,pairlist) [lindex [lindex $QWIKMD::line $indexcutt] 1]
                }

                set indexcutt [lsearch -regexp -index 0 $QWIKMD::line (?i)^switchdist$]
                if {$indexcutt != -1} {
                    set QWIKMD::mdProtInfo($prefix,switch) [lindex [lindex $QWIKMD::line $indexcutt] 1]
                }
            }
            
            if {$QWIKMD::advGui(solvent,$QWIKMD::run,0) == "Implicit"} {

                set index [lsearch -regexp -index 0 $QWIKMD::line (?i)^gbis$]
                if { $index != -1} {
                    QWIKMD::replaceNAMDLine "gbis" "gbis on"
                } else {
                    puts $namdfile  "gbis on"
                }
                set QWIKMD::mdProtInfo($prefix,gbis) 1
                set index [lsearch -regexp -index 0 $QWIKMD::line (?i)^alphaCutoff$]
                if { $index != -1} {
                    QWIKMD::replaceNAMDLine "alphaCutoff" "alphaCutoff 14.0"
                } else {
                    puts $namdfile  "alphaCutoff 14.0"
                }
                set QWIKMD::mdProtInfo($prefix,alphacut) 14.0

                set index [lsearch -regexp -index 0 $QWIKMD::line (?i)^solventDielectric$]
                if { $index != -1} {
                    QWIKMD::replaceNAMDLine "solventDielectric" "solventDielectric 80.0"
                } else {
                    puts $namdfile  "solventDielectric 80.0"
                }
                set QWIKMD::mdProtInfo($prefix,solvDie) 80.0

                set index [lsearch -regexp -index 0 $QWIKMD::line (?i)^ionConcentration$]
                if { $index != -1} {
                    QWIKMD::replaceNAMDLine "ionConcentration" "ionConcentration $QWIKMD::advGui(saltconc,$QWIKMD::run,0)"
                } else {
                    puts $namdfile  "ionConcentration $QWIKMD::advGui(saltconc,$QWIKMD::run,0)"
                }
                set QWIKMD::mdProtInfo($prefix,sasa) 1
                set index [lsearch -regexp -index 0 $QWIKMD::line (?i)^sasa$]
                if { $index != -1} {
                     QWIKMD::replaceNAMDLine "sasa" "sasa on"
                } else {
                    puts $namdfile  "sasa on"
                }
                
            } else {

                QWIKMD::replaceNAMDLine "gbis" "gbis off"
                
                QWIKMD::replaceNAMDLine "sasa" "sasa off"

                set QWIKMD::mdProtInfo($prefix,sasa) 0

            }

            QWIKMD::replaceNAMDLine "PME" "PME off"
            QWIKMD::replaceNAMDLine "PMEGridspacing" "#PMEGridspacing 1"
            set QWIKMD::mdProtInfo($prefix,PME) 0
            
        }

        set str "set Temp"
        set index [lsearch -regexp $QWIKMD::line (?i)^$str]

        if {$index != -1} {
            lset QWIKMD::line $index "set Temp $temp"
        }
        
        set str "set nSteps"
        set index [lsearch -regexp $QWIKMD::line (?i)^$str]

        if {$index != -1} {
            set nsteps [expr [lindex $args 1] / [expr $temp - 60] ]
            set val 1
            if {$prefix == "Annealing"} {
                set val 10
            } else {
                set val 1
            }
            set fsteps $nsteps
            if {[expr fmod($nsteps,$val)] > 0} {
                set fsteps [expr int($nsteps + [expr $val - [expr fmod($nsteps,$val)]])]
            }
            lset QWIKMD::line $index "set nSteps  $fsteps"
        }
        set index [lsearch -regexp -index 0 $QWIKMD::line (?i)^minimize$]
        set QWIKMD::mdProtInfo($prefix,minimize) 0
        if {$index != -1} {
            set QWIKMD::mdProtInfo($prefix,minimize) [lindex $args 1]
            QWIKMD::replaceNAMDLine "minimize" "minimize [lindex $args 1]"
        }
        
        QWIKMD::replaceNAMDLine "run" "run [lindex $args 1]"

        set freq $QWIKMD::smdfreq
        set tabid [$QWIKMD::topGui.nbinput index current]
        if {$QWIKMD::basicGui(live,$tabid) == 0} {
            set freq [expr $QWIKMD::smdfreq * 10]
        }
        
        if {$freq > [lindex $args 1]} {
            set freq [lindex $args 1]
        }
        set index [lsearch -regexp -index 0 $QWIKMD::line (?i)^outputenergies$]
        if {$index == -1} {
            puts $namdfile  "outputenergies $freq"
        }

        set index [lsearch -regexp -index 0 $QWIKMD::line (?i)^outputtiming$]
        if {$index == -1} {
            puts $namdfile  "outputtiming $freq"
        }

        set index [lsearch -regexp -index 0 $QWIKMD::line (?i)^outputpressure$]
        if {$index == -1} {

            puts $namdfile  "outputpressure $freq"
        }

        set freq $QWIKMD::dcdfreq
        if {$freq > [lindex $args 1]} {
            set freq [lindex $args 1]
        }

        if {$QWIKMD::run == "QM/MM" && $QWIKMD::advGui(qmoptions,execseqproc,$prefix) == 1} {
            set freq $QWIKMD::advGui(qmoptions,dcdfrq,$prefix)
        }

        set index [lsearch -regexp -index 0 $QWIKMD::line (?i)^dcdfreq$]
        if {$index == -1} {
            puts $namdfile  "dcdfreq $freq"
        } elseif {$QWIKMD::run == "QM/MM" && $QWIKMD::advGui(qmoptions,execseqproc,$prefix) == 1} {
            QWIKMD::replaceNAMDLine "dcdfreq" "dcdfreq $freq"
        }

        set index [lsearch -regexp -index 0 $QWIKMD::line (?i)^XSTFreq$]
        if {$index == -1} {
        
            puts $namdfile  "XSTFreq $freq"
        }

        set index [lsearch -regexp -index 0 $QWIKMD::line (?i)^restartfreq$]
        set minimize [lsearch -regexp -index 0 $QWIKMD::line (?i)^minimize$]
        if {$index == -1} {
        
            set restart $freq
            if {$minimize != -1} {
                set restart [lindex $args 1]
            }
            puts $namdfile  "restartfreq $restart"
        }
    } else {
        ####Values for the text log file
        set index [lsearch -regexp -index 0 $QWIKMD::line (?i)temperature$]
        if {$index != -1} {
            set  QWIKMD::mdProtInfo($prefix,temp) [lindex [lindex $QWIKMD::line $index] 1]
        }

        set index [lsearch -regexp -index 0 $QWIKMD::line (?i)cutoff$]
        if {$index != -1} {
            set  QWIKMD::mdProtInfo($prefix,cutoff) [lindex [lindex $QWIKMD::line $index] 1]
        }

        set index [lsearch -regexp -index 0 $QWIKMD::line (?i)pairlistdist$]
        if {$index != -1} {
            set  QWIKMD::mdProtInfo($prefix,pairlist) [lindex [lindex $QWIKMD::line $index] 1]
        }

        set index [lsearch -regexp -index 0 $QWIKMD::line (?i)switchdist$]
        if {$index != -1} {
            set  QWIKMD::mdProtInfo($prefix,switch) [lindex [lindex $QWIKMD::line $index] 1]
        } 

        set index [lsearch -regexp -index 0 $QWIKMD::line (?i)alphaCutoff$]
        if {$index != -1} {
            set  QWIKMD::mdProtInfo($prefix,alphacut) [lindex [lindex $QWIKMD::line $index] 1]
        }

        set index [lsearch -regexp -index 0 $QWIKMD::line (?i)solventDielectric$]
        if {$index != -1} {
            set QWIKMD::mdProtInfo($prefix,solvDie) [lindex [lindex $QWIKMD::line $index] 1]
        }

        set index [lsearch -regexp -index 0 $QWIKMD::line (?i)sasa$]
        if {$index != -1} {
            set on [string trim [join [lindex [lindex $QWIKMD::line $index] 1]]]
            if {$on == "on"} {
                set  QWIKMD::mdProtInfo($prefix,sasa) 1
            } elseif {$on == "off"} {
                set  QWIKMD::mdProtInfo($prefix,sasa) 1
            }
        }
            
        # set index [lsearch -regexp -index 0 $QWIKMD::line (?i)dielectric$]
        # if {$index != -1} {
        #     set  QWIKMD::mdProtInfo($prefix,diel) [lindex [lindex $QWIKMD::line $index] 1]
        # }

        set QWIKMD::mdProtInfo($prefix,minimize) 0
        set index [lsearch -regexp -index 0 $QWIKMD::line (?i)minimize$]
        if {$index != -1} {
            set  QWIKMD::mdProtInfo($prefix,minimize) [lindex [lindex $QWIKMD::line $index] 1]
        }

        
    
        set index [lsearch -regexp -index 0 $QWIKMD::line (?i)SMD$]
        if {$index != -1} {
            set on [string trim [join [lindex [lindex $QWIKMD::line $index] 1]]]
            if {$on == "on"} {
                set  QWIKMD::mdProtInfo($prefix,smd) 1
            } elseif {$on == "off"} {
                set  QWIKMD::mdProtInfo($prefix,smd) 0
            }
        }


    }
    set QWIKMD::mdProtInfo($prefix,const) 0
    if {[lindex $args 2] != "none"} {
        #if {$QWIKMD::advGui(protocoltb,$QWIKMD::run,$step,lock) == 0} {
            set index [lsearch -regexp -index 0 $QWIKMD::line (?i)constraints$]
            if { $index != -1} {
                QWIKMD::replaceNAMDLine "constraints" "constraints on"
                
            } else {
                puts $namdfile "constraints on"
            }
            set index [lsearch -regexp -index 0 $QWIKMD::line (?i)conskcol$]
            if { $index != -1} {
                QWIKMD::replaceNAMDLine "conskcol" "conskcol B"
                
            } else {
                puts $namdfile "conskcol B"
            }
        #}
        set restrains [$QWIKMD::advGui(protocoltb,$QWIKMD::run) getcolumns 2]
        set index [lsearch $restrains [lindex $args 2]]
        set tbline $step
        set reffile [lindex $QWIKMD::confFile $step]_restraints.pdb
        set constfile [lindex $QWIKMD::confFile $step]_restraints.pdb
        if {$index > -1} {
            if {$step > 0} {
                if {[lindex $restrains [expr $step -1]] == [lindex $restrains $step]} {
                    set stepaux $step
                    while {[lindex $restrains [expr $stepaux -1]] == [lindex $restrains $stepaux]} {
                        incr stepaux -1
                        if {$stepaux == 0} {
                            break
                        }
                    }
                    if {$stepaux >= 1} {
                        set constfile [lindex $QWIKMD::confFile $stepaux]_restraints.pdb
                        set reffile [lindex $QWIKMD::confFile [expr $stepaux -1] ].coor
                    } else {
                        set constfile [lindex $QWIKMD::confFile 0]_restraints.pdb
                        set reffile [lindex $QWIKMD::confFile 0]_restraints.pdb
                    }
                } else {
                    set reffile [lindex $QWIKMD::confFile [expr $step - 1] ].coor
                }
            } 
        } elseif {$step > 0} {
            set reffile [lindex $QWIKMD::confFile [expr $step - 1] ].coor
        }
        set index [lsearch -regexp -index 0 $QWIKMD::line (?i)consref$]
        if { $index != -1} {
            QWIKMD::replaceNAMDLine "consref" "consref $reffile"
            
        } else {
            puts $namdfile "consref $reffile"
        }
        
        set index [lsearch -regexp -index 0 $QWIKMD::line (?i)conskfile$]
        if { $index != -1} {
            QWIKMD::replaceNAMDLine "conskfile" "conskfile $constfile"
        } else {
            puts $namdfile "conskfile $constfile"
        }
        set QWIKMD::mdProtInfo($prefix,const) 1
        set QWIKMD::mdProtInfo($prefix,constsel) [lindex $args 2]
    } else {
        set QWIKMD::mdProtInfo($prefix,const) 0
        QWIKMD::replaceNAMDLine "constraints" "constraints off"
    }

    set indexswichting [lsearch -regexp -index 0 $QWIKMD::line (?i)switching$] 
    set on [string trim [join [lindex [lindex $QWIKMD::line $index] 1]]]
    if {$on == "on"} {
        set  QWIKMD::mdProtInfo($prefix,switching) 1
    } elseif {$on == "off"} {
        set  QWIKMD::mdProtInfo($prefix,switching) 0
    }

    set index [lsearch -regexp -index 0 $QWIKMD::line (?i)timestep$]
    if {$index != -1} {
        set  QWIKMD::mdProtInfo($prefix,timestep) [lindex [lindex $QWIKMD::line $index] 1]
    }
    
    if {$QWIKMD::mdProtInfo($prefix,run) == 0 && $prefix != "Minimization"} {
        set sum [lindex $args 1]
        if {$QWIKMD::advGui(protocoltb,$QWIKMD::run,$step,lock) == 1} {
            set index [lsearch -regexp -index 0 -all $QWIKMD::line (?i)run$]
            set sum 0
            foreach ind $index {
                set sum [expr $sum + [lindex [lindex $QWIKMD::line $index] 1]]
            }
        } 
        set QWIKMD::mdProtInfo($prefix,run) [QWIKMD::format2Dec [expr $sum * $QWIKMD::mdProtInfo($prefix,timestep) * 1e-6]]
    }
    
    set index [lsearch -regexp -index 0 $QWIKMD::line (?i)fullElectFrequency$]
    if {$index != -1} {
        set  QWIKMD::mdProtInfo($prefix,electro) [lindex [lindex $QWIKMD::line $index] 1]
    }

    set index [lsearch -regexp -index 0 $QWIKMD::line (?i)nonbondedfreq$]
    if {$index != -1} {
        set  QWIKMD::mdProtInfo($prefix,vdw) [lindex [lindex $QWIKMD::line $index] 1]
    }
    set QWIKMD::mdProtInfo($prefix,thermostat) 0
    if {[lsearch [lindex $args 3] *T*] > -1 } {
        

        set indexLangevin [lsearch -regexp -index 0 $QWIKMD::line (?i)langevin$]
        set indexAndersen [lsearch -regexp -index 0 $QWIKMD::line (?i)loweAndersen$]
        if { $indexLangevin == -1 && $indexAndersen == -1} {
            puts $namdfile  "langevin on"
            puts $namdfile  "langevintemp $tempaux"
            set QWIKMD::mdProtInfo($prefix,thermostat) Langevin

    
        } else {
            if {[string trim [lindex [lindex $QWIKMD::line $indexLangevin] 1]] == "on" } {
                set QWIKMD::mdProtInfo($prefix,thermostat) Langevin
            } elseif {[string trim [lindex [lindex $QWIKMD::line $indexAndersen] 1]] == "on"} {
                set QWIKMD::mdProtInfo($prefix,thermostat) LoweAndersen
            }

            QWIKMD::replaceNAMDLine "langevin" "langevin on"
            QWIKMD::replaceNAMDLine "loweAndersen" "loweAndersen on"


            set index [lsearch -regexp -index 0 $QWIKMD::line (?i)langevintemp$]
            if {$QWIKMD::advGui(protocoltb,$QWIKMD::run,$step,lock) == 0} {
                QWIKMD::replaceNAMDLine "langevintemp" "langevintemp $tempaux"
                QWIKMD::replaceNAMDLine "loweAndersenTemp" "loweAndersenTemp $tempaux"
    
                set QWIKMD::mdProtInfo($prefix,temp) $tempaux
            } else {
                if {$indexLangevin != -1} {
                    set index [lsearch -regexp -index 0 $QWIKMD::line (?i)langevintemp$]
                    if {$index != -1} {
                        set QWIKMD::mdProtInfo($prefix,temp) [lindex [lindex $QWIKMD::line $index] 1]
                    }
                } else {
                    set index [lsearch -regexp -index 0 $QWIKMD::line (?i)loweAndersenTemp$]
                    if {$index != -1} {
                        set QWIKMD::mdProtInfo($prefix,temp) [lindex [lindex $QWIKMD::line $index] 1]
                    }
                }
            }  
        }
    } else {
        QWIKMD::replaceNAMDLine "langevin" "langevin off"
        QWIKMD::replaceNAMDLine "loweAndersen" "loweAndersen off"
    }
    set QWIKMD::mdProtInfo($prefix,barostat) 0
    if {[lsearch [lindex $args 3] *p*] > -1 } {
        set indexLangevin [lsearch -regexp -index 0 $QWIKMD::line (?i)langevinpiston$]
        set indexBerendsen [lsearch -regexp -index 0 $QWIKMD::line (?i)BerendsenPressure$]
        set press "[QWIKMD::format5Dec [expr [lindex $args 5] * 1.01325]]"
        if { $indexLangevin == -1 && $indexBerendsen == -1} {
            puts $namdfile  "langevinpiston on"
            puts $namdfile  "langevinpistontarget $press"
            puts $namdfile  "langevinpistontemp $tempaux"
            set QWIKMD::mdProtInfo($prefix,barostat) Langevin
            set QWIKMD::mdProtInfo($prefix,press) [lindex $args 5]

        } else {
            QWIKMD::replaceNAMDLine "langevinpiston" "langevinpiston on"
            QWIKMD::replaceNAMDLine "BerendsenPressure" "BerendsenPressure on"
            
            
            if {$QWIKMD::advGui(protocoltb,$QWIKMD::run,$step,lock) == 0} {
                if {[string trim [lindex [lindex $QWIKMD::line $indexLangevin] 1]] == "on" } {
                    set QWIKMD::mdProtInfo($prefix,barostat) Langevin
                } elseif {[string trim [lindex [lindex $QWIKMD::line $indexBerendsen] 1]] == "on"} {
                    set QWIKMD::mdProtInfo($prefix,barostat) Berendsen
                }
                set QWIKMD::mdProtInfo($prefix,press) [lindex $args 5]
                QWIKMD::replaceNAMDLine "langevinpistontarget" "langevinpistontarget $press"
                QWIKMD::replaceNAMDLine "BerendsenPressureTarget" "BerendsenPressureTarget $press"
            } else {
                if {$indexLangevin != -1} {
                    set index [lsearch -regexp -index 0 $QWIKMD::line (?i)langevinpistontarget$]
                    if {$index != -1} {
                        set QWIKMD::mdProtInfo($prefix,press) [QWIKMD::format2Dec [expr [lindex [lindex $QWIKMD::line $index] 1] / 1.01325 ]]
                    }
                } else {
                    set index [lsearch -regexp -index 0 $QWIKMD::line (?i)BerendsenPressureTarget$]
                    if {$index != -1} {
                        set QWIKMD::mdProtInfo($prefix,press) [QWIKMD::format2Dec [expr [lindex [lindex $QWIKMD::line $index] 1] / 1.01325 ]]
                    }
                }
            }
            
            set index [lsearch -regexp -index 0 $QWIKMD::line (?i)langevinpistontemp$]
            if { $index != -1} {
                set tempaux 1
                if {$prefix == "Annealing" || $prefix == "QMMM-Ann"} {
                    set tempaux 60
                    
                } elseif {[file root $prefix] != "Minimization" && [file root $prefix] != "QMMM-Min"} {
                    set tempaux $temp
                }
                QWIKMD::replaceNAMDLine "langevinpistontemp" "langevinpistontemp $tempaux"
            }
        }
    } else {
        QWIKMD::replaceNAMDLine "langevinpiston" "langevinpiston off"
        QWIKMD::replaceNAMDLine "BerendsenPressure" "BerendsenPressure off"

        set str "set barostat"
        set index [lsearch -regexp $QWIKMD::line (?i)^$str]
        if {$prefix == "Annealing" || $prefix == "QMMM-Ann"} {
            if { $index != -1} {
            lset QWIKMD::line $index "set barostat 0"
            } else {
                puts $namdfile "set barostat 0"
            }
        }

    }


    if {$step > 0} {
        set inputname [lindex $QWIKMD::confFile [expr $step -1]]
        set index [lsearch -regexp -index 0 $QWIKMD::line (?i)#binCoordinates$]
        if {$index != -1} {
            QWIKMD::replaceNAMDLine "#binCoordinates" "binCoordinates $inputname.restart.coor"
        } else {
             set index [lsearch -regexp -index 0 $QWIKMD::line (?i)binCoordinates$]
             if {$index != -1} {
                QWIKMD::replaceNAMDLine "binCoordinates" "binCoordinates $inputname.restart.coor"
            } else {
                puts $auxfile "binCoordinates $inputname.restart.coor"
            }
        }
        set tempdef 0
        if {[lindex $tempList $step] != [lindex $tempList [expr $step - 1]] && $QWIKMD::advGui(protocoltb,$QWIKMD::run,$step,lock) == 0} {
            set tempdef 1
        }
        if {[file root $inputname] != "Minimization" && $tempdef == 0 && [file root $inputname] != "QMMM-Min"} {
            QWIKMD::replaceNAMDLine "binVelocities" "binVelocities $inputname.restart.vel"
            QWIKMD::replaceNAMDLine "#binVelocities" "binVelocities $inputname.restart.vel"

            # set index [lsearch -regexp -index 0 $QWIKMD::line (?i)temperature$]
            # QWIKMD::replaceNAMDLine "temperature" "#[lindex $QWIKMD::line $index]"
        } else {
            set index [lsearch -regexp -index 0 $QWIKMD::line (?i)binVelocities$]
            if {$index != -1} {
                QWIKMD::replaceNAMDLine "binVelocities" "#[lindex $QWIKMD::line $index]"
            }
        }
        
        if {$QWIKMD::advGui(solvent,$QWIKMD::run,0) == "Explicit"} {
            set index [lsearch -regexp -index 0 $QWIKMD::line (?i)#extendedSystem$]
            if { $index != -1} {
                QWIKMD::replaceNAMDLine "#extendedSystem" "extendedSystem $inputname.restart.xsc"
            } else {
                set index [lsearch -regexp -index 0 $QWIKMD::line (?i)extendedSystem$]
                if {$index != -1} {
                    QWIKMD::replaceNAMDLine "extendedSystem" "extendedSystem $inputname.restart.xsc"
                } else {
                    puts $namdfile "extendedSystem $inputname.restart.xsc"
                }
            }
        } else {
            set index [lsearch -regexp -index 0 $QWIKMD::line (?i)extendedSystem$]
            QWIKMD::replaceNAMDLine "extendedSystem" "#extendedSystem $inputname.restart.xsc"
        }

    } elseif {$step == 0} {
        if {$QWIKMD::advGui(solvent,$QWIKMD::run,0) == "Explicit"} {
            set index [lsearch -regexp -index 0 $QWIKMD::line (?i)extendedSystem$]
            if { $index != -1} {
                QWIKMD::replaceNAMDLine "extendedSystem" "extendedSystem $prefix.xsc"
                
            } else {
                puts $namdfile "extendedSystem $prefix.xsc"
            }
        } else {
            set index [lsearch -regexp -index 0 $QWIKMD::line (?i)extendedSystem$]
            QWIKMD::replaceNAMDLine "extendedSystem" "#[lindex $QWIKMD::line $index]"
        }
        
        set index [lsearch -regexp -index 0 $QWIKMD::line (?i)binCoordinates$]
        QWIKMD::replaceNAMDLine "binCoordinates" "#[lindex $QWIKMD::line $index]"
        
        set type [$QWIKMD::topGui.nbinput.f2.tableframe.tb getcolumns 2]
        set index [lsearch -regexp -index 0 $QWIKMD::line (?i)binVelocities$]
        if {$QWIKMD::load == 0 || $QWIKMD::curframe == 0 || [file root $prefix] == "Minimization" || [file root $prefix] == "QMMM-Min"\
         || ($QWIKMD::run == "QM/MM" && [lsearch $type "QM"] > -1)} {
            QWIKMD::replaceNAMDLine "binVelocities" "#[lindex $QWIKMD::line $index]"
        } elseif {$QWIKMD::curframe != 0} {
            set velfile ""
            if {$QWIKMD::curframe == -1} {
                set velfile "qwikmdTemp.restart.vel"
            } else {
                catch {glob $QWIKMD::outPath/run/*.vel} velfile
                set velfile [file tail $velfile]
            }
            if { $index != -1} {
                QWIKMD::replaceNAMDLine "binVelocities" "binVelocities $velfile"
            } else {
                puts $namdfile "binVelocities $velfile"
            }
        }

    }

    if {$QWIKMD::run == "MD" && [lsearch -index 0 $QWIKMD::userMacros "QM"] > -1} {
        set do 1
        ## Check if during the preparation phase, the user deleted the supposed
        ## QM molecules
        if {$QWIKMD::prepared == 1} {
            set sel [atomselect top "not water and not ion"]
            if {[lindex [lsort -unique -integer [$sel get "QM"]] end] == 0} {
                set do 0
            }
            $sel delete
        }
        if {$do == 1} {
            puts $namdfile "fixedAtoms on"
            puts $namdfile "fixedAtomsFile [file root [lindex $strct 0]]_fixed.pdb" 
            puts $namdfile "fixedAtomsCol B" 
        }
        

    } elseif {$QWIKMD::run == "SMD"} {
        if {$QWIKMD::advGui(protocoltb,$QWIKMD::run,$step,smd) == 1} {
            set smdtxt "SMD"
            set index [lsearch -regexp -index 0 $QWIKMD::line (?i)SMD$]
            if {$index != -1} {
                QWIKMD::replaceNAMDLine "SMD" "SMD on"
                set  QWIKMD::mdProtInfo($prefix,smd) 1
            } else {
                puts $namdfile "SMD on"
            }

            if {$QWIKMD::advGui(protocoltb,$QWIKMD::run,$step,lock) == 0} {
                set index [lsearch -regexp -index 0 $QWIKMD::line (?i)SMDVel$]
                set val [format %.3g [expr $QWIKMD::basicGui(pspeed) * 2e-6]]
                if {$index != -1} {
                    QWIKMD::replaceNAMDLine "SMDVel" "SMDVel $val"
                } else {
                    puts $namdfile "SMDVel $val"
                }
                set QWIKMD::mdProtInfo($prefix,pspeed) $QWIKMD::basicGui(pspeed)
            } else {
                set index [lsearch -regexp -index 0 $QWIKMD::line (?i)SMDVel$]
                if {$index != -1} {
                    set QWIKMD::basicGui(pspeed) [QWIKMD::format2Dec [expr [expr [string trim [join [lindex [lindex $QWIKMD::line $index] 1]]]  / $QWIKMD::mdProtInfo($prefix,timestep) ] * 1e6 ] ]
                    set QWIKMD::mdProtInfo($prefix,pspeed) $QWIKMD::basicGui(pspeed)
                }
            }
            
            set index [lsearch -regexp -index 0 $QWIKMD::line (?i)SMDk$]
            if {$index != -1} {
                set QWIKMD::mdProtInfo($prefix,smdk) [string trim [join [lindex [lindex $QWIKMD::line $index] 1]]]
            }

            set index [lsearch -regexp -index 0 $QWIKMD::line (?i)consref$]
            set i 0
            while {$i < [llength  $QWIKMD::confFile]} {
                if {$QWIKMD::advGui(protocoltb,$QWIKMD::run,$i,smd) == 1} {
                    break
                }
                incr i
            }

            set smdfile [lindex $strct 1]
            if {$step > 0} {
                set smdfile [lindex $QWIKMD::confFile [expr $i -1] ].coor
            }

            set index [lsearch -regexp -index 0 $QWIKMD::line (?i)SMDFile$]
            if {$index != -1} {
                QWIKMD::replaceNAMDLine "SMDFile" "SMDFile $smdfile"
            } else {
                puts $namdfile "SMDFile $smdfile"
            } 

            
            if {$index != -1} {
                QWIKMD::replaceNAMDLine "consref" "consref $smdfile"
            } else {
                puts $namdfile "consref $smdfile"
            }
                
            set index [lsearch -regexp -index 0 $QWIKMD::line (?i)conskfile$]
            if {$index != -1} {
                QWIKMD::replaceNAMDLine "conskfile" "conskfile $smdfile"
            } else {
                puts $namdfile "conskfile $smdfile"
            }

            set index [lsearch -regexp -index 0 $QWIKMD::line (?i)constraints$]
            if {$index != -1} {
                QWIKMD::replaceNAMDLine "constraints" "constraints on"
            } else {
                puts $namdfile "constraints on"
            }

            set i 0
            
            while {$i < [llength  $QWIKMD::confFile]} {
                if {$QWIKMD::advGui(protocoltb,$QWIKMD::run,$i,smd) == 1} {
                    break
                }
                incr i
            }
            if {[file dirname $outputfile] == "${QWIKMD::outPath}/run"} {
                if {$i == $step} {
                    set index [lsearch -regexp -index 0 $QWIKMD::line (?i)firstTimestep$]
                    if { $index != -1} {
                        QWIKMD::replaceNAMDLine "firstTimestep" "firstTimestep 0"
                    } else {
                        puts $namdfile "firstTimestep 0"
                    }
                } else {
                    set index [lsearch -regexp -index 0 $QWIKMD::line (?i)firstTimestep$]
                    if {$index != -1} {
                        QWIKMD::replaceNAMDLine "firstTimestep" "[QWIKMD::addFirstTimeStep $step]"
                    } else {
                        puts $namdfile [QWIKMD::addFirstTimeStep $step]
                    }
                }
            }
        }
    } elseif {$QWIKMD::run == "QM/MM"} {
        if {$QWIKMD::advGui(protocoltb,$QWIKMD::run,$step,qmmm) == 1} {
            set QWIKMD::mdProtInfo($prefix,qmmm) 1
            set QWIKMD::mdProtInfo($prefix,timestep) 0.5
            QWIKMD::QMMMConfOpt $namdfile [file root [lindex $strct 0]] $step
        }
    }

    set firstindex [lindex [lsearch -all -regexp -index 0 $QWIKMD::line (?i)parameters$] end]
    if {[llength $firstindex] > 0} {
        set listaux [list]
        set listaux [lrange $QWIKMD::line 0 $firstindex]
        foreach parm $QWIKMD::ParameterList {
            set file [file tail ${parm}]
            set index [lsearch -regexp $QWIKMD::line "parameters $file"]
            if {$index == -1 && ([file extension $file] == ".str" || [file extension $file] == ".prm" || [file extension $file] == ".rtf") } {
                lappend listaux "parameters $file"
            }
        }
        if {[llength $listaux] > 0 } {
            incr firstindex
            while {[lsearch -regexp -start $firstindex -index 0 $QWIKMD::line (?i)parameters$] != -1} {
                incr firstindex
            }
            set QWIKMD::line [concat $listaux [lrange $QWIKMD::line $firstindex end]]
            unset listaux
        }
    } else {
        foreach parm $QWIKMD::ParameterList {
            set file [file tail ${parm}]
            set index [lsearch -regexp $QWIKMD::line "parameters $file"]
            if {$index == -1 && ([file extension $file] == ".str" || [file extension $file] == ".prm" || [file extension $file] == ".rtf") } {
                puts $namdfile [file tail ${parm}]
            }
        }
    }

    QWIKMD::replaceNAMDLine "outputname" "outputname [lindex $QWIKMD::confFile $step]"
    QWIKMD::replaceNAMDLine "dcdfile" "dcdfile [lindex $QWIKMD::confFile $step].dcd"
    QWIKMD::replaceNAMDLine "restartname" "restartname [lindex $QWIKMD::confFile $step].restart"
    set tabid [$QWIKMD::topGui.nbinput index current]
    if {$QWIKMD::basicGui(live,$tabid) == 1} {
        set index [lsearch -regexp $QWIKMD::line "IMDon on"]
        if {$index == -1} {
            puts $namdfile  "# IMD Parameters"
            puts $namdfile  "IMDon on   ;#"
            puts $namdfile  "IMDport    3000    ;# port number (enter it in VMD)"
            puts $namdfile  "IMDfreq    10  ;# send every 10 frame"
            puts $namdfile  "IMDwait    yes ;# wait for VMD to connect before running?"
            set opt "yes"
            if {$tabid == 1 && $QWIKMD::advGui(ignoreforces) == 0} {
                set opt "no"
            }
            puts $namdfile  "IMDignoreForces $opt ;#monitor without the possibility of perturbing the simulation\n"
        }    
    }
    lset QWIKMD::maxSteps $step [lindex $args 1]
    
    
    # set enter "{} {}"
    # set index [lsearch -exact -all $QWIKMD::line $enter]
    # for {set i 0} {$i < [llength $index]} {incr i} {
    #     lset QWIKMD::line [lindex $index $i] [join [lindex $QWIKMD::line [lindex $index $i]]]
    #     lset QWIKMD::line [lindex $index $i] ""
    # }

    

    for {set i 0 } {$i < [llength $QWIKMD::line]} {incr i} {
        set line [lindex $QWIKMD::line $i]
        if { $line == ">> >>"} {
            puts $namdfile ""
        } elseif {[regexp -all  {\[|\]} $line] == 0 && [lindex $line 0] == ">>"} {
            puts $namdfile [lindex $line 1]
        } else {
            puts $namdfile [lindex $QWIKMD::line $i]
        }
    }
    
    close $namdfile
    
    return $env(QWIKMDTMPDIR)/$prefix.conf
    
     
}
proc QWIKMD::QMMMConfOpt {namdfile filename step} {
    global env
    set prtclname $QWIKMD::advGui(protocoltb,$QWIKMD::run,$step)
    set index [lsearch -regexp -index 0 $QWIKMD::line (?i)qmColumn$]
    if {$QWIKMD::prepared == 1} {
        if {$index != -1} {
            QWIKMD::replaceNAMDLine "qmParamPDB" "qmParamPDB ${filename}_qm-input.pdb"
        } else {
            puts $namdfile "qmParamPDB ${filename}_qm-input.pdb"
        }
    }
    
    # set index [lsearch -regexp -index 0 $QWIKMD::line (?i)qmColumn$]
    if {$index != -1} {
        QWIKMD::replaceNAMDLine "qmColumn" "qmColumn beta"
    } else {
        puts $namdfile "qmColumn beta"
    }

    set index [lsearch -regexp -index 0 $QWIKMD::line (?i)qmBondColumn$]
    if {$index != -1} {
        QWIKMD::replaceNAMDLine "qmBondColumn" "qmBondColumn occ"
    } else {
        puts $namdfile "qmBondColumn occ"
    }

    ### QMSimsPerNode = Number of QM Regions ensures that each QM region will
    ### have a dedicated folder inside the qmbasedir (e.g. 0 and 1)
    set index [lsearch -regexp -index 0 $QWIKMD::line (?i)QMSimsPerNode$]
    if {$index != -1} {
        QWIKMD::replaceNAMDLine "QMSimsPerNode" "QMSimsPerNode [$QWIKMD::advGui(qmtable) size]"
    } else {
        puts $namdfile "QMSimsPerNode [$QWIKMD::advGui(qmtable) size]"
    }


    if {$QWIKMD::advGui(qmoptions,switchtype,$prtclname) != "Off"} {
        set index [lsearch -regexp -index 0 $QWIKMD::line (?i)QMSwitching$]
        if {$index != -1} {
            QWIKMD::replaceNAMDLine "QMSwitching" "QMSwitching on"
        } else {
            puts $namdfile "QMSwitching on"
        }

        set index [lsearch -regexp -index 0 $QWIKMD::line (?i)QMSwitchingType$]
        if {$index != -1} {
            QWIKMD::replaceNAMDLine "QMSwitchingType" "QMSwitchingType $QWIKMD::advGui(qmoptions,switchtype,$prtclname)"
        } else {
            puts $namdfile "QMSwitchingType $QWIKMD::advGui(qmoptions,switchtype,$prtclname)"
        }

        set index [lsearch -regexp -index 0 $QWIKMD::line (?i)QMPointChargeScheme$]
        if {$index != -1} {
            QWIKMD::replaceNAMDLine "QMPointChargeScheme" "QMPointChargeScheme $QWIKMD::advGui(qmoptions,ptchrgschm,$prtclname)"
        } else {
            puts $namdfile "QMPointChargeScheme $QWIKMD::advGui(qmoptions,ptchrgschm,$prtclname)"
        }

        set index [lsearch -regexp -index 0 $QWIKMD::line (?i)QMBondScheme$]
        if {$index != -1} {
            QWIKMD::replaceNAMDLine "QMBondScheme" "QMBondScheme $QWIKMD::advGui(qmoptions,qmbondsheme,$prtclname)"
        } else {
            puts $namdfile "QMBondScheme $QWIKMD::advGui(qmoptions,qmbondsheme,$prtclname)"
        }
        
    } else {
        set index [lsearch -regexp -index 0 $QWIKMD::line (?i)QMSwitching$]
        if {$index != -1} {
            QWIKMD::replaceNAMDLine "QMSwitching" "QMSwitching off"
        } else {
            puts $namdfile "QMSwitching off"
        }
    }
  
    set index [lsearch -regexp -index 0 $QWIKMD::line (?i)qmElecEmbed$]
    if {$index != -1} {
        QWIKMD::replaceNAMDLine "qmElecEmbed" "qmElecEmbed $QWIKMD::advGui(qmoptions,ptcharge,$prtclname)"
    } else {
        puts $namdfile "qmElecEmbed $QWIKMD::advGui(qmoptions,ptcharge,$prtclname)"
    }
    if {$QWIKMD::advGui(qmoptions,cmptcharge,$prtclname) == "On" && $QWIKMD::prepared == 1} {
        set index [lsearch -regexp -index 0 $QWIKMD::line (?i)QMCustomPCFile$]
        if {$index != -1} {
            QWIKMD::replaceNAMDLine "QMCustomPCSelection" "QMCustomPCSelection on"
        } else {
            puts $namdfile "QMCustomPCSelection on"
        }
        # set index [lsearch -regexp -index 0 $QWIKMD::line (?i)QMCustomPCFile$]
        # if {$index != -1} {
        #     QWIKMD::replaceNAMDLine "QMCustomPCFile" "QMCustomPCFile ${filename}_CustomPC-input.pdb"
        # } else {
        #     puts $namdfile "QMCustomPCFile ${filename}_CustomPC-input.pdb"
        # }

        set firstindex [lsearch -regexp -index 0 $QWIKMD::line (?i)QMCustomPCFile$]
        set listaux [list]
        if {$firstindex != -1} {
            set listaux [lrange $QWIKMD::line 0 [expr $firstindex -1]]
        }
        for {set qmID 1} {$qmID <= [$QWIKMD::advGui(qmtable) size]} {incr qmID} {
            if {$QWIKMD::advGui(qmtable,$qmID,pcDist) > 0} {
                set str "QMCustomPCFile ${filename}_CustomPC-input-QM${qmID}.pdb"
                if {$firstindex != -1} {
                    lappend listaux ${str}
                } else {
                    puts $namdfile ${str}
                }
            }
        }
        if {[llength $listaux] > 0 } {
            incr firstindex
            while {[lsearch -regexp -start $firstindex -index 0 $QWIKMD::line (?i)QMCustomPCFile$] != -1} {
                incr firstindex
            }
            set QWIKMD::line [concat $listaux [lrange $QWIKMD::line $firstindex end]]
            unset listaux
        }
    }

    #### Check when multiple lines exist with the same keyword 
    set lssmodeonoff off
    if {$QWIKMD::advGui(qmoptions,lssmode,$prtclname) != "Off"} {
        set lssmodeonoff on
        set lssmode dist
        if {$QWIKMD::advGui(qmoptions,lssmode,$prtclname) == "Center of Mass" && [info exist QWIKMD::advGui(qmtable,1,qmCOMSel)] == 1} {
            set lssmode COM
            set strlist ""
            for {set qmID 1} {$qmID <= [$QWIKMD::advGui(qmtable) size]} {incr qmID} {
                if {$QWIKMD::advGui(qmtable,$qmID,qmCOMSel) != "none"} {
                    set sel [atomselect top $QWIKMD::advGui(qmtable,$qmID,qmCOMSel)] 
                    set straux ""
                    set ind 0
                    foreach segname [$sel get segname] residue [$sel get resid] {
                        if {$straux != "$qmID $segname $residue"} {
                           
                            lappend strlist "\"$qmID $segname $residue\"\n"
                            set straux "$qmID $segname $residue"
                            incr ind
                        } 
                    }
                    $sel delete
                }
            }
            set firstindex [lsearch -regexp -index 0 $QWIKMD::line (?i)QMLSSRef$]
            set listaux [list]
            if {$firstindex != -1} {
                set listaux [lrange $QWIKMD::line 0 [expr $firstindex -1]]
            }
            foreach str $strlist {
                set newstr "QMLSSRef ${str}"
                if {$firstindex != -1} {
                    lappend listaux ${newstr}
                } else {
                    puts $namdfile ${newstr}
                }
            }
            if {[llength $listaux] > 0 } {
                incr firstindex
                while {[lsearch -regexp -start $firstindex -index 0 $QWIKMD::line (?i)QMLSSRef$] != -1} {
                    incr firstindex
                }
                set QWIKMD::line [concat $listaux [lrange $QWIKMD::line $firstindex end]]
                unset listaux
            }

        }

        set index [lsearch -regexp -index 0 $QWIKMD::line (?i)QMLSSMode$]
        if {$index != -1} {
            QWIKMD::replaceNAMDLine "QMLSSMode" "QMLSSMode $lssmode"
        } else {
            puts $namdfile "QMLSSMode $lssmode"
        }
    }

    set index [lsearch -regexp -index 0 $QWIKMD::line (?i)QMLiveSolventSel$]
    if {$index != -1} {
        QWIKMD::replaceNAMDLine "QMLiveSolventSel" "QMLiveSolventSel $lssmodeonoff"
    } else {
        puts $namdfile "QMLiveSolventSel $lssmodeonoff"
    }

    if {[info exists QWIKMD::advGui(qmtable,1,multi)] == 1} {
        set firstindex [lsearch -regexp -index 0 $QWIKMD::line (?i)qmMult$]
        set listaux [list]
        if {$firstindex != -1} {
            set listaux [lrange $QWIKMD::line 0 [expr $firstindex -1]]
        }
        for {set qmID 1} {$qmID <= [$QWIKMD::advGui(qmtable) size]} {incr qmID} {
            set str "qmMult $qmID $QWIKMD::advGui(qmtable,$qmID,multi)"
            if {$firstindex != -1} {
                lappend listaux ${str}
            } else {
                puts $namdfile ${str}
            }
        }
        if {[llength $listaux] > 0 } {
            incr firstindex
            while {[lsearch -regexp -start $firstindex -index 0 $QWIKMD::line (?i)qmMult$] != -1} {
                incr firstindex
            }
            set QWIKMD::line [concat $listaux [lrange $QWIKMD::line $firstindex end]]
            unset listaux
        }
    }
    if {[info exists QWIKMD::advGui(qmtable,1,charge)] == 1} {
        set firstindex [lsearch -regexp -index 0 $QWIKMD::line (?i)qmCharge$]
        set listaux [list]
        if {$firstindex != -1} {
            set listaux [lrange $QWIKMD::line 0 [expr $firstindex -1]]
        }
        for {set qmID 1} {$qmID <= [$QWIKMD::advGui(qmtable) size]} {incr qmID} {
            set str "qmCharge $qmID $QWIKMD::advGui(qmtable,$qmID,charge)"
            if {$firstindex != -1} {
                lappend listaux ${str}
            } else {
                puts $namdfile ${str}
            }
        }
        
        if {[llength $listaux] > 0 } {
            incr firstindex
            while {[lsearch -regexp -start $firstindex -index 0 $QWIKMD::line (?i)qmCharge$] != -1} {
                incr firstindex
            }
            set QWIKMD::line [concat $listaux [lrange $QWIKMD::line $firstindex end]]
            unset listaux
        }
    }
    set index [lsearch -regexp -index 0 $QWIKMD::line (?i)qmSoftware$]
    if {$index != -1} {
        QWIKMD::replaceNAMDLine "qmSoftware" "qmSoftware $QWIKMD::advGui(qmoptions,soft,$prtclname)"
    } else {
        puts $namdfile "qmSoftware $QWIKMD::advGui(qmoptions,soft,$prtclname)"
    }
    if {$QWIKMD::advGui(protocoltb,$QWIKMD::run,$step,lock) == 0} {
        if {[info exists env(QWIKMD$QWIKMD::advGui(qmoptions,soft,$prtclname))]} {
            set index [lsearch -regexp -index 0 $QWIKMD::line (?i)qmExecPath$]
            if {$index != -1} {
                QWIKMD::replaceNAMDLine "qmExecPath" "qmExecPath \"$env(QWIKMD$QWIKMD::advGui(qmoptions,soft,$prtclname))\""
            } else {
                puts $namdfile "qmExecPath \"$env(QWIKMD$QWIKMD::advGui(qmoptions,soft,$prtclname))\""
            }
        }
        if {$QWIKMD::prepared == 1} {
            if {[file exists ${QWIKMD::outPath}/run/qmmm_exec/[lindex $QWIKMD::confFile $step]]!= 1} {
                file mkdir ${QWIKMD::outPath}/run/qmmm_exec/[lindex $QWIKMD::confFile $step]
            }
            set index [lsearch -regexp -index 0 $QWIKMD::line (?i)qmBaseDir$]
            if {$index != -1} {
                QWIKMD::replaceNAMDLine "qmBaseDir" "qmBaseDir \"\[pwd\]/qmmm_exec/[lindex $QWIKMD::confFile $step]\""
            } else {
                puts $namdfile "qmBaseDir \"\[pwd\]/qmmm_exec/[lindex $QWIKMD::confFile $step]\""
            } 
        }
    }
    ### print the bash script to merge the outputs of the orbitals 
    ### created by the QM packages. This script checks which
    ### QM region is being calculated from the file name *.<qm region>.*
    ### and the step, so it merges every X steps
    if {$QWIKMD::advGui(qmoptions,execseqproc,$prtclname) == 1} {
        set file "${QWIKMD::outPath}/run/mergefile.sh"
        if {[file exists ${file}] == 0} {
            set secprocfile [open ${file} w+]
            puts $secprocfile "### File to merge the outputs of QM packages."
            puts $secprocfile "### Generated by QwikMD version [package versions qwikmd].\n"
            puts $secprocfile "#!/bin/bash\n"
            puts $secprocfile "i=\"\$IFS\";IFS=\'/\';set -f;p=(\$4);set +f;IFS=\"\$i\""
            puts $secprocfile "QMREGION=\$\{p\[-2\]\}"
            puts $secprocfile "if \[ ! -f \$\{1\}.\$\{QMREGION\}.out \] && \(\(\$\{5\} != \"0\"\)\) ; then"
            puts $secprocfile "\techo \"\" > \$\{1\}.\$\{QMREGION\}.out"
            puts $secprocfile "elif \[ ! -f \$\{3\}.\$\{QMREGION\}.out \] && \(\(\$\{5\} == \"0\"\)\) && \[ \"\$\{3\}\" != \"-1\" \] ; then"
            puts $secprocfile "\tcat \$\{4\}.TmpOut > \$\{3\}.\$\{QMREGION\}.out"
            puts $secprocfile "fi"
            puts $secprocfile "if ((\${5} % \$\{2\} == 0 && \$\{5\} != \"0\")); then"
            puts $secprocfile "\tcat \$\{4\}.TmpOut >> \$\{1\}.\$\{QMREGION\}.out"
            puts $secprocfile "fi"
            close $secprocfile
            file attributes "${QWIKMD::outPath}/run/mergefile.sh" -permissions rwxrwxrwx
        }
        

        set index [lsearch -regexp -index 0 $QWIKMD::line (?i)qmSecProc$]
        ### send the initial structure file name in the case of step 0
        ### to create qmout.out file dedicated to the initial structure to easy the loading.
        ### In this way we can load the orca or mopac files without the step 0, which namd
        ### does not store in dcd. If step > 0 sent "0" as the third argument
        set initstrcfile -1
        if {$step == 0} {
            set initstrcfile "${filename}_qmout"
        }
        if {$index != -1} {
            QWIKMD::replaceNAMDLine "qmSecProc" "qmSecProc \"\[pwd\]/mergefile.sh \
            [lindex $QWIKMD::confFile $step]_qmout $QWIKMD::advGui(qmoptions,dcdfrq,$prtclname) $initstrcfile\""
        } else {
            puts $namdfile "qmSecProc \"\[pwd\]/mergefile.sh \
            [lindex $QWIKMD::confFile $step]_qmout $QWIKMD::advGui(qmoptions,dcdfrq,$prtclname) $initstrcfile\""
        }
    }

    # set nlines [expr [lindex [split [$QWIKMD::advGui(qmoptions,ptcqmwdgt) index end] "."] 0] -1]
    # set cmdlist [split [$QWIKMD::advGui(qmoptions,ptcqmwdgt) get 1.0 $nlines.end] \n]
    # set QWIKMD::advGui(qmoptions,ptcqmval,$prtclname) $cmdlist
    # set cmdline ""
    set strtindex 0
    set firstindex [lsearch -regexp -index 0 $QWIKMD::line (?i)qmConfigLine$]
    set listaux [list]
    set QWIKMD::mdProtInfo(qmmm,cmdline,$prtclname) ""
    if {$firstindex != -1} {
        set listaux [lrange $QWIKMD::line 0 [expr $firstindex -1]]
    }
    foreach cmd $QWIKMD::advGui(qmoptions,ptcqmval,$prtclname) {
        set str "qmConfigLine \"${cmd}\""
        append QWIKMD::mdProtInfo(qmmm,cmdline,$prtclname) "\"${cmd}\""
        if {$firstindex != -1} {
            lappend listaux ${str}
        } else {
            puts $namdfile ${str}
        }

    }
    if {[llength $listaux] > 0 } {
        incr firstindex
        while {[lsearch -regexp -start $firstindex -index 0 $QWIKMD::line (?i)qmConfigLine$] != -1} {
            incr firstindex
        }
        set QWIKMD::line [concat $listaux [lrange $QWIKMD::line $firstindex end]]
        unset listaux
    }
}
proc QWIKMD::selectProcs {} {
    

    set procWindow ".proc"
    set QWIKMD::numProcs [QWIKMD::procs] 

    if {[winfo exists $procWindow] != 1} {
        toplevel $procWindow
        wm protocol ".proc" WM_DELETE_WINDOW {
            
            set QWIKMD::numProcs "Cancel"
            destroy ".proc"

        }

        grid columnconfigure $procWindow 0 -weight 1
        grid rowconfigure $procWindow 1 -weight 1

        ## Title of the windows
        wm title $procWindow  "How many processors?" ;# titulo da pagina
        set x [expr round([winfo screenwidth .]/2.0)]
        set y [expr round([winfo screenheight .]/2.0)]
        #wm geometry $procWindow "260x60-$x-$y"
        grid [ttk::frame $procWindow.f0] -row 0 -column 0 -sticky ew -padx 4 -pady 4
        grid columnconfigure $procWindow.f0 0 -weight 1
        grid [ttk::label $procWindow.f0.lb -text "QwikMD detected $QWIKMD::numProcs processors.\nHow many do you want to use?"] -row 0 -column 0 -sticky w -padx 2
        
        set values [list]
        for {set i $QWIKMD::numProcs} {$i >= 1} {incr i -1} {
            lappend values $i
        }
        
        grid [ttk::combobox $procWindow.f0.combProcs -values $values -width 4 -state normal -justify center -textvariable QWIKMD::numProcs] -row 0 -column 1 -pady 0 -padx 4
        $procWindow.f0.combProcs set $QWIKMD::numProcs
        

        grid [ttk::frame $procWindow.f1] -row 1 -column 0 -sticky ew

        grid [ttk::button $procWindow.f1.okBut -text "Ok" -padding "2 0 2 0" -width 15 -command {
            #set QWIKMD::numProcs [.proc.f0.combProcs get] 
            destroy ".proc"
            } ] -row 0 -column 0 -sticky ns

        grid [ttk::button $procWindow.f1.cancel -text "Cancel" -padding "2 0 2 0" -width 15 -command {
            set QWIKMD::numProcs "Cancel"
             destroy ".proc"
            } ] -row 0 -column 1 -sticky ns
        wm minsize $procWindow -1 -1
    } else {
        wm deiconify $procWindow
    }
    tkwait window $procWindow

} 


proc QWIKMD::Run {} {

    QWIKMD::selectNotebooks 1
    QWIKMD::selectProcs
    update idletasks
    if {$QWIKMD::numProcs == "Cancel"} {
        return
    }
    cd $QWIKMD::outPath/run

    if {[$QWIKMD::topGui.nbinput index current] == 0 && $QWIKMD::state == [llength $QWIKMD::prevconfFile]} {
        set file ""
        if {$QWIKMD::run == "SMD"} {
            set file "qwikmd_production_smd_$QWIKMD::state"
            
        } else {
            set file "qwikmd_production_$QWIKMD::state"
        }
        if {[file exists ${file}.conf] != 1} {
            lappend QWIKMD::confFile $file
            lappend QWIKMD::prevconfFile $file
        }
    }
    set tabid [$QWIKMD::topGui.nbinput index current]
    
    # if {[$QWIKMD::topGui.nbinput index current] == 1 && $QWIKMD::run == "QM/MM" && [file exists ${prefix}_qm-input.pdb] != 1} {
    #     if {$QWIKMD::advGui(protocoltb,$QWIKMD::run,$QWIKMD::state,qmmm) == 1} {
    #         cd $QWIKMD::outPath/run
    #         if {$QWIKMD::state > 0} {
    #             mol addfile [lindex $QWIKMD::prevconfFile [expr $QWIKMD::state -1]].restart.coor molid $QWIKMD::topMol waitfor all
    #         }
    #         cd $QWIKMD::outPath/setup
    #         if {[file exists ${prefix}_qm-input.pdb] == 1} {
    #             file delete -force -- ${prefix}_qm-input.pdb
    #         }
    #         QWIKMD::PrepareQMMM $prefix
    #         animate delete beg last end last skip 1 $QWIKMD::topMol
    #         cd $QWIKMD::outPath/run
    #         update
    #     }
    # }

    if {[file exists [lindex $QWIKMD::prevconfFile $QWIKMD::state].conf ] != 1} {
        
        if {[$QWIKMD::topGui.nbinput index current] == 1} {
            if {$QWIKMD::state == [$QWIKMD::advGui(protocoltb,$QWIKMD::run) size]} {
                tk_messageBox -message "Please add protocol before press Start." -title "No Protocol" -icon warning -type ok -parent $QWIKMD::topGui
                return
            }
            lappend QWIKMD::prevconfFile [lindex $QWIKMD::confFile end]
            #lappend QWIKMD::confFile [lindex $QWIKMD::confFile end]
        }
        
        if {$QWIKMD::basicGui(live,$tabid) == 1} {
            set QWIKMD::dcdfreq 1000
            set QWIKMD::load 0
        } else {
            set QWIKMD::dcdfreq 10000
        }
        set QWIKMD::confFile $QWIKMD::prevconfFile
        QWIKMD::NAMDGenerator [lindex [molinfo $QWIKMD::topMol get filename] 0] $QWIKMD::state
        QWIKMD::SaveInputFile $QWIKMD::basicGui(workdir,0)
        QWIKMD::defaultIMDbtt $tabid normal
        #[lindex $QWIKMD::runbtt $tabid] configure -text "Start [QWIKMD::RunText]"
    }
    set QWIKMD::confFile $QWIKMD::prevconfFile
    set prefix [file root [file tail $QWIKMD::basicGui(workdir,0)]] 
    if {$QWIKMD::state > 0} {
        set prevcheck [lindex $QWIKMD::prevconfFile [expr $QWIKMD::state -1] ]
        set ret 0
        if {[file exists $prevcheck.check]} {
            set fil [open  $prevcheck.check r]
            set line [read -nonewline $fil]
            close $fil
            if {$line != "DONE"} {
                set ret 1
            }
        }  else {
            set ret 1
        }
        if {$ret == 1} {
            tk_messageBox -message "Previous simulation is still running or terminated with error" -title "Running Simulation" -icon info \
            -type ok -parent $QWIKMD::topGui
            file delete -force -- [lindex $QWIKMD::prevconfFile [expr $QWIKMD::state -1]].check
            incr QWIKMD::state -1
            QWIKMD::defaultIMDbtt $tabid normal
            # [lindex $QWIKMD::runbtt $tabid] configure -text "Start [QWIKMD::RunText]"
            # [lindex $QWIKMD::runbtt $tabid] configure -state normal
            return
        }
    }


    set conf [lindex $QWIKMD::prevconfFile $QWIKMD::state]
    ################################################################################
    ## New version of namd2 (NAMD_CVS-2015-10-28_Linux-x86_64-multicore-CUDA) does not 
    ## return an error and crash if there is not enough patches per GPU (so we can use)
    ## the same command for both CUDA and
    ################################################################################
    set exec_command "namd2 +idlepoll +setcpuaffinity +p${QWIKMD::numProcs} $conf.conf"
    set do 0
    set i 0
    if {$tabid == 0 && $QWIKMD::basicGui(prtcl,$QWIKMD::run,smd) == 1} {
        if {[string match "*_production_smd_*" [lindex $QWIKMD::prevconfFile $QWIKMD::state ] ] > 0 && $QWIKMD::state > 0} {
            set do 1
        }
            
        while {$i < [llength  $QWIKMD::prevconfFile]} {
            if {[string match "*_production_smd*" [lindex $QWIKMD::prevconfFile $i] ] > 0} {
                break
            }
            incr i
        }

    } else {
        if {$QWIKMD::advGui(protocoltb,$QWIKMD::run,$QWIKMD::state,smd) == 1 && $QWIKMD::state > 0} {
            set do 1
        }
        while {$i < [llength $QWIKMD::prevconfFile]} {
            if {$QWIKMD::advGui(protocoltb,$QWIKMD::run,$i,smd) == 1} {
                break
            }
            incr i
        }
    }
    if {$i != $QWIKMD::state} {
        set do 0
    }
    set smdfile [lindex $QWIKMD::inputstrct 0]
    if {$QWIKMD::run == "SMD" && $QWIKMD::state > 0} {
        set smdfile [lindex $QWIKMD::inputstrct 0]
        if {$QWIKMD::state > 0} {
            if {$tabid == 0} {
                set index [lindex [lsearch -all $QWIKMD::prevconfFile "*_production_smd*"] 0]
                set smdfile [lindex $QWIKMD::prevconfFile [expr $index -1 ]].coor
            } else {
                set i 0
                while {$i < [llength  $QWIKMD::prevconfFile]} {
                    if {$QWIKMD::advGui(protocoltb,$QWIKMD::run,$i,smd) == 1} {
                        break
                    }
                    incr i
                }
                set smdfile [lindex $QWIKMD::prevconfFile [expr $i -1 ]].coor 
            }
        }
    }
    if {$QWIKMD::run == "SMD" && [file exists $smdfile] != 1 && $do ==1} {
        
        QWIKMD::save_viewpoint 1
        set stfile [lindex [molinfo $QWIKMD::topMol get filename] 0]
        set name [lindex $stfile 0]
        set mol [mol new $name]
        mol addfile [lindex $QWIKMD::prevconfFile [expr $QWIKMD::state -1]].restart.coor
        set all [atomselect top "all"]
        set beta [atomselect top $QWIKMD::anchorRessel]
        set occupancy [atomselect top $QWIKMD::pullingRessel]
        $all set beta 0
        $all set occupancy 0
        $beta set beta 1
        $occupancy set occupancy 1
        $all writepdb $smdfile
        mol delete $mol
        $all delete
        $beta delete
        $occupancy delete
        mol delete $mol 
        QWIKMD::restore_viewpoint 1
        display update ui
        update
    }
    if {$QWIKMD::run == "SMD" && [string match "*_production_smd_*" [lindex $QWIKMD::prevconfFile $QWIKMD::state ] ] > 0} {
        QWIKMD::checkAnchors
        if {[lindex $QWIKMD::timeXsmd end] != ""} {
            set QWIKMD::smdprevx [lindex $QWIKMD::timeXsmd end]
            set QWIKMD::smdprevindex 0 
        }
    }

    # if {[llength $QWIKMD::volpos] == 0} {
    #   set QWIKMD::volpos 0
    # }
    # if {[llength $QWIKMD::presspos] == 0} {
    #   set QWIKMD::presspos 0
    # }

    if {[lindex $QWIKMD::volpos end] > [lindex $QWIKMD::presspos end] && [llength $QWIKMD::volpos] != 0} {
        set QWIKMD::condprevx [lindex $QWIKMD::volpos end]
    } elseif {[llength $QWIKMD::presspos] != 0} {
        set QWIKMD::condprevx [lindex $QWIKMD::presspos end]
    }
    
    set QWIKMD::condprevindex 0 

    set tabid [$QWIKMD::topGui.nbinput index current]

    if {$QWIKMD::basicGui(live,$tabid) == 1} {

        set QWIKMD::load 0
        set IMDPort 3000

        set QWIKMD::smdcurrentpos 0
        [lindex $QWIKMD::runbtt $tabid] configure -state disabled

        #Block other tabs and protocol when running
        
        if {$tabid == 0} {
            $QWIKMD::topGui.nbinput tab 1 -state disabled
        } else {
            $QWIKMD::topGui.nbinput tab 0 -state disabled
        }
        set prtcnotebook [lindex $QWIKMD::selnotbooks 1]
        for {set i 0} {$i < [llength [[lindex $prtcnotebook 0] tabs]]} {incr i} {
            if {$i != [lindex $prtcnotebook 1]} {
                [lindex $prtcnotebook 0] tab $i -state disabled
            }
        }
        [lindex $QWIKMD::preparebtt $tabid] configure -state normal
        [lindex $QWIKMD::savebtt $tabid] configure -state disabled
        set  QWIKMD::basicGui(mdPrec,0) 0
        $QWIKMD::basicGui(mdPrec,[expr $tabid +1]) configure -maximum [lindex $QWIKMD::maxSteps $QWIKMD::state]

        eval ::ExecTool::exec "${exec_command} >> $conf.log & "
        
        QWIKMD::connect localhost $IMDPort

        set logfile [open [lindex $QWIKMD::prevconfFile $QWIKMD::state].log r]
        while {[eof $logfile] != 1 } {
            set line [gets $logfile]

            if {[lindex $line 0] == "Info:" && [lindex $line 1] == "TIMESTEP"} {
                set QWIKMD::timestep [lindex $line 2]
            }

            if {[lindex $line 0] == "Info:" && [join [lrange $line 1 3]] == "INTERACTIVE MD FREQ" } {
                set QWIKMD::imdFreq [lindex $line 4]
                break
            }
        }
        close $logfile

        incr QWIKMD::state
        
        set QWIKMD::load 0
    } else {
        set QWIKMD::smdcurrentpos 0
        set answer [tk_messageBox -message "MD simulation will run in the background blocking the VMD windows of the current session until\
         the simulation is finished.\nDo you want to proceed?" -title "Run Simulation" -icon question -type yesno -parent $QWIKMD::topGui]
        if {$answer == "yes"} {
            [lindex $QWIKMD::runbtt $tabid] configure -state disabled
            [lindex $QWIKMD::preparebtt $tabid] configure -state disabled
            [lindex $QWIKMD::savebtt $tabid] configure -state disabled
            eval ::ExecTool::exec $exec_command  >> $conf.log
            incr QWIKMD::state 
            set QWIKMD::load 0
            QWIKMD::updateMD
            
        }
        
    }
}

proc QWIKMD::connect {IMDHost IMDPort} {

    set attempt_delay 5000   ;# delay between attepmts to connect in ms
    set attempt_timeout 100000 ;# timeout in ms
    set solvent ""
    set tabid [$QWIKMD::topGui.nbinput index current] 
    if {$tabid== 0} {
        set solvent $QWIKMD::basicGui(solvent,$QWIKMD::run,0)
    } else {
        set solvent $QWIKMD::advGui(solvent,$QWIKMD::run,0)
    }
    if {$solvent == "Explicit"} {
        set attempt_delay 10000   ;# delay between attepmts to connect in ms
        set attempt_timeout 200000 ;# timeout in ms
        pbc box -off
    }
    mol top $QWIKMD::topMol
    update idletasks
    set timecounter 0
    after $attempt_delay
    while {$timecounter <= $attempt_timeout} { 
        if ![catch { imd connect $IMDHost $IMDPort }] {
            
            imd keep 0

            trace variable ::vmd_timestep($QWIKMD::topMol) w ::QWIKMD::updateMD 
            #imd keep 0
            break
        } else {
            # else give NAMD more time
            after $attempt_delay
        }
        incr timecounter $attempt_delay
    }
    if {$timecounter > $attempt_timeout} {
        tk_messageBox -message "The simulation failed to start.\nPlease check VMD terminal window or the *.log files in the\
         \"run\" output folder for errors." -icon error -type ok -parent $QWIKMD::topGui
    }
}

################################################################################
## Main proc that defines mutations, changes on protonation state, renaming and change
## residues type. If in the QWIKMD::rowSelection call UpdateRes with opt ==1 (meaning
## do the changes), global variables like QWIKMD::protonate, QWIKMD::protindex
## stores the indexes (ResID_Chain)
## QWIKMD::protres stores the different states of the Resname cells in Select Residue table
##  QWIKMD::rename stores the residues indexes that need to be rename
##  QWIKMD::renameindex stores the indexes (ResID_Chain) that will be rename during the PrepareStructures
##  QWIKMD::dorename([lindex $QWIKMD::renameindex $i]) stores the new resname for that index (ResID_Chain)
## mutations, protonation changes and type changes follows the same logit described
################################################################################

proc QWIKMD::CallUpdateRes {tbl row col text} {
    set domaintable [QWIKMD::UpdateRes $tbl $row $col $text]
    if {$domaintable != 0} {
        if {$QWIKMD::tablemode == "type"} {
            #$tbl cancelediting
            $tbl rejectinput
            QWIKMD::UpdateMolTypes [expr [$QWIKMD::topGui.nbinput index current] + 1 ]
            
        }
        if {$QWIKMD::tablemode == "rename"} {
            
            set resid [$tbl cellcget $row,0 -text]
            set chain [$tbl cellcget $row,2 -text]
            set toposearch ""
            if {[info exists QWIKMD::dorename(${resid}_$chain)] == 1 } {
                set toposearch [QWIKMD::checkAtomNames $QWIKMD::dorename(${resid}_$chain)]
            } else {
                set toposearch [QWIKMD::checkAtomNames $domaintable]
                $tbl cellconfigure $row,$col -text $domaintable 
            }
            
            if {[lindex $toposearch 0] != -1} {
                set sel [atomselect $QWIKMD::topMol "resid \"$resid\" and chain \"$chain\" and noh"]
                set atomnames [$sel get name]
                foreach name $atomnames {
                    if {[lsearch -index 0 [lindex $toposearch 1] $name] == -1 && [llength $atomnames] > 1} {
                        set answer [tk_messageBox -message "Atoms' name from residue $resid in the original structure don't match the\
                         CHARMM topologies. Please rename the atom's names." -title "Atom's Name" -icon info -type yesno -parent $QWIKMD::selResGui]
                        if {$answer == "yes"} {
                            set QWIKMD::tablemode "edit"
                            QWIKMD::tableModeProc
                            $QWIKMD::selresTable selection set $row
                            set QWIKMD::advGui(qmoptions,qmgentopo) 0
                            QWIKMD::editAtomGuiProc
                            QWIKMD::updateEditAtomWindow
                            QWIKMD::editAtom
                            raise $QWIKMD::editATMSGui
                            return $domaintable 
                        } else {
                            return $domaintable 
                        }
                    }
                }
                $sel delete
            } else {
                tk_messageBox -message "No topologies found for the residue $text. Please add the topologies for this residue or rename it to the correct name."\
                -title "No topologies" -icon info -type okcancel -parent $QWIKMD::selResGui
                return $domaintable 
            }
        }
    } else {
        set domaintable [$tbl cellcget $row,$col -text] 
    }
    return $domaintable   

}
################################################################################
## update the molecule types on the Structure and Manipulation table
################################################################################
proc QWIKMD::UpdateMolTypes {tabid} {
    QWIKMD::mainTable $tabid
    QWIKMD::SelResid
    if {[llength $QWIKMD::delete] > 0} {
        set chaincol [$QWIKMD::selresTable getcolumns 2]
        set rescol [$QWIKMD::selresTable getcolumns 0]
        set tbindex [list]
        foreach delres $QWIKMD::delete {
            set residchain [split $delres "_"]
            set resindex [lsearch -all $rescol [lindex $residchain 0] ]
            foreach resind $resindex {
                if {[lindex $chaincol $resind] == [lindex $residchain end]} {
                    lappend tbindex $resind
                }
            }
        }
        set QWIKMD::delete [list]
        set auxmode $QWIKMD::tablemode
        set QWIKMD::tablemode "delete"
        $QWIKMD::selresTable selection set $tbindex
        QWIKMD::Apply
        set QWIKMD::tablemode $auxmode
    }
}

proc QWIKMD::UpdateRes {tbl row col text} {
    set resname $QWIKMD::prevRes
    set domutate 0
    set recolor 0
    set totindex ""
    set delrep 0

    set resid [$tbl cellcget $row,0 -text]
    set chain [$tbl cellcget $row,2 -text]
    set type [$tbl cellcget $row,3 -text]

    set sel [atomselect top "resid \"$resid\" and chain \"$chain\""]
    set initresid [lindex [$sel get resname] 0]
    set returntext ""

    set ind ${resid}_$chain
    
    if {$QWIKMD::tablemode == "prot"} {
        if {$text != $initresid && $QWIKMD::protres(0,3) != "" && $initresid != "HIS" && $initresid != "HSD" && $initresid != "HSE" && $initresid != "HSP"} {
            
            set returntext "$initresid -> $QWIKMD::protres(0,3) -> $text"
            set recolor 1
            set domutate 1
        } elseif {($text != $initresid && $QWIKMD::protres(0,3) == "" ) || $initresid == "HIS" || $initresid == "HSD" || $initresid == "HSE" || $initresid == "HSP"} {
            set returntext "$initresid -> $text"
            set recolor 1
            set domutate 1
        } elseif {$text == $initresid} {
            set returntext $text

            set index [lsearch -exact $QWIKMD::protindex $ind]
            if {$index != -1} {
                set QWIKMD::protindex [lreplace $QWIKMD::protindex $index $index]
                set domutate 0
            }
        }
    } elseif {$QWIKMD::tablemode == "mutate"} {
        if {$text != $initresid} {
            set returntext "$initresid -> $text"
            set recolor 1
            set domutate 1
        } else {
            set returntext $text
            set index [lsearch -exact $QWIKMD::mutindex $ind]
            #set domutate 1
            if {$index != -1} {
                set QWIKMD::mutindex [lreplace $QWIKMD::mutindex $index $index]
                set domutate 0
                set recolor 0
            }
        }
    } elseif {$QWIKMD::tablemode == "rename" || $QWIKMD::tablemode == "type"} {

        set returntext $text
        if {$text == $initresid} {

            set index [lsearch -exact $QWIKMD::renameindex $ind]
            if {$index != -1} {
                set QWIKMD::renameindex [lreplace $QWIKMD::renameindex $index $index]
                set domutate 0
                set recolor 0
            }
        } else {
            if {$QWIKMD::tablemode == "type" && $text == "protein"} {
                set answer [tk_messageBox -message "Are you sure that [$tbl cellcget $row,1 -text] is a protein residue?"\
                 -title "Residues Type" -icon info -type yesno -parent $QWIKMD::selResGui]
                if {$answer == "no"} {
                    $tbl cancelediting
                } 
            }
            set colresname [list] 
            set colresname [concat $colresname [$tbl getcolumns 1] ]

            set resname $QWIKMD::protres(0,2)
            if {$QWIKMD::tablemode == "type"} {
                set resname [$tbl cellcget $row,1 -text]
                set totindex [lsearch -all -exact $colresname $resname]
            } else {
                set totindex [concat $totindex [lsearch -all -exact $colresname $resname]]
            }
            if {[llength $totindex] == 0} {
                set resname [$tbl cellcget $row,1 -text]
                if {$QWIKMD::tablemode == "type"} {
                    set totindex [lsearch -all -exact $colresname $resname]
                } else {
                    set totindex [concat $totindex [lsearch -all -exact $colresname $resname]]
                }

                if {[llength $totindex] == 0} {
                    set totindex $row
                }
            }
            set domutate 1
            set QWIKMD::resallnametype 1
            if {[llength $totindex] > 1} {
                if {$QWIKMD::tablemode == "type"} {
                    set msgtext "The type of one or more residues can be changed based on the chosen residue type.\nDo you want to change all?"
                    set title "Change Residues Type"
                } else {
                    set msgtext "One or more residues can be rename based on the chosen residue name.\nDo you want to rename all?"
                    set title "Rename Residues"
                }
                set answer [tk_messageBox -message $msgtext -title $title -icon question -type yesnocancel -parent $QWIKMD::selResGui]
                
                if {$answer == "no"} {
                    set QWIKMD::resallnametype 0
                    set totindex $row
                } elseif {$answer == "cancel"} {
                    set domutate 0
                    return 0
                } 
            }
        }
    } 
    $sel delete
    $QWIKMD::selresTable selection clear 0 end
    QWIKMD::rowSelection

    set rowcolor [$tbl rowcget $row -background]
    
    if {$recolor == 1} {
        $QWIKMD::selresTable cellconfigure $row,1 -background #ffe1bb
    } else {
        $QWIKMD::selresTable cellconfigure $row,1 -background white
    }
    
    $tbl configure -labelcommand tablelist::sortByColumn

    
    set sel [atomselect $QWIKMD::topMol "resid \"$resid\" and chain \"$chain\""]
    set structure [$sel get structure]
    set hexcols [QWIKMD::chooseColor [lindex $structure 0] ]
            
    set hexred [lindex $hexcols 0]
    set hexgreen [lindex $hexcols 1]
    set hexblue [lindex $hexcols 2]

    if {$type == "protein" && $domutate ==1} {
        $tbl rowconfigure $row -background white -selectbackground cyan
        $QWIKMD::selresTable cellconfigure $row,3 -background "#${hexred}${hexgreen}${hexblue}" -selectbackground "#${hexred}${hexgreen}${hexblue}"
    
    } elseif {$type != "protein" && $domutate == 1} {
        $tbl rowconfigure $row -background $rowcolor -selectbackground cyan
        $tbl cellconfigure $row,3 -background white -selectbackground cyan
    }

    if {$QWIKMD::tablemode == "prot" && $type == "protein" && $domutate == 1} {
        if {[lsearch -exact $QWIKMD::protindex ${resid}_${chain}] == -1} {
            lappend QWIKMD::protindex ${resid}_${chain}
        }
        set QWIKMD::protonate(${resid}_${chain}) "$QWIKMD::protres(0,2) $text"
    } elseif {$QWIKMD::tablemode == "mutate" && $domutate == 1} {
    
        set index [lsearch -exact $QWIKMD::mutindex ${resid}_${chain}]
        if {$index == -1} {
            lappend QWIKMD::mutindex ${resid}_${chain}
            if {[llength $QWIKMD::mutindex] > 3} {
                tk_messageBox -message "You are mutating more than 3 residues and possibly inducing structural instability."\
                 -title "Mutations" -icon warning -type ok -parent $QWIKMD::selResGui
            }
        }
        set index [lsearch -exact $QWIKMD::protindex ${resid}_${chain}]

        if {$index != -1 } {
            
            set QWIKMD::protindex [lreplace $QWIKMD::protindex $index $index]
        }

        set QWIKMD::mutate(${resid}_${chain}) "$initresid $text"

    } elseif {$QWIKMD::tablemode == "rename" && $domutate == 1} {

        set colresname [$tbl getcolumns 1]
        for {set i 0} {$i < [llength $totindex]} {incr i} {
        
            $tbl cellconfigure [lindex $totindex $i],3 -background white -selectbackground cyan
            set toresname ""
            set txt "or \(resid \"[$tbl cellcget [lindex $totindex $i],0 -text]\" and chain \"[$tbl cellcget [lindex $totindex $i],2 -text]\"\)"

            if {$type == "hetero"} {
                set index [lsearch $QWIKMD::heteronames $text]
                set toresname [lindex $QWIKMD::hetero $index]
                QWIKMD::checkMacros hetero $txt ""
                append QWIKMD::heteromcr " $txt"
            } elseif {$type == "nucleic"} {
                set toresname $text
                QWIKMD::checkMacros nucleic $txt ""
                append QWIKMD::nucleicmcr " $txt"
            } elseif {$type == "lipid"} {
                set toresname $text
                QWIKMD::checkMacros lipid $txt ""
                append QWIKMD::lipidmcr " $txt"
            } elseif {$type == "glycan"} {
                set index [lsearch $QWIKMD::carbnames $text]
                set toresname [lindex $QWIKMD::carb $index]
                QWIKMD::checkMacros glycan $txt ""
                append QWIKMD::glycanmcr " $txt"
            } elseif {$type == "protein"} {
                set toresname $text
            } 
            if {[lsearch -index 0 $QWIKMD::userMacros $type] > -1 && $toresname == ""} {
                set macro [lindex $QWIKMD::userMacros [lsearch -index 0 $QWIKMD::userMacros $type]]
                set toresname [lindex [lindex $macro 1] [lsearch [lindex $macro 2] $text]]
            }

            atomselect macro qwikmd_protein $QWIKMD::proteinmcr
            atomselect macro qwikmd_nucleic $QWIKMD::nucleicmcr
            atomselect macro qwikmd_glycan $QWIKMD::glycanmcr
            atomselect macro qwikmd_lipid $QWIKMD::lipidmcr
            atomselect macro qwikmd_hetero $QWIKMD::heteromcr
            set str "[$tbl cellcget [lindex $totindex $i],0 -text]_[$tbl cellcget [lindex $totindex $i],2 -text]"
            set index [lsearch -exact $QWIKMD::rename $str]
            if { $index != -1} {
                set QWIKMD::rename [lreplace $QWIKMD::rename $index $index]
            }

            set index [lsearch -exact $QWIKMD::renameindex $str]
            if { $index == -1} {
                lappend QWIKMD::renameindex $str
            }
            set QWIKMD::dorename($str) $toresname
            $tbl cellconfigure [lindex $totindex $i],1 -text $text
            $tbl rowconfigure [lindex $totindex $i] -background white -selectbackground cyan
            
            if {$type == "protein"} {
                $tbl cellconfigure [lindex $totindex $i],3 -background "#${hexred}${hexgreen}${hexblue}" -selectbackground "#${hexred}${hexgreen}${hexblue}"
    
            }
        }
    } elseif {$QWIKMD::tablemode == "type" && $domutate == 1} {
        for {set i 0} {$i < [llength $totindex]} {incr i} {
            set resindex "[$tbl cellcget [lindex $totindex $i],0 -text]_[$tbl cellcget [lindex $totindex $i],2 -text]"
            set renameind [lsearch -exact $QWIKMD::renameindex $resindex]
            if {$renameind != -1} {
                set QWIKMD::renameindex [lreplace $QWIKMD::renameindex $renameind $renameind]
                array unset QWIKMD::dorename $resindex
            }
            set toresname ""
            set txt "and not \(resid \"[$tbl cellcget [lindex $totindex $i],0 -text]\" and chain \"[$tbl cellcget [lindex $totindex $i],2 -text]\"\)"
            set txt2 "or \(resid \"[$tbl cellcget [lindex $totindex $i],0 -text]\" and chain \"[$tbl cellcget [lindex $totindex $i],2 -text]\"\)"
            QWIKMD::editMacros $QWIKMD::protres(0,2) $txt $txt2 old
            QWIKMD::editMacros $text $txt $txt2 new
            set type ""
            update idletasks    
        }
    }

    $sel delete
    array unset QWIKMD::protres *
    
    set QWIKMD::selected 1
    if {$delrep == 1} {
        while {[molinfo $QWIKMD::topMol get numreps] !=  [expr $QWIKMD::repidin + $QWIKMD::aprep]} {
            mol delrep [expr [molinfo $QWIKMD::topMol get numreps] -1 ] $QWIKMD::topMol
        }
    }
    return $returntext
}

################################################################################
## Modify the macros by adding the resid the newmacro and removing from the oldmacro
## opt defines if this the operation to remove from the old or add to the new macro
################################################################################
proc QWIKMD::editMacros {macro removetxt addtxt opt} {
    QWIKMD::checkMacros $macro $removetxt $addtxt
    set seltext ""
    if {$opt == "old"} {
        set seltext $removetxt
    } else {
        set seltext $addtxt
    }
    switch -exact $macro {
        protein {
            append QWIKMD::proteinmcr " $seltext"
        }
        nucleic {
            append QWIKMD::nucleicmcr " $seltext"
        }
        glycan {
            append QWIKMD::glycanmcr " $seltext"
        }
        lipid {
            append QWIKMD::lipidmcr " $seltext"
        }
        hetero {
            append QWIKMD::heteromcr " $seltext"
        }
        default {
            atomselect macro $macro "[atomselect macro $macro] $seltext"
        }
    }
    if {$opt == "new"} {
        atomselect macro qwikmd_protein $QWIKMD::proteinmcr
        atomselect macro qwikmd_nucleic $QWIKMD::nucleicmcr
        atomselect macro qwikmd_glycan $QWIKMD::glycanmcr
        atomselect macro qwikmd_lipid $QWIKMD::lipidmcr
        atomselect macro qwikmd_hetero $QWIKMD::heteromcr
    }
    
}
################################################################################
## check for duplicated definitions on macros
################################################################################
proc QWIKMD::checkMacros {macro txt txt2} {

    proc replaceString {str1 str2} {
        return [string replace $str1 [string first $str2 $str1] [expr [string first $str2 $str1] + [string length $str2] ]] 
    }

    switch -exact $macro {
        protein {
            if {[string first $txt $QWIKMD::proteinmcr] > -1} {
                set QWIKMD::proteinmcr [[namespace current]::replaceString $QWIKMD::proteinmcr $txt]
            } 

            if {[string first $txt2 $QWIKMD::nucleicmcr] > -1} {
                set QWIKMD::proteinmcr [[namespace current]::replaceString $QWIKMD::proteinmcr $txt2]
            }
        }
        nucleic {
            if {[string first $txt $QWIKMD::nucleicmcr] > -1} {
                set QWIKMD::nucleicmcr [[namespace current]::replaceString $QWIKMD::nucleicmcr $txt]
            } 

            if {[string first $txt2 $QWIKMD::nucleicmcr] > -1} {
                set QWIKMD::nucleicmcr [[namespace current]::replaceString $QWIKMD::nucleicmcr $txt2]
            }
        }
        glycan {
            if {[string first $txt $QWIKMD::glycanmcr] > -1} {
                set QWIKMD::glycanmcr [[namespace current]::replaceString $QWIKMD::glycanmcr $txt]
            } 

            if {[string first $txt2 $QWIKMD::glycanmcr] > -1} {
                set QWIKMD::glycanmcr [[namespace current]::replaceString $QWIKMD::glycanmcr $txt2]
            }
        }
        lipid {
            if {[string first $txt $QWIKMD::lipidmcr] > -1} {
                set QWIKMD::lipidmcr [[namespace current]::replaceString $QWIKMD::lipidmcr $txt]
            } 

            if {[string first $txt2 $QWIKMD::lipidmcr] > -1} {
                set QWIKMD::lipidmcr [[namespace current]::replaceString $QWIKMD::lipidmcr $txt2]
            }
        }
        hetero {
            if {[string first $txt $QWIKMD::heteromcr] > -1} {
                set QWIKMD::heteromcr [[namespace current]::replaceString $QWIKMD::heteromcr $txt]
            } 

            if {[string first $txt2 $QWIKMD::heteromcr] > -1} {
                set QWIKMD::heteromcr [[namespace current]::replaceString $QWIKMD::heteromcr $txt2]
            }
        }
        default {
            set current [atomselect macro $macro]
            if {[string first $txt $current] > -1} {
                set current [[namespace current]::replaceString $current $txt]
            } 

            if {[string first $txt2 $current] > -1} {
                set current [[namespace current]::replaceString $current $txt2]
            }
            atomselect macro $macro $current

        }   
    }   
} 

################################################################################
## Syncr proc to match the chains selected in "Select chain/type" and the main table
################################################################################                
proc QWIKMD::reviewTable {tabid} {
    set table $QWIKMD::topGui.nbinput.f$tabid.tableframe.tb
    $table delete 0 end
    set length [expr [array size QWIKMD::chains] / 3 ]
    set index 0

    for {set i 0} {$i < $length} {incr i} {
        if {$QWIKMD::chains($i,0) == 0} {
            if {[info exists QWIKMD::index_cmb($QWIKMD::chains($i,1),4)] == 1} {
                mol showrep $QWIKMD::topMol [QWIKMD::getrepnum $QWIKMD::index_cmb($QWIKMD::chains($i,1),4) $QWIKMD::topMol] off
                set previndex [$table getcolumns 0]
                set indexfind [lsearch $previndex $QWIKMD::chains($i,1)]
                $table delete $indexfind
            }
        } elseif {$QWIKMD::chains($i,0) == 1 } {
            update 
            $table insert end [list [lindex $QWIKMD::chains($i,1) 0] $QWIKMD::chains($i,2) [lindex $QWIKMD::chains($i,1) 2] {} {} ]
            if {[info exists QWIKMD::index_cmb($QWIKMD::chains($i,1),4)] != 1} {
                mol addrep $QWIKMD::topMol
                set QWIKMD::index_cmb($QWIKMD::chains($i,1),4) [mol repname $QWIKMD::topMol [expr [molinfo $QWIKMD::topMol get numreps] -1] ]

                $QWIKMD::topGui.nbinput.f$tabid.tableframe.tb cellconfigure $index,3 -text [QWIKMD::mainTableCombosStart 0 $QWIKMD::topGui.nbinput.f$tabid.tableframe.tb $index 3 "aux"]
                $QWIKMD::topGui.nbinput.f$tabid.tableframe.tb cellconfigure $index,4 -text [QWIKMD::mainTableCombosStart 0 $QWIKMD::topGui.nbinput.f$tabid.tableframe.tb $index 4 "aux"]
            }
            set repindex [QWIKMD::getrepnum $QWIKMD::index_cmb($QWIKMD::chains($i,1),4) $QWIKMD::topMol]
            set cursel [lindex [molinfo $QWIKMD::topMol get \"[list selection $repindex]\"] 0]
            if {$cursel != $QWIKMD::index_cmb($QWIKMD::chains($i,1),5) } {
                mol modselect $repindex $QWIKMD::topMol  "$QWIKMD::index_cmb($QWIKMD::chains($i,1),5)" 
            }
            mol showrep $QWIKMD::topMol [QWIKMD::getrepnum $QWIKMD::index_cmb($QWIKMD::chains($i,1),4) $QWIKMD::topMol] on
            set QWIKMD::index_cmb($QWIKMD::chains($i,1),3) $index
            QWIKMD::mainTableCombosEnd $QWIKMD::topGui.nbinput.f$tabid.tableframe.tb $index 3 $QWIKMD::index_cmb($QWIKMD::chains($i,1),1)
            QWIKMD::mainTableCombosEnd $QWIKMD::topGui.nbinput.f$tabid.tableframe.tb $index 4 $QWIKMD::index_cmb($QWIKMD::chains($i,1),2)
            $table cellconfigure $index,3 -text $QWIKMD::index_cmb($QWIKMD::chains($i,1),1)
            $table cellconfigure $index,4 -text $QWIKMD::index_cmb($QWIKMD::chains($i,1),2)

            incr index
        }
        

    }
    
    $QWIKMD::topGui.nbinput.f$tabid.tableframe.tb finishediting

}

################################################################################
## update analysis in live simulaiton. This proc is called everytime a frame is received
## from namd through IMD
################################################################################
proc QWIKMD::updateMD {args} {
    set tabid [lindex [lindex $QWIKMD::selnotbooks 0] 1]
    if {$QWIKMD::basicGui(live,$tabid) == 1} {
        incr QWIKMD::counterts

        if {$QWIKMD::hbondsGui != ""} {
            if {[expr [expr $QWIKMD::counterts - $QWIKMD::prevcounterts] % $QWIKMD::calcfreq] == 0} {
                QWIKMD::HbondsCalc  
            }   
        }

        if {$QWIKMD::tempGui != "" || $QWIKMD::pressGui != "" || $QWIKMD::volGui != "" } {
            if {[expr [expr $QWIKMD::counterts -  $QWIKMD::prevcounterts] % $QWIKMD::calcfreq] == 0} {
                QWIKMD::CondCalc
            }
        }

        if {$QWIKMD::energyTotGui != "" || $QWIKMD::energyPotGui != "" || $QWIKMD::energyElectGui != "" || $QWIKMD::energyKineGui != "" \
        || $QWIKMD::energyBondGui != "" || $QWIKMD::energyAngleGui != "" || $QWIKMD::energyDehidralGui != "" || $QWIKMD::energyVdwGui != ""} {
            if {[expr [expr $QWIKMD::counterts -  $QWIKMD::prevcounterts] % $QWIKMD::calcfreq] == 0} {
                QWIKMD::EneCalc
            }   
        }
        set do 0
        if {[string match "*smd*" [lindex  $QWIKMD::confFile [expr $QWIKMD::state -1 ] ] ] > 0} {
            set do 1
        }
        if {[info exists QWIKMD::advGui(protocoltb,$QWIKMD::run,[expr $QWIKMD::state -1 ],smd)]} {
            if {$QWIKMD::advGui(protocoltb,$QWIKMD::run,[expr $QWIKMD::state -1 ],smd) == 1} {
                set do 1
            }
        }
        if {$do == 1} {
            incr QWIKMD::countertssmd
        }

        if {$QWIKMD::smdGui != ""} {
            if {[expr [expr $QWIKMD::countertssmd - $QWIKMD::prevcountertsmd] % $QWIKMD::calcfreq] == 0} {
                QWIKMD::SmdCalc 
            }
        }

        if {$QWIKMD::rmsdGui != ""} {
            if {[expr [expr $QWIKMD::counterts -  $QWIKMD::prevcounterts] % $QWIKMD::calcfreq] == 0} {
                QWIKMD::RmsdCalc
            }
        }
        incr QWIKMD::basicGui(mdPrec,0) $QWIKMD::imdFreq

        if {[expr $QWIKMD::counterts - $QWIKMD::prevcounterts] == 1} {
            if {($tabid == 0 && $QWIKMD::basicGui(solvent,$QWIKMD::run,0) == "Explicit") || ($tabid == 1 && $QWIKMD::advGui(solvent,$QWIKMD::run,0) == "Explicit") } {
                update idletasks
                #set pbcinfo ""
                #set do [catch {pbc get -first 0 -last 0 -molid $QWIKMD::topMol} pbcinfo]
                #if {$do == 0} {
                    catch {pbc set $QWIKMD::pbcInfo}
                    catch {pbc box -center bb -color yellow -width 4}
                #}
                
            }
        }   
        QWIKMD::updateTime live
    }

    
    if {[file exists "[lindex $QWIKMD::confFile [expr $QWIKMD::state -1]].check"] == 1} {
        set line ""
        QWIKMD::selectNotebooks 1
        while {$line == ""} {
            set fil [open [lindex $QWIKMD::confFile [expr $QWIKMD::state -1] ].check r]
            set line [read -nonewline $fil]
            close $fil
        } 

        if {$QWIKMD::basicGui(live,$tabid) == 1} {
            trace vdelete ::vmd_timestep($QWIKMD::topMol) w ::QWIKMD::updateMD
        }

        if {$line != "DONE" } {
            incr QWIKMD::state -1
            tk_messageBox -message "One or more files failed to be written. The new simulation ready to run is \
            [lindex $QWIKMD::prevconfFile [expr $QWIKMD::state -1]]" -title "Running Simulation" -icon warning -type ok -parent $QWIKMD::topGui
            QWIKMD::defaultIMDbtt $tabid normal
            # [lindex $QWIKMD::runbtt $tabid] configure -state normal
            # [lindex $QWIKMD::runbtt $tabid] configure -text "Start [QWIKMD::RunText]"
            # $QWIKMD::basicGui(preparebtt,$tabid) configure -state normal
            
        } else {
            tk_messageBox -message "The molecular Dynamics simulation [lindex $QWIKMD::prevconfFile [expr $QWIKMD::state -1] ] finished.\
             Please press Run button to continue" -title "Running Simulation" -icon info -type ok -parent $QWIKMD::topGui
            # $QWIKMD::runbtt configure -text "Start [QWIKMD::RunText]"
            # $QWIKMD::runbtt configure -state normal
            # $QWIKMD::basicGui(preparebtt,$tabid)  configure -state normal
        }
        QWIKMD::defaultIMDbtt $tabid normal
        [lindex $QWIKMD::preparebtt $tabid] configure -state normal
        [lindex $QWIKMD::savebtt $tabid] configure -state disabled
        set QWIKMD::prevcounterts $QWIKMD::counterts
        if {$QWIKMD::run == "SMD"} {
            set do 0
            if {$tabid == 0} {
                if {$QWIKMD::basicGui(prtcl,$QWIKMD::run,smd) == 1} {
                    set do 1
                }
            } else {
                if {$QWIKMD::advGui(protocoltb,$QWIKMD::run,$QWIKMD::state,smd) == 1} {
                    set do 1
                }
            }
            if {$do == 1} {
                set QWIKMD::prevcountertsmd $QWIKMD::countertssmd
            }  
        }
        
    }

}

################################################################################
## Proc called by the button Apply
## Used to validate the deletion and inclusion of residues in Select Residue window
## Also to validate the selection of the anchor and pulling residues in SMD simulations
## and QM regions as well as Center of Mass for QM calculations
## General residue selection using the table
################################################################################
proc QWIKMD::Apply {} {
    set table $QWIKMD::selresTable
    set lock 0
    set id [$table curselection]
    ## Return if no residue was selected or if the molecule to be EDITED is a "QM" molecule type
    # if {$id == "" || ($QWIKMD::tablemode == "edit" && [$table cellcget $id,3 -text] == "QM" && $QWIKMD::advGui(qmoptions,qmgentopo) == 0)} {
    #     if {$id != ""} {
    #         tk_messageBox -message "Molecules defined as \"QM\" cannot be edited." -type ok \
    #         -icon warning -title "Modify \"QM\" Molecules" -parent $QWIKMD::selResGui
    #     }
    #     return
    # }
    set qmmm 0
    if {[regexp "QM Region Selection" [wm title $QWIKMD::selResGui] ]} {
        set qmmm 1
    } elseif {[regexp "Center of Mass Region Selection" [wm title $QWIKMD::selResGui] ] } {
        set qmmm 2
    }
    if {$QWIKMD::anchorpulling != 1 && ($QWIKMD::tablemode == "add" || $QWIKMD::tablemode == "delete" || $QWIKMD::tablemode == "edit") && $qmmm == 0} {
    
        if {$QWIKMD::tablemode == "delete"} {
            set prechain ""
            set chain ""
            set chainind 0
            set length [expr [array size QWIKMD::chains] /3]
            for {set i 0} {$i < [llength $id]} {incr i} {
                set row [lindex $id $i]
                $table rowconfigure $row -background white -foreground grey -selectbackground cyan -selectforeground grey
                $table cellconfigure $row,1 -editable false
                $table cellconfigure $row,3 -editable false
                set resid [$table cellcget $row,0 -text]
                set chain [$table cellcget $row,2 -text]
                set type [$table cellcget $row,3 -text]
                set resname [lindex [$table cellcget $row,1 -text] 0]
                set str "${resid}_${chain}"
                set index [lsearch -exact $QWIKMD::delete $str]
                set chaint "$chain and $type"
                if {$index == -1} {
                    lappend QWIKMD::delete $str
                    set index 0
                    if {$chaint == $prechain} {
                        for {set i 0} {$i < $length} {incr i} {
                            if {$QWIKMD::chains($i,1) == $chaint} {
                                set chainind $i
                                break
                            }
                        }
                        set prechain $chaint
                        if {$type == "protein" || $type == "nucleic" || $type == "hetero" || $type == "lipid" || $type == "glycan"} {
                            set QWIKMD::index_cmb($chaint,5) "chain \"$chain\" and qwikmd_${type}"
                        } else {
                            set QWIKMD::index_cmb($chaint,5) "chain \"$chain\" and $type"
                        }
                        
                    } 
                    if {$type == "protein" || $type == "nucleic" || $type == "hetero" || $type == "lipid" || $type == "glycan"} {
                        append QWIKMD::index_cmb($chaint,5) " and not (resid \"[$table cellcget $row,0 -text]\" and chain \"$chain\" and qwikmd_${type})"
                    } else {
                        append QWIKMD::index_cmb($chaint,5) " and not (resid \"[$table cellcget $row,0 -text]\" and chain \"$chain\" and $type)"
                    }
                }

            }

            for {set i 0} {$i < $length} {incr i} {
                if {$QWIKMD::chains($i,0) == 1} {
                    mol modselect $i $QWIKMD::topMol [lindex $QWIKMD::index_cmb($QWIKMD::chains($i,1),5)]
                }
                
            }

        } elseif {$QWIKMD::tablemode == "add"} {
            
            for {set i 0} {$i < [llength $id]} {incr i} {
                set row [lindex $id $i]
                
                set resid [$table cellcget $row,0 -text]
                set chain [$table cellcget $row,2 -text]
                set type [$table cellcget $row,3 -text]
                set str "${resid}_${chain}"
                set index [lsearch -exact $QWIKMD::delete $str]
                set chaint "$chain and $type"
                if { $index != -1} {
                    set QWIKMD::delete [lreplace $QWIKMD::delete $index $index]
                    if {$type == "protein" || $type == "nucleic" || $type == "hetero" || $type == "lipid" || $type == "glycan"} {
                        set first [string first " and not (resid \"$resid\" and chain \"$chain\" and qwikmd_${type})" $QWIKMD::index_cmb($chaint,5)]
                        set length [string length " and not (resid \"$resid\" and chain \"$chain\" and qwikmd_${type})"]
                    } else {
                        set first [string first " and not (resid \"$resid\" and chain \"$chain\" and $type)" $QWIKMD::index_cmb($chaint,5)]
                        set length [string length " and not (resid \"$resid\" and chain \"$chain\" and $type)"]
                    }
                    set QWIKMD::index_cmb($chaint,5) "[string range $QWIKMD::index_cmb($chaint,5) 0 [expr $first -1]][string range $QWIKMD::index_cmb($chaint,5) [expr $first + $length] end]"
                    
                }

                set index [lsearch -exact $QWIKMD::rename $str]
                if { $index != -1} {
                    $table rowconfigure $row -background red -foreground black -selectbackground cyan -selectforeground black
                } else {
                    $table rowconfigure $row -background white -foreground black -selectbackground cyan -selectforeground black
                }
                $table cellconfigure $row,1 -editable true
                $table cellconfigure $row,3 -editable true
            }
            set text ""
            set length [expr [array size QWIKMD::chains] /3]
            for {set i 0} {$i < $length} {incr i} {
                mol modselect $i $QWIKMD::topMol $QWIKMD::index_cmb($QWIKMD::chains($i,1),5)    
            }
            QWIKMD::SelResid
        } elseif {$QWIKMD::tablemode == "edit"} { 
            
            QWIKMD::editAtomGuiProc
            QWIKMD::updateEditAtomWindow
            if {$id != ""} {
                QWIKMD::editAtom
            }
        }

        $table selection clear 0 end
        QWIKMD::rowSelection

    } elseif {$QWIKMD::run == "SMD" && $QWIKMD::anchorpulling == 1} {
        # if QWIKMD::buttanchor == 1 called from Anchoring Residues
        # if QWIKMD::buttanchor == 2 called from Pulling Residues
        
        set msg 0
        if {$QWIKMD::buttanchor == 1} {
            set QWIKMD::anchorRessel ""
            set QWIKMD::anchorRes ""
            for {set i 0} {$i < [llength $id]} {incr i} {
                set resid [$table cellcget [lindex  $id $i],0 -text]
                set chain [$table cellcget [lindex  $id $i],2 -text]
                if {[lsearch $QWIKMD::pullingRes ${resid}_$chain] == -1} {
                    lappend QWIKMD::anchorRes ${resid}_$chain
                    if {$i != 0} {
                        append QWIKMD::anchorRessel " or resid \"$resid\" and chain \"$chain\"" 
                    } else {
                        append QWIKMD::anchorRessel "resid \"$resid\" and chain \"$chain\"" 
                    }
                } else {
                    set msg 1
                }
            }

        } elseif {$QWIKMD::buttanchor == 2} {
            set QWIKMD::pullingRessel ""
            set QWIKMD::pullingRes ""
            for {set i 0} {$i < [llength $id]} {incr i} {
                set resid [$table cellcget [lindex  $id $i],0 -text]
                set chain [$table cellcget [lindex  $id $i],2 -text]
                if {[lsearch $QWIKMD::anchorRes ${resid}_$chain] == -1} {
                    lappend QWIKMD::pullingRes ${resid}_$chain
                    if {$i != 0} {
                        append QWIKMD::pullingRessel " or resid \"$resid\" and chain \"$chain\""
                    } else {
                        append QWIKMD::pullingRessel "resid \"$resid\" and chain \"$chain\""
                    } 
                } else {
                    set msg 1
                }
                
            }
        }
        QWIKMD::checkAnchors
        
        if {$msg == 1} {
            tk_messageBox -message "Anchor and pulling residues selections overlapped. Please review you selections" \
            -title "Overlapping Selections" -icon info -type ok -parent $QWIKMD::selResGui
        } else {
            set QWIKMD::anchorpulling 0
            set QWIKMD::buttanchor 0
            set lock 1
        }
        
    } elseif {$qmmm > 0} {
        set qmID $QWIKMD::advGui(pntchrgopt,qmID)
        if {$qmmm == 1} {
            if {[QWIKMD::reviewQMCharges $qmID] == 1} {
                QWIKMD::reviseQMRegion $qmID
                return
            }
            set tblselected 0
            set QWIKMD::advGui(qmtable,$qmID,qmRegionSelIndex) ""
            set QWIKMD::advGui(qmtable,$qmID,qmRegionSel) ""
            set repnameaux [list]
            if {$QWIKMD::selResidSel == "" || $QWIKMD::selResidSel == "Type Selection"} {
                set repnameaux $QWIKMD::resrepname
                set QWIKMD::resrepname [list]
            }
            
            for {set i 0} {$i < [llength $id]} {incr i} {
                set resid [$table cellcget [lindex  $id $i],0 -text]
                set chain [$table cellcget [lindex  $id $i],2 -text]
                lappend QWIKMD::advGui(qmtable,$qmID,qmRegionSelIndex) ${resid}_$chain
                if {$QWIKMD::selResidSel == "" || $QWIKMD::selResidSel == "Type Selection"} {
                    # if {$i != 0} {
                    #     append QWIKMD::advGui(qmtable,$qmID,qmRegionSel) " or resid \"$resid\" and chain \"$chain\""
                    # } else {
                    #     append QWIKMD::advGui(qmtable,$qmID,qmRegionSel) "resid \"$resid\" and chain \"$chain\""
                    # }
                    lappend QWIKMD::resrepname [list ${resid}_$chain 0]
                }
            }
            if {$QWIKMD::selResidSel == "" || $QWIKMD::selResidSel == "Type Selection"} {
                set QWIKMD::advGui(qmtable,$qmID,qmRegionSel) [QWIKMD::reduceSelStr]
                set QWIKMD::resrepname $repnameaux
            }
            set tblselected 0
            if {$QWIKMD::selResidSel != "" && $QWIKMD::selResidSel != "Type Selection"} {
                if {[string first "segname" $QWIKMD::selResidSel] > -1 && $QWIKMD::load == 0} {
                    tk_messageBox -message "Don't use \"segname\" to define QM regions. This molecule field changes during structure preparation." \
            -title "QM Region Selection" -icon error -type ok -parent $QWIKMD::selResGui
                    return
                }
                set QWIKMD::advGui(qmtable,$qmID,qmRegionSel) $QWIKMD::selResidSel
            }
            #set QWIKMD::advGui(qmtable,$qmID,qmRegionNumAtoms) [$QWIKMD::advGui(qmregopt,atmnumb) cget -text]
            set QWIKMD::advGui(qmtable,$qmID,solvDist) $QWIKMD::advGui(pntchrgopt,qmsolv)
            set QWIKMD::advGui(qmtable,$qmID,pcDist) $QWIKMD::advGui(pntchrgopt,pcDist)
            # 
            #[$QWIKMD::advGui(qmtable) editwinpath] delete 0 end
            #[$QWIKMD::advGui(qmtable) editwinpath] insert end [$QWIKMD::advGui(qmregopt,atmnumb) cget -text]
            # set solvent "(same residue as (all within $QWIKMD::advGui(qmtable,$qmID,solvDist) of ($QWIKMD::advGui(qmtable,$qmID,qmRegionSel)))) and not qwikmd_protein and not qwikmd_nucleic and not qwikmd_glycan"
            # set selaux [atomselect top "$QWIKMD::advGui(qmtable,$qmID,qmRegionSel) or ($solvent)" frame now]
            # set QWIKMD::advGui(qmtable,$qmID,charge) [expr round([eval "vecadd [$selaux get charge]"])]
            $QWIKMD::advGui(qmtable) cellconfigure [expr $qmID -1],2 -text $QWIKMD::advGui(qmtable,$qmID,charge)
            $QWIKMD::advGui(qmtable) cellconfigure [expr $qmID -1],1 -text $QWIKMD::advGui(qmregopt,atmnumb)
            # $selaux delete
            $QWIKMD::advGui(qmtable) finishediting
            set lock 1          
            
        } else {
            set QWIKMD::advGui(qmtable,$qmID,qmCOMIndex) ""
            set QWIKMD::advGui(qmtable,$qmID,qmCOMSel) ""
            set selaux ""
            for {set i 0} {$i < [llength $id]} {incr i} {
                set resid [$table cellcget [lindex  $id $i],0 -text]
                set chain [$table cellcget [lindex  $id $i],2 -text]
                lappend QWIKMD::advGui(qmtable,$qmID,qmCOMIndex) ${resid}_$chain
            }
            if {[llength $id] > 0} {
                set QWIKMD::advGui(qmtable,$qmID,qmCOMSel) [QWIKMD::reduceSelStr]
            }
            
            #set QWIKMD::advGui(qmtable,$qmID,qmRegionNumAtoms) [$QWIKMD::advGui(qmregopt,atmnumb) cget -text]
            $QWIKMD::advGui(qmtable) cellconfigure [expr $qmID -1],4 -text $QWIKMD::advGui(qmtable,$qmID,qmCOMSel)
            #[$QWIKMD::advGui(qmtable) editwinpath] delete 0 end
            #[$QWIKMD::advGui(qmtable) editwinpath] insert end $QWIKMD::advGui(qmtable,$qmID,qmCOMSel)
            #set prtclrow [$QWIKMD::advGui(protocoltb,$QWIKMD::run) curselection]

            $QWIKMD::advGui(qmtable) finishediting
            set lock 1
        }
        set QWIKMD::selResidSel ""
        set QWIKMD::selResidSelIndex [list]
        
    } else {
        set tabid [$QWIKMD::topGui.nbinput index current]
        if {$tabid == 1 && [llength  $QWIKMD::resrepname] > 0} {
            set prtclrow [lindex [$QWIKMD::advGui(protocoltb,$QWIKMD::run) editinfo] 1]

            if {$QWIKMD::selResidSel == "Type Selection" || $QWIKMD::selResidSel == ""} {
                set QWIKMD::selResidSel [QWIKMD::reduceSelStr]
            }

            for {set i 0} {$i < [llength $id]} {incr i} {
                set resid [$table cellcget [lindex  $id $i],0 -text]
                set chain [$table cellcget [lindex  $id $i],2 -text]
                lappend QWIKMD::advGui(protocoltb,$QWIKMD::run,$prtclrow,restrIndex) ${resid}_$chain
            }
            [$QWIKMD::advGui(protocoltb,$QWIKMD::run) editwinpath] set $QWIKMD::selResidSel
            #set prtclrow [$QWIKMD::advGui(protocoltb,$QWIKMD::run) curselection]
            set QWIKMD::advGui(protocoltb,$QWIKMD::run,$prtclrow,restrsel) $QWIKMD::selResidSel
            $QWIKMD::advGui(protocoltb,$QWIKMD::run) finishediting
            set QWIKMD::selResidSel ""
            set QWIKMD::selResidSelIndex [list]
            set lock 1
        }
    }
    if {$lock == 1} {
        set opt 1
        if {$QWIKMD::load == 1} {
            set opt 0
        }
        QWIKMD::lockSelResid $opt
        QWIKMD::tableModeProc
        wm withdraw $QWIKMD::selResGui 
        trace remove variable ::vmd_pick_event write QWIKMD::ResidueSelect
        mouse mode rotate
    }
    QWIKMD::SelResClearSelection
}
################################################################################
## Reduces the string produced by selecting the residues from the residue table
################################################################################
proc QWIKMD::reduceSelStr {} {
    set outstr ""
    set listChains [lsort -unique [$QWIKMD::selresTable getcolumns 2]]
    set selindex [$QWIKMD::selresTable curselection]
    foreach chain $listChains {
        # set selRes [lsearch -index 0 -all $QWIKMD::resrepname "*_${chain}"]
        set residstr ""

        foreach ind $selindex {
            if {[$QWIKMD::selresTable cellcget $ind,2 -text] == $chain} {
                append residstr "\"[$QWIKMD::selresTable cellcget $ind,0 -text]\" "
            }
        }

        if {[llength $residstr] > 0} {
            append outstr "\(resid $residstr and chain \"$chain\"\) or "
        }
        
    }
    if {$outstr != ""} {
        set outstr [string trimright $outstr "or "]
    }
    return $outstr
}
################################################################################
## validate QM Charges
## If QM package is Mopac, check if -1 <= charges >= +1
## all packages if the total QM charges (per QM region) is integer
################################################################################
proc QWIKMD::reviewQMCharges {qmID} {
    set return 0
    set pckg $QWIKMD::advGui(qmoptions,soft,$QWIKMD::advGui(qmoptions,crrtprtcl))
    if {[QWIKMD::format2Dec [expr fmod($QWIKMD::advGui(qmtable,$qmID,charge),1)]] > 0.00} {
        tk_messageBox -message "The total charge of QM region $qmID must be an integer number. \
        Please add or delete more residues to reach the adequate total charge value."\
        -title "QM Region Charge" -icon info -type ok -parent $QWIKMD::selResGui 
        set return 1
    } elseif {[expr abs($QWIKMD::advGui(qmtable,$qmID,charge)) > 1] && $QWIKMD::advGui(qmoptions,checkchrgMOPAC) == 0} {
        set do 0
        if {$pckg== "ORCA"} {
            set prctnames [$QWIKMD::advGui(protocoltb,$QWIKMD::run) getcolumns 0]

            foreach prct $prctnames {
                if {[lsearch -index 0 $QWIKMD::advGui(qmoptions,ptcqmval,$prct) "!PM3"] != -1 ||
                [lsearch -index 0 $QWIKMD::advGui(qmoptions,ptcqmval,$prct) "!AM1"] != -1 ||
                [lsearch -index 0 $QWIKMD::advGui(qmoptions,ptcqmval,$prct) "!MNDO"] != -1} {
                    set do 1
                    break
                } 
            }   
        } elseif {$pckg == "MOPAC"} {
            set do 1
        }
        if {$do == 1} {
           tk_messageBox -message "The total charges of the QM regions should be between -1 and 1 (inclusive) when using semiempirical methods. \
            Please add or delete more residues to reach the adequate total charge value."\
            -title "QM region charge in Semiempirical Methods" -icon info -type ok -parent $QWIKMD::selResGui 
            set QWIKMD::advGui(qmoptions,checkchrgMOPAC) 1 
            set return 1 
        }
        
    }
    return $return
}
################################################################################
## Represent the residues around the QM region qmID that can be 
## selected to balance the excess charge (in case of semiempirical methods)
################################################################################
proc QWIKMD::reviseQMRegion {qmID} {
    set index [lsearch $QWIKMD::resrepname "potQM"]
    #set QWIKMD::advGui(qmtable,potQM) 0
    if { $index > -1} {
        mol delrep [QWIKMD::getrepnum [lindex [lindex $QWIKMD::resrepname $index] 1] $QWIKMD::topMol] $QWIKMD::topMol
        set QWIKMD::resrepname [lreplace $QWIKMD::resrepname $index $index]
    }
    
    set qmrepindex [lsearch -index 0 $QWIKMD::resrepname "qmmm"]
    if {$qmrepindex == -1} {
        $QWIKMD::advGui(qmtable) cellselection set [expr $qmID -1],1
        QWIKMD::qmRegionTableBind
        # display update ui 
        set qmrepindex [lsearch -index 0 $QWIKMD::resrepname "qmmm"]
        # vwait ::QWIKMD::advGui(qmtable,tbselected)
    }

    set qmmmRep [QWIKMD::getrepnum [lindex [lindex $QWIKMD::resrepname $qmrepindex] 1] $QWIKMD::topMol] 
    set qmmmSel [molinfo $QWIKMD::topMol get "{selection $qmmmRep}"]
    set seltext [atomselect $QWIKMD::topMol "(((all within 5 of ($qmmmSel)) and not water) and not ($qmmmSel)) and not segname ION and not water"]
    set residues [$seltext get residue]
    set reslist [lsort -unique $residues]
    $seltext delete 
    set selecttext ""
    foreach res $reslist {
        set sel [atomselect $QWIKMD::topMol "residue $res"]
        set charge ""
        if {[$sel num] == 1} {
            set charge [$sel get charge]
        } elseif {[$sel num] > 1} {
            set charge [eval "vecadd [$sel get charge]"]
        } else {
            continue
        }
        set charge [QWIKMD::format2Dec $charge ]
        if {[expr abs($charge)] > 0 } {
            append selecttext "(residue $res) or "
        }
        $sel delete
    }
    if {$selecttext == ""} {
        tk_messageBox -message "There is no charged residue within 5A of the QM region." -title "Charged Residues"\
        -type ok -icon warning -parent $QWIKMD::selresTable
    }
    mol addrep $QWIKMD::topMol
    lappend QWIKMD::resrepname [list "potQM" [mol repname $QWIKMD::topMol [expr [molinfo $QWIKMD::topMol get numreps] -1] ]] 
    set rep [QWIKMD::getrepnum [lindex [lindex $QWIKMD::resrepname end] 1] $QWIKMD::topMol]
    mol modcolor $rep $QWIKMD::topMol "ResType"
    mol modselect $rep $QWIKMD::topMol [string trimright $selecttext " or"]
    mol modstyle $rep $QWIKMD::topMol "Licorice"
    mol modmaterial $rep $QWIKMD::topMol "Transparent"
}
################################################################################
## validate simulation time and temperature
## opt 1 -- command called by changes in max length (SMD simulations)
## opt 2 -- command called by changes in pulling speed (SMD simulations)
## opt 3 -- command called by changes in simulaiton time (SMD simulations)
################################################################################
proc QWIKMD::reviewLenVelTime {opt} {
    if {$opt == 1 || $opt == 2} {
        set val [expr [expr $QWIKMD::basicGui(plength) * 1.0] / {$QWIKMD::basicGui(pspeed) * 1.0} ]
        set point [string first $val "."]
        set decimal [string length [string range $val $point end]]
        if {$decimal > 6} {
            set val [QWIKMD::format5Dec $val]
        }
        set QWIKMD::basicGui(mdtime,1) $val
    } elseif {$opt == 3} {
        set val [QWIKMD::format0Dec [expr $QWIKMD::basicGui(mdtime,1) / 2e-6]]
        set mod [expr fmod($val,10)]
        if { $mod != 0.0} { 
            set QWIKMD::basicGui(mdtime,1) [QWIKMD::format5Dec [expr [expr $val + {10 - $mod}] * 2e-6 ] ]
            
        } 
        set val [expr [expr $QWIKMD::basicGui(plength) * 1.0] / { $QWIKMD::basicGui(mdtime,1) * 1.0 }]
        set point [string first $val "."]
        set decimal [string length [string range $val $point end]]
        if {$decimal > 6} {
            set val [QWIKMD::format5Dec $val]
        }
        set QWIKMD::basicGui(pspeed) $val
    }
}

################################################################################
## check if the anchor and pulling residues are represented in the OpenGL VMD window 
################################################################################
proc QWIKMD::checkAnchors {} {
    
    if {$QWIKMD::anchorRessel != "" && $QWIKMD::showanchor == 1} {
        if {$QWIKMD::anchorrepname == ""} {
            mol representation "VDW 1.0 12.0"
            mol addrep $QWIKMD::topMol
            set QWIKMD::anchorrepname [mol repname $QWIKMD::topMol [expr [molinfo $QWIKMD::topMol get numreps] -1] ]
            mol modcolor [QWIKMD::getrepnum $QWIKMD::anchorrepname $QWIKMD::topMol] $QWIKMD::topMol "ColorID 2"
            QWIKMD::RenderChgResolution
        }
        mol modselect [QWIKMD::getrepnum $QWIKMD::anchorrepname $QWIKMD::topMol] $QWIKMD::topMol $QWIKMD::anchorRessel
    } elseif {$QWIKMD::anchorrepname != "" && $QWIKMD::showanchor == 0} {
        mol delrep [QWIKMD::getrepnum $QWIKMD::anchorrepname $QWIKMD::topMol] $QWIKMD::topMol
        set QWIKMD::anchorrepname ""
    }

    if {$QWIKMD::pullingRessel != "" && $QWIKMD::showpull == 1} {
        if {$QWIKMD::pullingrepname == ""} {
            mol representation "VDW 1.0 12.0"
            mol addrep $QWIKMD::topMol
            set QWIKMD::pullingrepname [mol repname $QWIKMD::topMol [expr [molinfo $QWIKMD::topMol get numreps] -1] ]
            mol modcolor [QWIKMD::getrepnum $QWIKMD::pullingrepname $QWIKMD::topMol] $QWIKMD::topMol "ColorID 10"
            QWIKMD::RenderChgResolution
        }
        mol modselect [QWIKMD::getrepnum $QWIKMD::pullingrepname $QWIKMD::topMol] $QWIKMD::topMol $QWIKMD::pullingRessel
    } elseif {$QWIKMD::pullingrepname != "" && $QWIKMD::showpull == 0} {
        mol delrep [QWIKMD::getrepnum $QWIKMD::pullingrepname $QWIKMD::topMol] $QWIKMD::topMol
        set QWIKMD::pullingrepname ""
    }
}

################################################################################
## Bind proc when the table inside Select Residue window is selected
################################################################################
proc QWIKMD::rowSelection {} {
    set moltop $QWIKMD::topMol
    mol selection ""
    mol representation "Licorice"
    set table $QWIKMD::selresTable
    set id [$table curselection]
    for {set i 0} {$i < [llength $QWIKMD::residtbprev]} {incr i} {
        # if {[lsearch $id [lindex $QWIKMD::residtbprev $i]] == -1} {
            set type [$table cellcget [lindex $QWIKMD::residtbprev $i],3 -text]
            switch $type {
                protein {
                    set repname proteinrep
                }
                nulceic {
                    set repname nucleicrep
                }
                glycan {
                    set repname glycanrep
                }
                lipid {
                    set repname lipidrep
                }
                water {
                    set repname waterrep
                }
                default {
                    set repname otherrep
                }
            }
            set index [lsearch -index 0 $QWIKMD::resrepname $repname]
            if {$index > -1} {
                mol delrep [QWIKMD::getrepnum [lindex [lindex $QWIKMD::resrepname $index] 1] $QWIKMD::topMol] $QWIKMD::topMol
                set QWIKMD::resrepname [lreplace $QWIKMD::resrepname $index $index]
            }
        # }
    }
    update idletasks
    if {$id != ""} {
        set resid [$table cellcget [lindex $id 0],0 -text]
        set resname [$table cellcget [lindex $id 0],1 -text]
        set chain [$table cellcget [lindex $id 0],2 -text]
        set type [$table cellcget [lindex $id 0],3 -text]
        # set brk 0
        if {($QWIKMD::tablemode == "type" || $QWIKMD::tablemode == "rename")} {
            
            if {$type != "water"} {
                if {$QWIKMD::tablemode == "mutate" || $QWIKMD::tablemode == "prot" || $QWIKMD::tablemode == "rename"} {
                    $table columnconfigur 3  -editable false
                    $table columnconfigure 1 -editable true
                    $table editcell [lindex $id 0],1
                } elseif {$QWIKMD::tablemode == "type"} {
                    
                    $table columnconfigur 3  -editable true
                    $table columnconfigure 1 -editable false
                    $table editcell [lindex $id 0],3
                }
            }
            # if {$brk == 1} {
            #   $QWIKMD::selresTable cancelediting
            #   $QWIKMD::selresTable columnconfigure 1 -editable false 
            #   $QWIKMD::selresTable columnconfigure 3 -editable false 
            # }
            
        } 
        ## Use reduceString to concatenate the representations by molecule type
        ## Reduces the number of selections and improves performance to allow
        ## the preparation of large systems
        set proteinrep [list]
        set nucleicrep [list]
        set glycanrep [list]
        set lipidrep [list]
        set waterrep [list]
        set otherrep [list]
        set staux ""

        for {set i 0} {$i < [llength $id]} {incr i} {
            set index [lindex $id $i]
            set type [$table cellcget $index,3 -text]
            set resname [lindex [split [$table cellcget $index,1 -text] "->"] 0]
            set resid [$table cellcget $index,0 -text]
            set chain [$table cellcget $index,2 -text]
            append staux "resid \"$resid\" and chain \"$chain\" or "
            switch $type {
                protein {
                    lappend proteinrep $index
                }
                nulceic {
                    lappend nucleicrep $index
                }
                glycan {
                    lappend glycanrep $index
                }
                lipid {
                    lappend lipidrep $index
                }
                water {
                    lappend waterrep $index
                }
                default {
                    lappend otherrep $index
                }
            }
        }
        if {[regexp "QM Region Selection" [wm title $QWIKMD::selResGui]] == 0}  {
            set typelist [list protein nulceic glycan lipid water default]
            foreach type $typelist {

                set repname ""
                set indelist ""
                switch $type {
                    protein {
                        set repname proteinrep
                        set indexlist $proteinrep
                    }
                    nulceic {
                        set repname nucleicrep
                        set indexlist $nucleicrep
                    }
                    glycan {
                        set repname glycanrep
                        set indexlist $glycanrep
                    }
                    lipid {
                        set repname lipidrep
                        set indexlist $lipidrep
                    }
                    water {
                        set repname waterrep
                        set indexlist $waterrep
                    }
                    default {
                        set repname otherrep
                        set indexlist $otherrep
                    }
                }
                if {[llength $indexlist] == 0} {
                    continue
                }
                $QWIKMD::selresTable selection clear 0 end
                $QWIKMD::selresTable selection set $indexlist
                set str [QWIKMD::reduceSelStr]
                set repr ""
                if {$type == "protein" || $type == "nucleic" || $type == "glycan" || $type == "lipid" } {
                    set repr "Licorice"
                } elseif {$type == "hetero" || $type == "QM"} {
                    set repr "VDW 1.0 12.0"
                } elseif {$type == "water"} {
                    if {$chain == "W"} {
                        set repr "Points"
                    } else {
                        set repr "VDW 1.0 12.0"
                    }
                } else {
                    set repr "Licorice"
                }
                mol representation $repr
                mol addrep $moltop
                lappend QWIKMD::resrepname [list $repname [mol repname $moltop [expr [molinfo $QWIKMD::topMol get numreps] -1] ]]
                set repnamenew [QWIKMD::getrepnum [lindex [lindex $QWIKMD::resrepname end] 1] $QWIKMD::topMol]
                mol modselect $repnamenew $moltop $str
                mol modcolor $repnamenew $moltop "Name"
            }
            QWIKMD::RenderChgResolution
            $QWIKMD::selresTable selection clear 0 end
            $QWIKMD::selresTable selection set $id
        }

        if {[regexp "QM Region Selection" [wm title $QWIKMD::selResGui]] && [llength $id] > 0} {
            set qmID $QWIKMD::advGui(pntchrgopt,qmID)
            set staux [string trimright $staux " or "]
            set redef 0
            set tabid [$QWIKMD::topGui.nbinput index current]
            if {$tabid != [lindex [lindex $QWIKMD::selnotbooks 0] 1] || \
                [$QWIKMD::topGui.nbinput.f[expr ${tabid} +1].nb index current] != [lindex [lindex $QWIKMD::selnotbooks 1] 1]} {
                set redef 1   
            }
            if {$QWIKMD::selResidSel == "Type Selection" && $redef == 1} {
                set sel [atomselect $QWIKMD::topMol "all"]
                $sel set beta 0
                $sel set occupancy 0
                $sel delete
                QWIKMD::getQMMM $qmID $staux
            } elseif {$redef == 0} {
                set sel [atomselect $QWIKMD::topMol "index $QWIKMD::advGui(qmtable,$qmID,indexes)"]
                $sel set beta $qmID
                update
                set sel2 [atomselect $QWIKMD::topMol "beta == 1"]
                $sel delete
            }
            set staux "all and beta == $qmID"
            set within "within"
            if {$QWIKMD::load == 1} {
                set within "pbwithin"
            }
            set settext "($staux)"
            if {$redef == 1} {
                set solvent "same residue as (all $within $QWIKMD::advGui(pntchrgopt,qmsolv) of ($staux)) and not qwikmd_protein and not qwikmd_nucleic and not qwikmd_glycan"
                set settext "($staux) or ($solvent)"
            }
            
            set atmsel [atomselect $QWIKMD::topMol "$settext"]
            set numamts [$atmsel num]
            if {$redef == 1} {
                set charge ""
                if {$numamts > 1} {
                    set charge [QWIKMD::format2Dec [eval "vecadd [$atmsel get charge]"]]
                } elseif {$numamts == 1} {
                    set charge [QWIKMD::format2Dec [$atmsel get charge]]
                }
                set QWIKMD::advGui(qmtable,$qmID,charge) $charge
                set QWIKMD::advGui(qmtable,$qmID,qmTopoCharge) $charge
                set QWIKMD::advGui(qmtable,$qmID,indexes) [$atmsel get index]
            }
            set QWIKMD::advGui(qmregopt,lblqmcharge) $QWIKMD::advGui(qmtable,$qmID,charge)
            $QWIKMD::advGui(qmtable) cellconfigure [expr $qmID -1],2 -text $QWIKMD::advGui(qmtable,$qmID,charge)
            $QWIKMD::advGui(qmtable) cellconfigure [expr $qmID -1],1 -text $numamts
            $atmsel delete
            set QWIKMD::advGui(qmregopt,atmnumb) $numamts

            set index [lsearch -index 0 $QWIKMD::resrepname "qmmm"]
            
            if {$index != -1} {
                mol delrep [QWIKMD::getrepnum [lindex [lindex $QWIKMD::resrepname $index] 1] $QWIKMD::topMol] $QWIKMD::topMol
                set QWIKMD::resrepname [lreplace $QWIKMD::resrepname $index $index]
            }
            mol addrep $moltop
            mol representation "DynamicBonds"
            lappend QWIKMD::resrepname [list "qmmm" [mol repname $moltop [expr [molinfo $QWIKMD::topMol get numreps] -1] ]]
            set repnum  [QWIKMD::getrepnum [lindex [lindex $QWIKMD::resrepname end] 1] $QWIKMD::topMol]
            mol modcolor $repnum $moltop "Name"
            mol modselect $repnum $moltop "$settext"
            QWIKMD::RenderChgResolution
            # if {$QWIKMD::advGui(qmoptions,ptcharge) == "on"} {
            #     set atmsel [atomselect $QWIKMD::topMol "(all within $QWIKMD::advGui(qmtable,$qmID,pcDist) of ($staux)) and not water"]
            #     set numamts [$atmsel num]
            #     $atmsel delete
            # }

            # set QWIKMD::advGui(qmtable,$qmID,qmRegionSel) $staux
            # set QWIKMD::advGui(qmtable,$qmID,qmRegionSelIndex) $QWIKMD::resrepname
        }
    } else {
        for {set i 0} {$i < [llength $QWIKMD::resrepname]} {incr i} {
            mol delrep [QWIKMD::getrepnum [lindex [lindex $QWIKMD::resrepname $i] 1] $QWIKMD::topMol] $QWIKMD::topMol
        }
        set QWIKMD::resrepname [list]
        if {[regexp "QM Region Selection" [wm title $QWIKMD::selResGui]]} {
            set QWIKMD::advGui(qmregopt,atmnumb) 0
        }
    }
    set QWIKMD::residtbprev $id
}
proc QWIKMD::save_viewpoint {view_num} {
   global viewpoints
   foreach mol [molinfo list] {
      set viewpoints($QWIKMD::topMol,0) [molinfo $mol get rotate_matrix]
      set viewpoints($QWIKMD::topMol,1) [molinfo $mol get center_matrix]
      set viewpoints($QWIKMD::topMol,2) [molinfo $mol get scale_matrix]
      set viewpoints($QWIKMD::topMol,3) [molinfo $mol get global_matrix]
   }
}

proc QWIKMD::restore_viewpoint {view_num} {
   global viewpoints
   foreach mol [molinfo list] {
      if [info exists viewpoints($QWIKMD::topMol,0)] {
        molinfo $mol set center_matrix $viewpoints($QWIKMD::topMol,1)
        molinfo $mol set rotate_matrix $viewpoints($QWIKMD::topMol,0)
        molinfo $mol set scale_matrix $viewpoints($QWIKMD::topMol,2)
        molinfo $mol set global_matrix $viewpoints($QWIKMD::topMol,3)
        
      }
   }
}

proc QWIKMD::SaveInputFile {file} {
    if {[file exists $file] == 1} {
        file delete -force -- $file
    }
    set ofile [open $file w+]

    puts $ofile [string repeat "#" 20]
    puts $ofile "#\t\t QwikMD Input File"
    puts $ofile [string repeat "#\n" 10]
    puts $ofile [string repeat "#" 20]
    
    puts $ofile "set QWIKMD::nucleicmcr \{$QWIKMD::nucleicmcr\}"
    puts $ofile "set QWIKMD::proteinmcr \{$QWIKMD::proteinmcr\}"
    puts $ofile "set QWIKMD::heteromcr \{$QWIKMD::heteromcr\}"
    puts $ofile "set QWIKMD::glycanmcr \{$QWIKMD::glycanmcr\}"
    puts $ofile "set QWIKMD::lipidmcr \{$QWIKMD::lipidmcr\}"
    puts $ofile "atomselect macro qwikmd_protein \$QWIKMD::proteinmcr"
    puts $ofile "atomselect macro qwikmd_nucleic \$QWIKMD::nucleicmcr"
    puts $ofile "atomselect macro qwikmd_glycan \$QWIKMD::glycanmcr"
    puts $ofile "atomselect macro qwikmd_lipid \$QWIKMD::lipidmcr"
    puts $ofile "atomselect macro qwikmd_hetero \$QWIKMD::heteromcr"
   
    set macroindex [lsearch -index 0 $QWIKMD::userMacros "QM"]
    if {$macroindex > -1} {
        set macro [lindex $QWIKMD::userMacros $macroindex]

        puts $ofile "atomselect macro [lindex $macro 0] \"\(resname [lindex $macro 1]\)\""
        if {$QWIKMD::prepared == 0} {
            set folder "\$env(QWIKMDTMPDIR)"
        } else {
            set folder "\[file rootname \$QWIKMD::basicGui(workdir,0)\]\/setup"
        }
        set macrofilelist [lindex $macro end]
        set txt [list [lindex $macro 0] [lindex $macro 1] [lindex $macro 1]]
        set filelist [list]
        foreach macrofile $macrofilelist {
            set macrofile [file tail $macrofile]
            lappend filelist "${folder}/$macrofile"
            puts $ofile "lappend QWIKMD::TopList ${folder}/$macrofile"
            set topoindex [lsearch $QWIKMD::TopList "*/$macrofile"]
            set QWIKMD::TopList [lreplace $QWIKMD::TopList $topoindex $topoindex]

            set paraindex [lsearch $QWIKMD::ParameterList "*/$macrofile"]
            if {$paraindex > -1} {
                puts $ofile "lappend QWIKMD::ParameterList ${folder}/$macrofile"
                set QWIKMD::ParameterList [lreplace $QWIKMD::ParameterList $paraindex $paraindex]
            }
        }
        puts $ofile "lappend QWIKMD::userMacros [list [concat $txt [list $filelist]]]"
        set QWIKMD::userMacros [lreplace $QWIKMD::userMacros $macroindex $macroindex]
        puts $ofile "QWIKMD::reviewTopPar 0"
        puts $ofile "QWIKMD::loadTopologies"
    }
    
    set tabid [$QWIKMD::topGui.nbinput index current]
    puts $ofile "\$QWIKMD::topGui.nbinput select $tabid"
    puts $ofile "set QWIKMD::prepared $QWIKMD::prepared"

    puts $ofile "QWIKMD::changeMainTab"
    incr tabid
    puts $ofile "\$QWIKMD::topGui.nbinput.f${tabid}.nb select [$QWIKMD::topGui.nbinput.f${tabid}.nb index current]"
    puts $ofile "QWIKMD::ChangeMdSmd ${tabid}"
    
    if {$QWIKMD::prepared == 0} {
        puts $ofile "set aux \"\[file rootname \$QWIKMD::basicGui(workdir,0)\]_temp\""
        
        set currstr ""
        catch {glob [file rootname $QWIKMD::basicGui(workdir,0)]_temp/*_current.pdb} currstr
        set stfile [lindex [molinfo $QWIKMD::topMol get filename] 0]
        set name "[file tail [file root [lindex $stfile 0] ] ]"
        puts $ofile "set QWIKMD::inputstrct \${aux}/${name}_current.pdb"
        puts $ofile "set QWIKMD::membraneFrame $QWIKMD::membraneFrame"
        puts $ofile "array set QWIKMD::mdProtInfo \{[array get QWIKMD::mdProtInfo]\}"
        puts $ofile "QWIKMD::LoadButt \$QWIKMD::inputstrct"
    } else {
        puts $ofile "set aux \"\[file rootname \$QWIKMD::basicGui(workdir,0)\]\""
        puts $ofile "set QWIKMD::outPath $\{aux\}"
        puts $ofile "cd $\{QWIKMD::outPath\}/run/"
        puts $ofile "set QWIKMD::inputstrct \{$QWIKMD::inputstrct\}"

        puts $ofile "QWIKMD::LoadButt {[lindex $QWIKMD::inputstrct 0] [lindex $QWIKMD::inputstrct 1]}"
    }
    puts $ofile "set QWIKMD::autorename $QWIKMD::autorename"
    ## Remove GUI components from the basic and advGUI arrays. In this way, we ensure compatibility 
    ## if the widget names change  
    set arrayaux ""
    set values [array get QWIKMD::basicGui]
    for {set j 1} {$j < [llength $values]} {incr j 2} {
        lset values $j [split [lindex $values $j] \t]
        set find [regexp {.qwikmd*} [join [lindex $values $j]]]
        if {$find == 0 } {
            lset values $j [join [lindex $values $j]]
            append arrayaux "[lrange $values [expr $j -1] $j] "
        }
    }
    puts $ofile "array set QWIKMD::basicGui \{$arrayaux\}"
    set values [array get QWIKMD::advGui]
    for {set j 1} {$j < [llength $values]} {incr j 2} {
        lset values $j [split [lindex $values $j] \t]
        set find [regexp {.qwikmd*} [join [lindex $values $j]]]
        if {$find == 0 } {
            lset values $j [join [lindex $values $j]]
            append arrayaux "[lrange $values [expr $j -1] $j] "
        }
    }
    puts $ofile "array set QWIKMD::advGui \{$arrayaux\}"
    # if {$QWIKMD::prepared == 1} {
        puts $ofile "array set QWIKMD::chains \{[array get QWIKMD::chains]\}"
        puts $ofile "array set QWIKMD::index_cmb \{[array get QWIKMD::index_cmb] \}"
        puts $ofile "set QWIKMD::delete \{$QWIKMD::delete\}"
    # }

    puts $ofile "array set QWIKMD::mutate \{[array get QWIKMD::mutate]\}"
    puts $ofile "array set QWIKMD::protonate \{[array get QWIKMD::protonate] \}"

    puts $ofile "set QWIKMD::mutindex \{$QWIKMD::mutindex\}"
    puts $ofile "set QWIKMD::protindex \{$QWIKMD::protindex\}"
    puts $ofile "set QWIKMD::renameindex \{$QWIKMD::renameindex\}"
    puts $ofile "array set QWIKMD::dorename \{[array get QWIKMD::dorename]\}"
    puts $ofile "set QWIKMD::atmsRenameLog \{$QWIKMD::atmsRenameLog\}"
    puts $ofile "set QWIKMD::atmsReorderLog \{$QWIKMD::atmsReorderLog\}"
    puts $ofile "set QWIKMD::atmsDeleteLog \{$QWIKMD::atmsDeleteLog\}"
    puts $ofile "set QWIKMD::patchestr \{$QWIKMD::patchestr\}"
    
    #if {$QWIKMD::prepared == 1} {
        puts $ofile "set QWIKMD::state 0"

        if {$QWIKMD::prepared == 1} {
            puts $ofile "set QWIKMD::load 1"
        } else {
            set QWIKMD::prevconfFile $QWIKMD::confFile
        }
        set prevconfList $QWIKMD::prevconfFile
        if {[expr ${tabid} - 1] != [lindex [lindex $QWIKMD::selnotbooks 0] 1] || [$QWIKMD::topGui.nbinput.f${tabid}.nb index current] != [lindex [lindex $QWIKMD::selnotbooks 1] 1]} {
            set prevconfList $QWIKMD::confFile
        }
        puts $ofile "set QWIKMD::prevconfFile \{$prevconfList\}"
        puts $ofile "set QWIKMD::confFile \$QWIKMD::prevconfFile"
        
        if {$tabid == 1} {
            set solvent $QWIKMD::basicGui(solvent,$QWIKMD::run,0)
        } else {
            set solvent $QWIKMD::advGui(solvent,$QWIKMD::run,0)
            if {$QWIKMD::run != "MDFF"} {
                set lines [list]
 
                for {set i 0} {$i < [$QWIKMD::advGui(protocoltb,$QWIKMD::run) size]} {incr i} {
                    lappend lines [$QWIKMD::advGui(protocoltb,$QWIKMD::run) rowcget $i -text]
                }
                puts $ofile "set prtclLines \{$lines\}"
                puts $ofile "for \{set i 0\} \{\$i < \[llength \$prtclLines\]\} \{incr i\} \{"
                puts $ofile "\t\$QWIKMD::advGui(protocoltb,\$QWIKMD::run) insert end \[lindex \$prtclLines \$i\]"
                if {$QWIKMD::prepared == 1} {
                    puts $ofile "\tif \{\[file exists \[lindex \[lindex \$prtclLines \$i\] 0\].dcd\] == 1\} \{"
                    puts $ofile "\t\tincr QWIKMD::state"
                    puts $ofile "\t\}"
                }
                puts $ofile "\}"
            }
        }
        if {$solvent == "Explicit" && $QWIKMD::prepared == 1} {
            puts $ofile "pbc box -center bb -color yellow -width 4"
            puts $ofile "set QWIKMD::pbcInfo \[pbc get -last end -nocheck\]"
        } 
    #}
    
    if {$QWIKMD::run == "SMD"} {
        #puts $ofile "set QWIKMD::smd $QWIKMD::smd"
        if {$QWIKMD::anchorRes != ""} {
            puts $ofile "set QWIKMD::anchorRes \{$QWIKMD::anchorRes\}"
            puts $ofile "set QWIKMD::anchorRessel \{$QWIKMD::anchorRessel\}"
        }
        if {$QWIKMD::pullingRes != ""} {
            puts $ofile "set QWIKMD::pullingRes \{$QWIKMD::pullingRes\}"
            puts $ofile "set QWIKMD::pullingRessel \{$QWIKMD::pullingRessel\}"
        }
        puts $ofile "QWIKMD::checkAnchors"
        
    }

    if {$QWIKMD::run == "MDFF"} {
        puts $ofile "\$QWIKMD::advGui(protocoltb,MDFF) delete 0 end"
        set line [list]
        #make sure that the line is saved as a list of lists
        lappend line [$QWIKMD::advGui(protocoltb,$QWIKMD::run) rowcget 0 -text] 
        puts $ofile "set prtclLines \{$line\}"
        puts $ofile "\$QWIKMD::advGui(protocoltb,MDFF) insert end \[lindex \$prtclLines end\]"
        puts $ofile "set QWIKMD::advGui(mdff,min) $QWIKMD::advGui(mdff,min)"
        puts $ofile "set QWIKMD::advGui(mdff,mdff) $QWIKMD::advGui(mdff,mdff)"
    }

    if {$QWIKMD::run == "QM/MM"} {
        
        set lines [list]
        for {set i 0} {$i < [$QWIKMD::advGui(qmtable) size]} {incr i} {
            lappend lines [$QWIKMD::advGui(qmtable) rowcget $i -text]
        }
        puts $ofile "set prtclLines \{$lines\}"
        puts $ofile "for \{set i 0\} \{\$i < \[llength \$prtclLines\]\} \{incr i\} \{"
        puts $ofile "\t\$QWIKMD::advGui(qmtable) insert end \[lindex \$prtclLines \$i\]"
        puts $ofile "\}"

        set QWIKMD::advGui(qmoptions,crrtprtcl) "all"
        QWIKMD::chgProtoclQMOpt
        puts $ofile "set QWIKMD::advGui(qmoptions,crrtprtcl) all"
        puts $ofile "set i 1"
        puts $ofile "set prtclLines \{$QWIKMD::advGui(qmoptions,ptcqmval,all)\}"
        puts $ofile "foreach line \$prtclLines \{"
        puts $ofile "    \$QWIKMD::advGui(qmoptions,ptcqmwdgt) insert \$i.0 \"\$line\n\""
        puts $ofile "    incr i"
        puts $ofile "\}"
    }
    set tabid [$QWIKMD::topGui.nbinput index current]
    puts $ofile "set QWIKMD::basicGui(live,$tabid) $QWIKMD::basicGui(live,$tabid)"
    if {$QWIKMD::basicGui(live,$tabid) == 0} {
        puts $ofile "set QWIKMD::dcdfreq [expr $QWIKMD::dcdfreq * 10]"
        puts $ofile "set QWIKMD::smdfreq $QWIKMD::smdfreq"
    } 
    puts $ofile "set QWIKMD::maxSteps \{$QWIKMD::maxSteps\}"
    close $ofile
}
######################################################################
##  Proc triggered by the vmd_pick_atom callback
######################################################################
proc QWIKMD::ResidueSelect {args} {
    global vmd_pick_atom
    if {[winfo exists $QWIKMD::selResGui] && $QWIKMD::topMol != "" && $vmd_pick_atom != ""} {
        set table $QWIKMD::selresTable
         
        set atom [atomselect $QWIKMD::topMol "index $vmd_pick_atom"]
        set chain [lindex [$atom get chain] 0]  
        set resid [lindex [$atom get resid] 0] 
        set str "${resid}_$chain"
        $atom delete
        set chaincol [$table getcolumns 2]
        set rescol [$table getcolumns 0]
        set i 0
        
        while { $i < [llength $rescol]} {
            set res [lindex $rescol $i]
            set index "${res}_[lindex $chaincol $i]"
            

            if {$index == $str} {
                
                set sel [$table curselection]
                
                set ind [lsearch $sel $i]
                
                if {$ind > -1} {
                    set sel [lreplace $sel $ind $ind]
                    $QWIKMD::selresTable selection clear 0 end  
                    $QWIKMD::selresTable selection set $sel
                } else {
                    lappend sel $i
                }
                
                if {[llength $sel] > 0 && $ind == -1} {
                    $QWIKMD::selresTable selection set $sel
                    $QWIKMD::selresTable see [lindex $sel end]
                } elseif {[llength $sel] == 0} {
                    $QWIKMD::selresTable selection clear 0 end
                }
                set QWIKMD::selResidSel "Type Selection"
                set QWIKMD::selResidSelIndex [list]
                QWIKMD::rowSelection
                break
            } 
            incr i
        }
    }
}

proc QWIKMD::mean {values} {
    # set a 0.0
    # set total [llength $values]
    # for {set i 0} {$i < $total} {incr i} {
    #     set a [expr $a + [lindex $values $i]]
    # }
    # return [QWIKMD::format4Dec [expr $a / $total ]]
    return [QWIKMD::format4Dec [vecmean $values]]
}

proc QWIKMD::meanSTDV {values} {
    # set sum 0.0
    # set totsum 0.0
    # set total [llength $values]
    # set sum 0.0
    # set stdv 0.0
    # set j 1
    # for {set i 0} {$i < $total} {incr i} {
    #     if {$j == 1} {

    #         set sum [lindex $values $i]
    #         set totsum $sum
    #         set stdv 0.0
    #     } else {
    #         set oldm $sum 
    #         set totsum [expr $totsum + [lindex $values $i]]
    #         set sum [expr $oldm + [expr [expr [lindex $values $i] - $oldm ] /$j]]
    #         set stdv [expr $stdv +  [expr [expr [lindex $values $i] - $oldm] * [expr [lindex $values $i] - $sum ] ]] 
    #     }
    #     incr j
    # }
    # return "[QWIKMD::format4Dec [expr $totsum / $total]] [QWIKMD::format4Dec [expr sqrt($stdv/[expr $total -1])]]" 
    return "[QWIKMD::format4Dec [vecmean $values]] [QWIKMD::format4Dec [vecstddev $values]]"
}
# proc QWIKMD::zoom {W D} {
#   if {$D > 0 && [expr $QWIKMD::maxy - $D] > 0} {
#         set delta $D
#         set afterid [after 200 "$W configure -ymax [expr $QWIKMD::maxy - $D]"]
#     } elseif {$D < 0 && [expr $QWIKMD::maxy - $D] < $QWIKMD::maxy} {
#         set afterid [after 200 "$W configure -ymax [expr $QWIKMD::maxy - $D]"]
#     }
# }

 proc QWIKMD::mincalc {values} {
    set length [llength $values]
    set min [lindex $values 0]
    for {set i 1} {$i < $length} {incr i} {
        if {[lindex $values $i] < $min} {
            set min [lindex $values $i]
        }
    }
    return $min
 }

  proc QWIKMD::maxcalc {values} {
    set length [llength $values]
    set max [lindex $values 0]
    for {set i 1} {$i < $length} {incr i} {
        if {[lindex $values $i] > $max} {
            set max [lindex $values $i]
        }
    }
    return $max
 }
