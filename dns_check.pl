use Net::DNS;

#my $domain=$ARGV[0];
#my $dns_server=$ARGV[1];
my $domain="google.com";
my $dns_server="ns2.google.com";

#PRES();
Separate ("List A_Record");
A_Record();

Separate ("List SOA_Record");
SOA_Record();

#Check_open_dns();
Separate ("List MX_Record");
MX_Records();

Separate ("List NS_Record");
NS_Records();

Separate ("List SPF_Record");
SPF_Record();

Separate ("List AXFR_Record");
#AXFR();

sub Separate {
        my $key=shift;
        print "\n";
        print "--------------------- $key ----------------------------\n\n";
}

sub A_Record {
        my @hosts=qw(www ftp mail dns vpn sslvpn);
        my $res = Net::DNS::Resolver->new;
        foreach my $host (@hosts) {
                my $query_A=$res->search("$host\.$domain");

                if ($query_A) {
                        foreach my $rr ($query_A->answer) {
                        next unless $rr->type eq "A";
                        print "$host\.$domain: ";
                        print $rr->address, "\n";
                }
                } else {
                        warn "Unable to obtain A record : ", $res->errorstring, "\n";
                }
        }
}


sub AXFR {
         print "AXFR records :\n";
         my $res  = Net::DNS::Resolver->new;
         $res->nameservers("$dns_server");
         my @zone = $res->axfr("$domain");
         foreach my $rr (@zone) {
                  $rr->print;
         }
}

sub PRES {
        use Net::DNS::Resolver::Recurse;
        my $pres = Net::DNS::Resolver::Recurse->new;
        $pres->tcp_timeout(2);
        $pres->udp_timeout(2);
        $pres->debug(1);
        my @root_ns = map $_ . '.root-servers.net', 'a'..'m';
        $pres->hints(@root_ns);
        my $packet = $pres->query_dorecursion($domain, "NS");
        print "Parent Nameservers:\n";
        foreach my $pns ($packet->additional) {
                   print $pns->name,"(", $pns->rdatastr,")\n";
        }
}

sub SOA_Record {
        print "SOA record: \n";
        my $res=Net::DNS::Resolver->new;
        my $soa_query = $res->query($domain, 'SOA');
        if ($soa_query) {
                ($soa_query->answer)[0]->print, "\n";
        }
        else  {
            print "SOA record fail. Result:\n",$res->errorstring;
        }
}

sub Check_open_dns {
        print "Checking recursion (open dns server)...\n";
        my @nservers = qw(ns.xtera-ip.com.cn);
        my $rres = Net::DNS::Resolver->new(
                nameservers => [@nservers],
                recurse     => 1,
                debug       => 0,
                );
        my $dest;
        my $r_query = $rres->query($dest,"A");
        my @dest_ips=();
        if ($r_query) {
                foreach my $rrr ($r_query->answer) {
                        next unless $rrr->type eq "A";
                        print "Recursive lookups are ENABLED in ",$rres->nameserver(),": ",$rrr->address, "\n";
                }
        } else {
                warn "OK. Recursive queries are not answered.  Result: ", $rres->errorstring, "\n";
        }
}

sub MX_Records {
        print "MX Records is :\n";
        my $res  = Net::DNS::Resolver->new;
        my @mx   = mx($res, $domain);
        if (@mx) {
               foreach my $rr (@mx) {
                    print $rr->preference, " ", $rr->exchange, "\n";
              }
        } else {
               warn "Can't find MX records for $domain: ", $res->errorstring, "\n";
        }
}

sub NS_Records {
        print "NS Records : \n";
        my $res   = Net::DNS::Resolver->new;
        my $query = $res->query("$domain", "NS");
        if ($query) {
            foreach my $rr (grep { $_->type eq 'NS' } $query->answer) {
                    print $rr->nsdname, "\n";
            }
        }
        else {
            warn "query failed: ", $res->errorstring, "\n";
        }
}

sub Reverse_MX {
        my $ip;
        print "\nChecking Reverse MX Records ...\n";
        my $mx_res = Net::DNS::Resolver->new();
        my $mxanswer = $mx_res->query($ip->reverse_ip(),'PTR');
        if($mxanswer) {
              foreach my $mrr (grep {$_->type eq "PTR" } $mxanswer->answer) {
               print $ip->reverse_ip()," PTR ",$mrr->ptrdname,"\n";
               }


         } else {
          print "MX records not found\n";
         }
}

sub SPF_Record {
        print "SPF Records is : \n";
        #my $domain=shift;
        my $res=Net::DNS::Resolver->new();
        my $spf_query=$res->query($domain,"TXT");
        if ($spf_query) {
                foreach my $rr ($spf_query->answer) {
                        print "SPF record ok: ",$rr->txtdata, "\n";
                }
        }
        else {
                warn "unable to get SPF record : ", $res->errorstring, "\n";       }
}
