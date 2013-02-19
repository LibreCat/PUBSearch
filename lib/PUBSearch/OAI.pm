package PUBSearch::OAI;

use Catmandu::Sane;
use PUBSearch::OAI_Core;

oai_provider '/new_oai',
    deleted => sub {
        $_[0]->{status} && $_[0]->{status} eq 'deleted';
    },
    set_specs_for => sub {
        my $pub = $_[0];
        my $specs = [$pub->{documentType}];
		
        if ($pub->{file}) {
            if ($pub->{file}->[0]->{openAccess} eq '1') {
                push @$specs, "$pub->{documentType}Ftxt", "driver", "open_access";
            }
        }

        $specs;
    };

1;
