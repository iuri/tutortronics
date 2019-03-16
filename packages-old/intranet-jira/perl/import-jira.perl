#!/usr/bin/perl -w

# --------------------------------------------------------
#
# import-jira
#
# ]project-open[ ERP/Project Management System
# (c) 2008 - 2010 ]project-open[
# frank.bergmann@project-open.com
#
# --------------------------------------------------------

exit(0);

use Switch;
use DBI;
use Data::Dumper;
use JIRA::REST;
use Getopt::Long;

# --------------------------------------------------------
# Default JIRA Connection
# Enter specific values in order to overwrite parameter values set in ]po[.
#
$debug = 3;						# Debug? 0=no output, 10=very verbose
$jira_prefix = "";					# "JIRA" - unique prefix for server
$jira_host = "";					# "mail.your-server.com" - JIRA server of the mailbox
$jira_user = "";					# "mailbox\@your-server.com" - you need to quote the at-sign
$jira_pwd = "";						# "secret" - JIRA password
$jira_nocreate_p = 0;					# 0=normal operations, 1=don't create tickets
$jira_import_users_p = -1;				# 1=Import new users that appear in Jira JSON

# --------------------------------------------------------
# Database Connection Parameters
#
# Information about the ]po[ database
$instance = getpwuid( $< );;				# The name of the database instance.
$db_username = "$instance";				# By default the same as the instance.
$db_pwd = "";						# The DB password. Empty by default.
$db_datasource = "dbi:Pg:dbname=$instance";		# How to identify the database

# --------------------------------------------------------
# Check for command line options
#
my $json_file = "";
my $result = GetOptions (
    "file=s"     => \$json_file,
    "debug=i"    => \$debug,
    "no-create"  => \$jira_nocreate_p,
    "host=s"     => \$jira_host,
    "prefix=s"   => \$jira_prefix,
    "user=s"     => \$jira_user,
    "password=s" => \$jira_pwd
    ) or die "Usage:\n\nimport-jira.perl --debug 3 --host projop.atlassian.net --user projop --password secret\n\n";


# --------------------------------------------------------
# Establish the database connection
# The parameters are defined in common_constants.pm
$dbh = DBI->connect($db_datasource, $db_username, $db_pwd, {pg_enable_utf8 => 1, PrintWarn => 0, PrintError => 1}) ||
    die "import-jira: Unable to connect to database.\n";


# --------------------------------------------------------
# Get parameters from database
#
if ("" eq $jira_prefix) {
    $sth = $dbh->prepare("SELECT attr_value FROM apm_parameters ap, apm_parameter_values apv WHERE ap.parameter_id = apv.parameter_id and ap.package_key = 'intranet-jira' and ap.parameter_name = 'JiraPrefix'");
    $sth->execute() || die "import-jira: Unable to execute SQL statement.\n";
    $row = $sth->fetchrow_hashref;
    $jira_prefix = $row->{attr_value};
}

if ("" eq $jira_host) {
    $sth = $dbh->prepare("SELECT attr_value FROM apm_parameters ap, apm_parameter_values apv WHERE ap.parameter_id = apv.parameter_id and ap.package_key = 'intranet-jira' and ap.parameter_name = 'JiraHost'");
    $sth->execute() || die "import-jira: Unable to execute SQL statement.\n";
    $row = $sth->fetchrow_hashref;
    $jira_host = $row->{attr_value};
}

if ("" eq $jira_user) {
    $sth = $dbh->prepare("SELECT attr_value FROM apm_parameters ap, apm_parameter_values apv WHERE ap.parameter_id = apv.parameter_id and ap.package_key = 'intranet-jira' and ap.parameter_name = 'JiraUser'");
    $sth->execute() || die "import-jira: Unable to execute SQL statement.\n";
    $row = $sth->fetchrow_hashref;
    $jira_user = $row->{attr_value};
}

if ("" eq $jira_pwd) {
    $sth = $dbh->prepare("SELECT attr_value FROM apm_parameters ap, apm_parameter_values apv WHERE ap.parameter_id = apv.parameter_id and ap.package_key = 'intranet-jira' and ap.parameter_name = 'JiraPwd'");
    $sth->execute() || die "import-jira: Unable to execute SQL statement.\n";
    $row = $sth->fetchrow_hashref;
    $jira_pwd = $row->{attr_value};
}

