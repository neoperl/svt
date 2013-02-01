#!/usr/bin/perl -w
use strict;
use Net::SSH::Expect;

open (AF, "host_list") or die "don't open host_list: $!\n";
my @list;
foreach (<AF>) {
        chomp;
        @list=split(/\s/);
        SHUTDOWN("$list[0]","$list[1]","$list[2]","$list[3]");
};
close AF;

sub SHUTDOWN {

        my $host=shift;
        my $user=shift;
        my $password=shift;
        my $wait=shift;
        my $ssh=Net::SSH::Expect->new (
                host=>$host,
                password=>$password,
                user=>$user,
                raw_pty=>1,
                );
        $ssh->debug(0);

        $ssh->run_ssh() or die "SSH process couldn't start: $!";
        sleep 3;
if ($ssh->waitfor('\(yes\/no\)\?', 2)) {
                $ssh->send("yes\n");
        };

        $ssh->waitfor('password', 5);
        $ssh->send("$password");
        $ssh->waitfor("$wait", 2);
#$ssh->exec("stty raw -echo");
        my $cmd=$ssh->exec("init 0");
#       print "$cmd\n\n";
        print "$host: --------------------------------------------------\n";
        $ssh->close();
}
