package Catmandu::Fix::dates_to_W3cdtf;

use Catmandu::Sane;
use Time::Local 'timelocal_nocheck';
use Moo;



sub fix {
    my ( $self, $pub ) = @_;

 
    foreach ( qw(dateCreated dateLastChanged defenseDateTime) ) {
        # convert the dates with time to  dateToW3cdtf format
        $pub->{$_} = _dateToW3cdtf( $pub->{$_} ) if $pub->{$_}; 
    }

    $pub;
}


sub _dateToW3cdtf {
    my $dateStr = shift;

    if ($dateStr =~m/(\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2})(?::(\d{2}))?/) {
        my $t = timelocal_nocheck($6 || 0,$5,$4,$3,$2 - 1,$1);
        my $dlst = (localtime($t))[8]; #check if daylight savings time used

        $dateStr =~ s/ /T/;
        # TODO: Should me moved into config:
        $dateStr .= ($dlst ? '+2:00' : '+1:00'); #adjust timezone if daylight savings time used
    }
    return $dateStr;
}



1;
