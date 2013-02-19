package Catmandu::Fix::add_ddc;

use Catmandu::Sane;
use Moo;

sub fix {
	
    my ( $self, $pub ) = @_;
    my $ddc;
    
    	if ($pub->{hasDdc} && ref $pub->{hasDdc} eq 'ARRAY') {
    		foreach (@$ddc) {
    			$ddc->{class} = $_->{ddcNumber};
    			$ddc->{name} = $_->{ddcName}->{text};
    			$ddc->{level} = $_->{ddcLevel};
        		push @{$pub->{ddc}}, $ddc;
    		}
    	} elsif ($pub->{hasDdc}) {
    			$ddc->{class} = $pub->{hasDdc}->{ddcNumber};
    			$ddc->{name} = $pub->{hasDdc}->{ddcName}->{text};
    			$ddc->{level} = $pub->{hasDdc}->{ddcLevel};
    			push @{$pub->{ddc}}, $ddc; 
    	}
    	
		delete $pub->{hasDdc};        
	
    $pub;

}

1;
