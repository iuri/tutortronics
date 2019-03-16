ad_library {

    Set up a scheduled process to send out email messages.

    @cvs-id $Id: acs-messaging-init.tcl,v 1.4 2015/12/04 13:50:05 cvs Exp $
    @author John Prevost <jmp@arsdigita.com>
    @creation-date 2000-10-28

}

# Schedule every 15 minutes
ad_schedule_proc -thread t 907 acs_messaging_process_queue


# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
