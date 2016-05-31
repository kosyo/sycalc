use strict;
use Socket;
use Data::Dumper;

sub ParseExpression($)
{
    my($line) = @_;
    my @arr = $line =~ m/\d+|\+|\*\*|\*|\/|-/g;
    my $expr = join(",", @arr) . "\n";
    return $expr;
}

sub StartClient()
{
    my $host = "localhost";
    my $port = 5000;

    socket(F, PF_INET, SOCK_STREAM, getprotobyname('tcp')) || die $!;
    my $internet_addr = inet_aton($host)
        or die "Couldn't convert  into an Internet address: $!\n";
    my $sin = sockaddr_in($port, $internet_addr);

    connect(F, $sin)
        or die "Couldn't connect to $host:$port: $!\n";

    my $old_fh = select(F); 
    $| = 1;                # don't buffer output
    select($old_fh);
    my $line = <STDIN>;

    my $expr = ParseExpression($line);
    syswrite F, $expr, length $expr;
    my $l = <F>;
    print $l;

    close(F);

}

StartClient();
