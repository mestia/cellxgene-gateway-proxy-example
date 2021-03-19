#!/usr/bin/perl
use 5.20.0;
use warnings;

my $group = $ARGV[0] // die "need a group name\n";

my $apache_template = '/etc/cellxgene_templates/apache.conf';
my $systemd_template = '/etc/cellxgene_templates/systemd.service';
my $mapping = '/etc/cellxgene_templates/group_to_port.map';

my $dstconf = '/etc/apache2/sites-available/cellxgene/'."$group".'.conf';
my $dstservice = '/etc/systemd/system/cellxgene_'."$group".'.service';
my $index = '/var/www/index.html';

my $tmpconf = '/tmp/'."$group".'.conf';
my $tmpservice = '/tmp/'."$group".'.service';

sub readtemplate {
    my $file = shift;
    open (my $fd, "<", $file) or die "Can't open file $file, $!";
    my @content = <$fd>;
    close $fd;
    return @content;
    return;
}

my @match = grep {/$group/} readtemplate($mapping);
die "fix your mapping: $mapping, found multiple matches!\n" if scalar(@match) > 1;
die "fix your mapping: $mapping, found zero matches!\n" if scalar(@match) == 0;
my $port = (split(/:/,$match[0]))[1];
die "Can't find port for group $group" if ! $port;

sub gen_conf {
    my $file = shift;
    my @result;
    for my $str (readtemplate($file)) {
        chomp ($port,$group);
        $str =~ s/\<group\>/$group/g;
        $str =~ s/\<PORT\>/$port/g;
        push @result,$str;
    }
    return \@result;
    return;
}

sub write_conf {
    my ($file,$config) = @_;
    #we expect array here
    return if ref($config) ne 'ARRAY';
    open (my $fd,">",$file) or die "can't write to file $file, $!";
    say "created $file";
    print $fd @$config;
    close $fd;
}

sub update_index{
    my $file = shift;
    my @result;
    my $newlink = "\t\t".'<li><a href="/'.$group.'/">'.$group.'</a></li>';
    for my $str (readtemplate($file)) {
        if ($str =~ m/$group/) {
            say "the group already exist in $index";
            return;
        }
        push @result,$newlink."\n" if $str =~ m/\s+<!--new_links_go_here-->$/;
        push @result,$str;
    }
    return \@result;
    return;

}

write_conf($dstconf,gen_conf($apache_template));
write_conf($dstservice,gen_conf($systemd_template));
write_conf($index,update_index($index));

my $error = `systemctl daemon-reload`;
$error = `service apache2 reload`;
say "$error" if $error;
say " - add cellxgeneUser to the new $group";
say " - create the corresponding share /share/cellxgene/$group";
