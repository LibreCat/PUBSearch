package Catmandu::Fix::split_ext_ident;

use Catmandu::Sane;
use Moo;

sub fix {
	my ($self, $pub) = @_;
	
	foreach my $ident (@{$pub->{externalIdentifier}}){
	
		given ($ident) {
			when (/^MEDLINE:(.*)/) {$pub->{medline}= $1}
			when (/^arXiv:(.*)/) {$pub->{arxiv} = $1}
			when (/^INSPIRE:(.*)/) {$pub->{inspire} = $1}
			when (/^ISI:(.*)/) {$pub->{isi} = $1}
			when (/^AHF:(.*)/) {$pub->{ahf} = $1}
			when (/^PhilLister:(.*)/) {$pub->{phillister} = $1}
			when (/^(FP7\/.*)/) {
				$pub->{fp7} = $1;
				$pub->{ecFunded} = 1;
				} 
		}
		
	}	
	
	delete $pub->{externalIdentifier};
	
	$pub;
}

1;
