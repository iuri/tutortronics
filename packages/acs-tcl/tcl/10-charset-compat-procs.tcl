ad_library {
    
    Compatibily procs in case we're not running a version of AOLServer that supports charsets.
    
    @author Rob Mayoff [mayoff@arsdigita.com]
    @author Nada Amin [namin@arsdigita.com]
    @creation-date June 28, 2000
    @cvs-id $Id: 10-charset-compat-procs.tcl,v 1.4 2015/12/04 13:50:10 cvs Exp $
}

set compat_procs [list ns_startcontent ns_encodingfortype]

foreach one_proc $compat_procs {
    if {[llength [info commands $one_proc]] == 0} {
	proc $one_proc {args} { }
    }
}


# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
