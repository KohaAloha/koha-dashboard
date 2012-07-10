package KC::Dashboard;

# Script to create dashboard.koha-community.org
# Copyright chris@bigballofwax.co.nz 2012

our $VERSION = '0.1';

use Dancer;
use Dancer::Plugin::Database;
use strict;
use warnings;
use DBI;
use Template;

my $username;
my $password;

set 'session' => 'Simple';

# set 'template'     => 'template_toolkit';
# set 'logger'       => 'console';
# set 'log'          => 'debug';
set 'show_errors'  => 1;
set 'startup_info' => 1;
set 'warnings'     => 1;

get '/' => sub {
    my $sql =
"SELECT realname,bugs.bug_id,bug_when,short_desc                                            
  FROM bugs_activity,profiles,bugs WHERE bugs_activity.who=profiles.userid
  AND bugs.bug_id=bugs_activity.bug_id AND added='Signed Off' 
  ORDER BY bug_when DESC LIMIT 5";
    my $sth = database->prepare($sql) or die database->errstr;
    $sth->execute or die $sth->errstr;
    my $entries = $sth->fetchall_arrayref;
    $sql =
"select realname,count(*) from bugs_activity,profiles,bugs where bugs_activity.who=profiles.userid and bugs.bug_id=bugs_activity.bug_id and added='Signed Off' and bug_when >= '2012-07-01' and bug_when < '2012-08-01' group by realname,added order by count(*) desc;";
    $sth = database->prepare($sql) or die database->errstr;
    $sth->execute or die $sth->errstr;
    my $stats = $sth->fetchall_arrayref;
    $sql =  "SELECT count(*) as count ,subdate(current_date, 1) as yesterday FROM bugs_activity WHERE date(bug_when) = subdate(current_date, 1);";
    $sth = database->prepare($sql) or die database->errstr;
    $sth->execute or die $sth->errstr;
    my $activity = $sth->fetchrow_hashref();

    template 'show_entries.tt',
      {
        'entries' => $entries,
        'stats'   => $stats,
	'activity' => $activity,
      };
};

get '/bug_status' => sub {
    my $sql =
      "SELECT count(*) as count,bug_status FROM bugs GROUP BY bug_status";
    my $sth = database->prepare($sql) or die database->errstr;
    $sth->execute or die $sth->errstr;

    template 'bug_status.tt',
      { 'status' => $sth->fetchall_hashref('bug_status') };
};

get '/randombug' => sub {
    my $sql =
"SELECT * FROM (SELECT bug_id,short_desc FROM bugs WHERE bug_status NOT in 
    ('CLOSED','RESOLVED','Pushed to Master','Pushed to Stable','VERIFIED', 'Signed Off', 'Passed QA') ) AS bugs2 ORDER BY rand() LIMIT 1";
    my $sth = database->prepare($sql) or die database->errstr;
    $sth->execute or die $sth->errstr;

    template 'randombug.tt', { 'randombug' => $sth->fetchall_arrayref };
};

get '/needsignoff' => sub {
    my $sql = "SELECT bugs.bug_id,short_desc FROM bugs
               WHERE bug_status ='Needs Signoff' ORDER by lastdiffed limit 5;";
    my $sth = database->prepare($sql) or die database->errstr;
    $sth->execute or die $sth->errstr;
    template 'needsignoff.tt', { 'needsignoff' => $sth->fetchall_arrayref };

};

true;