if (-1 eq $jira_import_users_p) {
    $sth = $dbh->prepare("SELECT attr_value FROM apm_parameters ap, apm_parameter_values apv WHERE ap.parameter_id = apv.parameter_id and ap.package_key = 'intranet-jira' and ap.parameter_name = 'ImportJiraUsersP'");
    $sth->execute() || die "import-jira: Unable to execute SQL statement.\n";
    $row = $sth->fetchrow_hashref;
    $import_p = $row->{attr_value};
    $jira_import_users_p = $import_p;
}
if (!defined $import_p || -1 eq $jira_import_users_p) { $jira_import_users_p = 0; } # Default: Don't import users



# --------------------------------------------------------
# Get the "internal" customer - represents the company itself
#
$sth = $dbh->prepare("SELECT company_id as company_id from im_companies where company_path = 'internal'");
$sth->execute() || die "import-jira: Unable to execute SQL statement.\n";
$row = $sth->fetchrow_hashref;
my $internal_customer_id = $row->{company_id};
if (!defined $internal_customer_id) { die "import-jira: Did not find the 'internal customer'\n" };




print "import-jira: host=$jira_host, user=$jira_user, pwd=$jira_pwd\n" if ($debug > 9);
die "import-jira.perl: You need to define a jira_host" if ("" eq $jira_host);
die "import-jira.perl: You need to define a jira_user" if ("" eq $jira_user);
die "import-jira.perl: You need to define a jira_pwd" if ("" eq $jira_pwd);


# --------------------------------------------------------
# Import/Update users that are not yet defined in ]po[
# --------------------------------------------------------

sub get_user_by_email {
    my ($email) = @_;

    # Deal with the creation_user
    my $user_id = 0;
    if (defined $email) {
	$sth = $dbh->prepare('SELECT party_id from parties where lower(trim(email)) = lower(trim($1))');
	$sth->execute($email) || die "import-jira: get_user_by_email: Unable to execute SQL statement.\n";
	$row = $sth->fetchrow_hashref;
	$user_id = $row->{party_id};
    }
    if (!defined $user_id) { $user_id = 0; }
    return $user_id;
    
}

sub get_user {
    my ($json) = @_;
    my $email = $json->{emailAddress};
    if (!defined $email) { return 0; }
    print "import-jira: get_user: json=", Dumper($json), "\n" if ($debug >= 5);

    # Deal with the creation_user
    my $user_id = 0;
    if (defined $email) {
	$sth = $dbh->prepare('SELECT party_id from parties where lower(trim(email)) = lower(trim($1))');
	$sth->execute($email) || die "import-jira: get_user_by_email: Unable to execute SQL statement.\n";
	$row = $sth->fetchrow_hashref;
	$user_id = $row->{party_id};
    }

    my $name = $json->{name};
    if (!defined $user_id || 0 eq $user_id) { 
	$sth = $dbh->prepare('SELECT min(user_id) as user_id from users where lower(trim(username)) = lower(trim($1))');
	$sth->execute($name) || die "import-jira: get_user_by_email: Unable to execute SQL statement.\n";
	$row = $sth->fetchrow_hashref;
	$user_id = $row->{user_id};
    }

    $display_name = $json->{displayName};
    if ($display_name =~ /^([a-zA-Z])+ ([a-zA-Z])+$/) {
	$sth = $dbh->prepare('SELECT min(person_id) as person_id from persons where lower(first_names) = lower($1) and lower(last_name) = lower($2)');
	$sth->execute($1, $2) || die "import-jira: get_user_by_email: Unable to execute SQL statement.\n";
	$row = $sth->fetchrow_hashref;
	$user_id = $row->{person_id};
    }

    if (!defined $user_id) { $user_id = 0; }
    print "import-jira: get_user: email=$email, name=$name, display_name=$display_name => user_id=$user_id\n" if ($debug >= 3);
    return $user_id;
}


sub process_user {
    my ($json) = @_;

    # Should we import users from Jira?
    if (!$jira_import_users_p) { return; }

    # ToDo: Create a user in ]po[ if it doesn't exist yet
}

# --------------------------------------------------------
# Import Comments to a ticket
# --------------------------------------------------------

