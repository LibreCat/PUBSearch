package Catmandu::Fix::volume_sort;

use Catmandu::Sane;
use Moo;

sub fix {
    my ( $self, $pub ) = @_;
    
    if ($pub->{volume} and $pub->{volume} =~ /^-?\d+$/) {
    	$pub->{volume} = sprintf("%10d", $pub->{volume});    	
    }
    
    $pub;
}

1;