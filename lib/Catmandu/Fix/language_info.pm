package Catmandu::Fix::language_info;

use Catmandu::Sane;
use Moo;

sub fix {
    my ( $self, $pub ) = @_;
        
    if (my $lang = $pub->{usesLanguage}->[0]) {
    	
    	$pub->{language}->{iso} = $lang->{languageCode};
    	foreach my $lname (@{$lang->{name}}) {
    		if ($lname->{lang} eq 'eng') {
    			$pub->{language}->{name} = $lname->{text};
    		}
    	}
    	
    }
    
    $pub;
}

1;