sub process_comment {
    my ($ticket_id, $json) = @_;
    my $comment_id = $json->{id};
    if (!defined $comment_id) { 
	print "import-jira: process_comment: ticket_id=$ticket_id: undefined comment\n";
	return; 
    }

    # Check if the topic already exists
    $sth = $dbh->prepare("SELECT count(*) as cnt from im_forum_topics where object_id = $ticket_id and jira_comment_id = $comment_id");
    $sth->execute() || die "import-jira: Unable to execute SQL statement.\n";
    $row = $sth->fetchrow_hashref;
    my $comment_exists_p = $row->{cnt};
    if ($comment_exists_p) { 
	print "import-jira: process_comment: ticket_id=$ticket_id, comment_id=$comment_id: Already exists\n" if ($debug >= 3);
	return; 
    }

    # Extract the comment fields
    my $comment_creation_date = $json->{created};
    my $comment_last_updated_date = $json->{updated};
    my $comment_author_id = get_user($json->{author});
    my $comment_update_author_id = get_user($json->{updateAuthor});
    my $comment_body = $json->{body};
    my $comment_subject = (split /\n/, $comment_body)[0];

    # Get the next topic ID
    $sth = $dbh->prepare("SELECT nextval('im_forum_topics_seq') as topic_id");
    $sth->execute() || die "import-jira: Unable to execute SQL statement.\n";
    $row = $sth->fetchrow_hashref;
    my $topic_id = $row->{topic_id};
    my $topic_type_id = 1108; # Note
    my $topic_status_id = 1200; # open

    # Check for the parent topic
    $sth = $dbh->prepare("SELECT min(topic_id) as topic_id from im_forum_topics where object_id = $ticket_id");
    $sth->execute() || die "import-jira: Unable to execute SQL statement.\n";
    $row = $sth->fetchrow_hashref;
    my $topic_parent_id = $row->{topic_id};
    if (!defined $topic_parent_id) { $topic_parent_id = "NULL"; }

    # Insert a Forum Topic into the ticket container
    print "import-jira: process_comment: About to create a new comment with topic_id=$topic_id\n" if ($debug >= 1);
    $sql = '
		insert into im_forum_topics (
			topic_id, object_id, parent_id,
			topic_type_id, topic_status_id, owner_id,
			jira_comment_id,
			subject, message
		) values ($1, $2, $3, $4, $5, $6, $7, $8, $9)
    ';
    $sth = $dbh->prepare($sql);
    $sth->execute($topic_id, $ticket_id, $topic_parent_id, $topic_type_id, $topic_status_id, $comment_author_id, $comment_id, $comment_subject, $comment_body);
}

# --------------------------------------------------------
# Import/Update a single Ticket
# --------------------------------------------------------

