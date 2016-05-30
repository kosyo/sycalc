use strict;
use Socket;
use Storable;
use Data::Dumper;
use Fcntl;
my $operator_precedence_table = {
        '+' => {p => 1, a => 'l'},
        '-' => {p => 1, a => 'l'},
        '*' => {p => 2, a => 'l'},
        '/' => {p => 2, a => 'l'},
        '**' => {p => 3, a => 'r'},
};

sub CheckInput(@)
{
    my (@arr) =  @_;
    my $i = 0;
    for my $el (@arr)
    {
        if(($i != 0 || $el !~ m/^\d+$/) && ($el !~ m/^\d+$/ && !defined $$operator_precedence_table{$el}
                || (defined $$operator_precedence_table{$el} && $arr[$i - 1] !~ m/^\d+$/)
                || ($el =~ m/^\d+$/ && $arr[$i - 1] =~ m/^\d+$/)))
        {
            return 1;
        }
        $i++;
    }
    return 0;

}
sub ShuntingYardCalc(@)
{
    my (@arr) =  @_;

    my (@nums, @ops, $sum);
    my $j = 0;
    while(@arr)
    {   
        push @nums, pop @arr;
        if($j != 0 && ($$operator_precedence_table{$arr[ @arr - 1]}{p} < $$operator_precedence_table{$ops[@ops - 1]}{p} ))
        {
            do
            {
                my $num1 = pop @nums;
                my $num2 = pop @nums;
                my $op = pop @ops;
                $sum = eval("$num1 $op $num2");
                print "sum is: $sum";
                push @nums, $sum;
            } while($$operator_precedence_table{$ops[@ops - 1]}{a} eq 'r');
        }
        if(@arr)
        {
            push @ops, pop @arr;
        }
        $j++;
    }   
    print Dumper @nums;
    print Dumper @ops;

    my $res;
    while(@nums > 1)
    {
        my $num1 = pop @nums;
        my $num2 = pop @nums;
        my $op = pop @ops;

        print("izprazvane na opashkata, $num1, $num2, $op");
        $res = eval("$num1 $op $num2");
        push @nums, $res;
    }

    return $nums[0];
}

socket(F, PF_INET, SOCK_STREAM, getprotobyname('tcp')) || die $!;
my $sin = sockaddr_in (5000, INADDR_ANY);
my $length = 10;
bind(F,$sin)  || die $!;
listen(F, $length) || die $!;
while(accept(FH, F))
{
    next if my $pid = fork;
    die "fork: $!" unless defined $pid;
    close(F);
    print("[$$] CONNECTED\n");

    while(<FH>)
    {
        print("[$$] $_\n");
        my @arr = split(/,/, $_);
        my $res;
        if(CheckInput(@arr) == 0)
        {
            $res = ShuntingYardCalc(@arr);
        }
        else
        {
            $res = "Invalid input!"
        }
        $res .= "\n";  
            
        syswrite FH, $res, length $res ;
        sysopen (RES, "result.txt", O_WRONLY|O_CREAT|O_APPEND, 0755) 
            or die "cannot be opened. $!";
        syswrite RES, $res, length $res;
        close RES;

    }
    close(FH);
    print("[$$] EXIT\n");
    exit;
}