sub process_incident {
    my ($json) = @_;

    print "import-jira: process_incident: json=", Dumper($json), "\n" if ($debug >= 7);

    # Import users if necessary
    process_user($json->{fields}->{reporter});
    process_user($json->{fields}->{creator});
    process_user($json->{fields}->{assignee});

    # Ticket Fields
    my $incident_jira_id = $json->{id};
    my $incident_nr = $json->{key};
    my $incident_name = $json->{fields}->{summary};
    my $incident_project_id = $json->{fields}->{project}->{id};
    my $incident_project_key = $json->{fields}->{project}->{key};
    my $incident_project_name = $json->{fields}->{project}->{name};
    my $incident_issuestatus_id = $json->{fields}->{status}->{id};
    my $incident_issuestatus_name = $json->{fields}->{status}->{name};
    my $incident_issuetype_id = $json->{fields}->{issuetype}->{id};
    my $incident_issuetype_name = $json->{fields}->{issuetype}->{name};
    my $incident_creation_date = $json->{fields}->{created};
    my $incident_priority_id = $json->{fields}->{priority}->{id};
    my $incident_priority_name = $json->{fields}->{priority}->{name};
    my $incident_resolution_name = $json->{fields}->{resolution}->{name};
    my $incident_due_date = $json->{fields}->{duedate};
    my $incident_progress_progress = $json->{fields}->{progress}->{progress};
    my $incident_progress_total = $json->{fields}->{progress}->{total};


    # Use the first line of the incident description as a subject line
    my $incident_subject = (split /\n/, $incident_name)[0];
    my $incident_body = $incident_name;


    # Incident key - every incident should have one, otherwise we're at the wrong party.
    if (!defined $incident_nr) { die "import-jira: Found an incident without key - wrong data\n" };
    print "import-jira: process_incident: key=",$incident_nr, "\n" if ($debug >= 2);

    # SLA - The project to which the ticket belongs.
    if (!defined $incident_project_key) { die "import-jira: Found an incident without project key - wrong data\n" };
    print "import-jira: process_incident: incident_project_key=",$incident_project_key, "\n" if ($debug >= 2);

    $sth = $dbh->prepare('SELECT min(project_id) as project_id from im_projects where jira_prefix = $1 and jira_project_key = $2');
    my $rv = $sth->execute($jira_prefix, $incident_project_key) || die "import-jira: Unable to execute SQL statement.\n";
    $row = $sth->fetchrow_hashref;
    my $ticket_project_id = $row->{project_id};

    if (!defined $ticket_project_id) {
	# Didn't find the ticket project, so let's create one!
	print "import-jira: before im_project__new\n" if ($debug >= 1);
	my $jira_project_name = "$jira_prefix-$incident_project_name";
	my $jira_project_nr = "jira_prefix-$incident_project_key";
	$sth = $dbh->prepare('
		SELECT im_project__new (
			nextval(\'t_acs_object_id_seq\')::integer, 	-- p_ticket_id
			\'im_project\'::varchar,			-- object_type
			now(),						-- creation_date
			0::integer,					-- creation_user
			\'0.0.0.0\'::varchar,				-- creation_ip
			null::integer,					-- (security) context_id
	
			$1::varchar,					-- project_name
			$2::varchar,					-- project_nr
			$3::varchar,					-- project_path
			null,						-- parent_id
			$4::integer,					-- customer_id
			2502,						-- Ticket Container
			76						-- open
		) as ticket_project_id
        ');
	$sth->execute($jira_project_name, $jira_project_nr, $incident_project_key, $internal_customer_id) || die "import-jira: Unable to create project.\n";
	$row = $sth->fetchrow_hashref;
	$ticket_project_id = $row->{ticket_project_id};
	$sth = $dbh->prepare("
		update im_projects set
			jira_prefix		= '$jira_prefix',
			jira_project_key	= '$incident_project_key',
			jira_project_id		= $incident_project_id,
			start_date		= now(),
			end_date		= now() + '1 year'::interval
		where	project_id		= $ticket_project_id;
        ");
	$sth->execute() || die "import-jira: Unable to execute SQL statement: \n$sql\n";
    }

    # Get the customer of the selected project
    $sth = $dbh->prepare("SELECT company_id as company_id from im_projects where project_id = '$ticket_project_id'");
    $sth->execute() || die "import-jira: Unable to execute SQL statement.\n";
    $row = $sth->fetchrow_hashref;
    my $ticket_customer_id = $row->{company_id};

    # Deal with the creation_user
    my $ticket_creation_user_id = get_user($json->{fields}->{creator});
    my $ticket_customer_contact_id = get_user($json->{fields}->{reporter});
    my $ticket_assignee_id = get_user($json->{fields}->{assignee});

    # ------------------------------------------------------------
    # Deal with ticket type
    #
    $sth = $dbh->prepare('SELECT min(category_id) from im_categories where category_type = \'Intranet Ticket Type\' and lower(trim(category)) = lower(trim($1))');
    $sth->execute($incident_issuetype_name) || die "import-jira: Unable to execute SQL statement.\n";
    $row = $sth->fetchrow_hashref;
    my $ticket_type_id = $row->{category_id};
    if (!defined $ticket_type_id) {
	$sth = $dbh->prepare('SELECT min(category_id) from im_categories where category_type = \'Intranet Ticket Type\' and aux_int1 = lower(trim($1))::integer');
	$sth->execute($incident_issuetype_id) || die "import-jira: Unable to execute SQL statement.\n";
	$row = $sth->fetchrow_hashref;
	$ticket_type_id = $row->{category_id};
    }
    if (!defined $ticket_type_id) {
	$sth = $dbh->prepare('SELECT min(category_id) from im_categories where category_type = \'Intranet Ticket Type\' and lower(trim(aux_string1)) = lower(trim($1))');
	$sth->execute($incident_issuetype_name) || die "import-jira: Unable to execute SQL statement.\n";
	$row = $sth->fetchrow_hashref;
	$ticket_type_id = $row->{category_id};
    }
    if (!defined $ticket_type_id) {
	switch ($incident_issuetype_name) {
	    case "Bug" { $ticket_type_id = 30110; } # Bug Request
	    case "Epic" { $ticket_type_id = 30116; } # Feature Request
	    case "Improvement" { $ticket_type_id = 30116; } # Feature Request
	    case "New Feature" { $ticket_type_id = 30116; } # Feature Request
	    case "Story" { $ticket_type_id = 30116; } # Feature Request
	    case "Task" { $ticket_type_id = 30116; } # Feature Request
	    case "Sub-task" { $ticket_type_id = 30116; } # Feature Request
	    else { 
		warn "import-jira: Didn't find issuetype='$incident_issuetype_name', using 'Feature Request' as default\n";
		$ticket_type_id = 30116; 
	    }
	}
    }


    # ------------------------------------------------------------
    # Deal with ticket status
    #
    $sth = $dbh->prepare('SELECT min(category_id) from im_categories where category_type = \'Intranet Ticket Status\' and lower(trim(category)) = lower(trim($1))');
    $sth->execute($incident_issuestatus_name) || die "import-jira: Unable to execute SQL statement.\n";
    $row = $sth->fetchrow_hashref;
    my $ticket_status_id = $row->{category_id};
    if (!defined $ticket_status_id) {
	$sth = $dbh->prepare('SELECT min(category_id) from im_categories where category_type = \'Intranet Ticket Status\' and aux_int1 = lower(trim($1))::integer');
	$sth->execute($incident_issuestatus_id) || die "import-jira: Unable to execute SQL statement.\n";
	$row = $sth->fetchrow_hashref;
	$ticket_status_id = $row->{category_id};
    }
    if (!defined $ticket_status_id) {
	$sth = $dbh->prepare('SELECT min(category_id) from im_categories where category_type = \'Intranet Ticket Status\' and lower(trim(aux_string1)) = lower(trim($1))');
	$sth->execute($incident_issuestatus_name) || die "import-jira: Unable to execute SQL statement.\n";
	$row = $sth->fetchrow_hashref;
	$ticket_status_id = $row->{category_id};
    }
    if (!defined $ticket_status_id) {
	switch ($incident_issuestatus_name) {
	    case "Build Broken" { $ticket_status_id = 30000; } # Open
	    case "Building" { $ticket_status_id = 30000; } # Open
	    case "Closed" { $ticket_status_id = 30001; } # Closed
	    case "Done" { $ticket_status_id = 30001; } # Closed
	    case "In Progress" { $ticket_status_id = 30020; } # Executing
	    case "No Category" { $ticket_status_id = 30000; } # Open
	    case "Open" { $ticket_status_id = 30000; } # Open
	    case "Reopened" { $ticket_status_id = 30000; } # Open
	    case "Resolved" { $ticket_status_id = 30096; } # Resolved
	    case "Test on Dev" { $ticket_status_id = 30000; } # Open
	    case "Test on Staging" { $ticket_status_id = 30000; } # Open
	    case "To Do" { $ticket_status_id = 30000; } # Open
	    case "User Acceptance" { $ticket_status_id = 30000; } # Open
	    else { 
		warn "import-jira: Didn't find issuestatus='$incident_issuestatus_name', using 'open' as default\n";
		$ticket_status_id = 30000; 
	    }
	}
    }


    # ------------------------------------------------------------
    # Deal with ticket priority
    #
    $sth = $dbh->prepare('SELECT min(category_id) from im_categories where category_type = \'Intranet Ticket Priority\' and lower(trim(category)) = lower(trim($1))');
    $sth->execute($incident_priority_name) || die "import-jira: Unable to execute SQL statement.\n";
    $row = $sth->fetchrow_hashref;
    my $ticket_priority_id = $row->{category_id};
    if (!defined $ticket_priority_id) {
	$sth = $dbh->prepare('SELECT min(category_id) from im_categories where category_type = \'Intranet Ticket Priority\' and aux_int1 = lower(trim($1))::integer');
	$sth->execute($incident_priority_id) || die "import-jira: Unable to execute SQL statement.\n";
	$row = $sth->fetchrow_hashref;
	$ticket_priority_id = $row->{category_id};
    }
    if (!defined $ticket_priority_id) {
	$sth = $dbh->prepare('SELECT min(category_id) from im_categories where category_type = \'Intranet Ticket Priority\' and lower(trim(aux_string1)) = lower(trim($1))');
	$sth->execute($incident_priority_name) || die "import-jira: Unable to execute SQL statement.\n";
	$row = $sth->fetchrow_hashref;
	$ticket_priority_id = $row->{category_id};
    }
    if (!defined $ticket_priority_id) {
	switch ($incident_priority_name) {
	    case "Highest" { $ticket_priority_id = 30201; } # 1 - Highest
	    case "High" { $ticket_priority_id = 30203; } # 3 - High
	    case "Normal" { $ticket_priority_id = 30205; } # 5 - Medium
	    case "Medium" { $ticket_priority_id = 30205; } # 5 - Medium
	    case "Low" { $ticket_priority_id = 30207; } # 7 - Low
	    case "Lowest" { $ticket_priority_id = 30205; } # 9 - Lowest
	    else {
		warn "import-jira: Didn't find priority='$incident_priority_name', using '5 - Medium' as default\n";
		$ticket_priority_id = 30205; # 5 - Medium
	    }
	}
    }



    # ------------------------------------------------------------
    # Deal with ticket resolution
    #
    my $ticket_resolution_type_id = "NULL";
    if (defined $incident_resolution_name) {
	$sth = $dbh->prepare('SELECT min(category_id) from im_categories where category_type = \'Intranet Ticket Resolution Type\' and lower(trim(category)) = lower(trim($1))');
	$sth->execute($incident_resolution_name) || die "import-jira: Unable to execute SQL statement.\n";
	$row = $sth->fetchrow_hashref;
	my $ticket_resolution_type_id = $row->{category_id};
    }
    if (!defined $ticket_resolution_type_id) { $ticket_resolution_type_id = "NULL"; }

# ToDo:
#    my $incident_jira_id = $json->{id};
#    my $incident_due_date = $json->{fields}->{duedate};
#    my $incident_progress_progress = $json->{fields}->{progress}->{progress};
#    my $incident_progress_total = $json->{fields}->{progress}->{total};

   
    # --------------------------------------------------------
    # Insert the basis ticket into the SQL database
    #
    # Duplicate check
    $sth = $dbh->prepare('SELECT min(project_id) as ticket_id from im_projects where project_nr = $1 and project_type_id = 101');
    $sth->execute($incident_nr) || die "import-jira: Unable to execute SQL statement.\n";
    $row = $sth->fetchrow_hashref;
    my $ticket_id = $row->{ticket_id};
    my $ticket_new_p = 0;
    if (!defined $ticket_id) {
	print "import-jira: before im_ticket__new: incident_name=$incident_name, incident_nr=$incident_nr, ticket_customer_id=$ticket_customer_id\n" if ($debug >= 1);
	$sth = $dbh->prepare('
		SELECT im_ticket__new (
			nextval(\'t_acs_object_id_seq\')::integer,	-- p_ticket_id
			\'im_ticket\'::varchar,				-- object_type
			$1::timestamptz,				-- creation_date
			$2::integer,					-- creation_user
			\'0.0.0.0\'::varchar,				-- creation_ip
			null::integer,					-- (security) context_id
			$3::varchar, $4::varchar, $5::integer, $6::integer, $7::integer
		) as ticket_id
        ');
	$sth->execute($incident_creation_date, $ticket_creation_user_id, $incident_subject, $incident_nr, $ticket_customer_id, $ticket_type_id, $ticket_status_id) || 
	    die "import-jira: Unable to execute SQL statement.\n";
	$row = $sth->fetchrow_hashref;
	$ticket_id = $row->{ticket_id};
	$ticket_new_p = 1;
    }
    
    # Update ticket field stored in the im_tickets table
    print "import-jira: before im_tickets update\n" if ($debug >= 1);
    $sql = "
		update im_tickets set
			ticket_type_id			= '$ticket_type_id'::integer,
			ticket_status_id		= '$ticket_status_id'::integer,
			ticket_customer_contact_id	= '$ticket_customer_contact_id',
			ticket_prio_id			= '$ticket_priority_id'::integer,
			ticket_assignee_id		= '$ticket_assignee_id'::integer,
			ticket_resolution_type_id	= $ticket_resolution_type_id
		where
			ticket_id = $ticket_id
    ";
    $sth = $dbh->prepare($sql);
    $sth->execute() || die "import-jira: Unable to execute SQL statement: \n$sql\n";

    # Update ticket field stored in the im_projects table
    print "import-jira: before im_projects update\n" if ($debug >= 1);
    $sth = $dbh->prepare('
		update im_projects set
			project_name		= $1,
			project_nr		= $2,
			parent_id		= $3::integer,
			description		= $4
		where	project_id = $5;
    ');
    $sth->execute($incident_subject, $incident_nr, $ticket_project_id, $incident_body, $ticket_id) || 
	die "import-jira: Unable to execute SQL statement: \n$sql\n";

    # A new topic needs to have the text as a comment
    if ($ticket_new_p) {
	# Get the next topic ID
	$sth = $dbh->prepare("SELECT nextval('im_forum_topics_seq') as topic_id");
	$sth->execute() || die "import-jira: Unable to execute SQL statement.\n";
	$row = $sth->fetchrow_hashref;
	my $topic_id = $row->{topic_id};
	my $topic_type_id = 1108; # Note
	my $topic_status_id = 1200; # open
	
	# Insert a Forum Topic into the ticket container
	print "import-jira: process_comment: About to create the first topic_id=$topic_id\n" if ($debug >= 1);
	$sql = 'insert into im_forum_topics (
			topic_id, object_id, parent_id,
			topic_type_id, topic_status_id, owner_id,
			subject, message
		) values ($1, $2, null, $3, $4, $5, $6, $7)
        ';
	$sth = $dbh->prepare($sql);
	$sth->execute($topic_id, $ticket_id, $topic_type_id, $topic_status_id, $ticket_creation_user_id, $incident_subject, $incident_body);
    } else {
	print "import-jira: process_comment: Ticket is not new, so we don't generate an extra forum topic.\n" if ($debug >= 1);	
    }


    # --------------------------------------------------------
    # Add the customer contact to the list of "members" of the ticket
    #
    if (0 ne $ticket_customer_contact_id) {
	print "import-jira: before im_biz_object_member__new\n" if ($debug >= 1);
	$sth = $dbh->prepare("select im_biz_object_member__new(null, 'im_biz_object_member', $ticket_id, '$ticket_customer_contact_id', 1300, 0, '0.0.0.0')");
	$sth->execute() || die "import-jira: Unable to execute SQL statement: \n$sql\n";
    }
    if (0 ne $ticket_creation_user_id) {
	print "import-jira: before im_biz_object_member__new\n" if ($debug >= 1);
	$sth = $dbh->prepare("select im_biz_object_member__new(null, 'im_biz_object_member', $ticket_id, '$ticket_creation_user_id', 1300, 0, '0.0.0.0')");
	$sth->execute() || die "import-jira: Unable to execute SQL statement: \n$sql\n";
    }
    if (0 ne $ticket_assignee_id) {
	print "import-jira: before im_biz_object_member__new\n" if ($debug >= 1);
	$sth = $dbh->prepare("select im_biz_object_member__new(null, 'im_biz_object_member', $ticket_id, '$ticket_assignee_id', 1300, 0, '0.0.0.0')");
	$sth->execute() || die "import-jira: Unable to execute SQL statement: \n$sql\n";
    }


    # --------------------------------------------------------
    # Add Forum Topics for Jira Comments

    my $comments = $json->{fields}->{comment}->{comments};
    for my $comment (@$comments) {
	print Dumper($comment), "\n" if ($debug > 7);
	process_comment($ticket_id, $comment);
    }

}




# --------------------------------------------------------
# Loop for each of the mails
#
if ("" ne $json_file) {
    # The user specified a file at the command line
    print "import-jira: Reading input from json_file='$json_file'\n" if ($debug >= 1);
    open my $fh, '<', $json_file or die "import-jira: Error opening $json_file: $!";
    my $json = do { local $/; <$fh> };
    process_incident($json);

} else {

    # Establish a connection to the JIRA server
    my $jira = JIRA::REST->new($jira_host, $jira_user, $jira_pwd);
#    my $issue = $jira->GET("/issue/JAGPIM-6");
#    print "Found issue $issue->{key}\n";
#    print "import-jira: json=", Dumper($issue), "\n";
#    process_incident($issue_json);

    my $search = $jira->GET("/search?jql=");
    foreach my $issue (@{$search->{issues}}) {
	print "import-jira: Found issue $issue->{key}\n";
	process_incident($issue);
    }

}

# --------------------------------------------------------
# Close connections to the DB and exit
#
$sth->finish;
warn $DBI::errstr if $DBI::err;
$dbh->disconnect || warn "Disconnection failed: $DBI::errstr\n";
exit(0);
