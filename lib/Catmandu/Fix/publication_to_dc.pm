package Catmandu::Fix::publication_to_dc;

use Catmandu::Sane;
use Moo;
use Dancer qw(:syntax setting);

my $DRIVER_TYPES = {
    journalArticle => 'article',
    book => 'book',
    bookChapter => 'bookPart',
    bookEditor => 'book',
    bookReview => 'review',
    conference => 'conferenceObject',
    dissertation => 'doctoralThesis',
    biDissertation => 'doctoralThesis',
    biPostdocThesis => 'doctoralThesis',
    biBachelorThesis => 'bachelorThesis',
    biMasterThesis => 'masterThesis',
    licentiateThesis => 'masterThesis',
    workingPaper => 'workingPaper',
    preprint => 'preprint',
    report => 'report',
    patent => 'patent',
    newspaperArticle =>  'contributionToPeriodical',
    
};


my $LANG_MAP = {
   chi => 'cmn',
   ger => 'deu',
   fre => 'fra',
   rum => 'ron',
   gre => 'ell',
};

my $uri_base = setting('host') . '/publication';

sub fix {

    my ($self, $pub) = @_;

   # basic infos
    my $type = $DRIVER_TYPES->{$pub->{documentType}} || 'other';
    my $dc = {
        identifier => [ "$uri_base/$pub->{_id}" ],
        type => [$type, "info:eu-repo/semantics/$type"]
    };
    ($pub->{documentType} eq 'biPostdocThesis') && (push @{$dc->{type}}, "posdoctoral thesis/habilitation");
    push @{$dc->{type}}, "text";
    $dc->{title}       = [ $pub->{mainTitle} ] if $pub->{mainTitle};
    $dc->{date}        = [ $pub->{publishingYear} ] if $pub->{publishingYear};
    push @{$dc->{date}}, $pub->{defenseDateTime} if $pub->{defenseDateTime};
    $dc->{description} = $pub->{abstract}->[0]->{text} if $pub->{abstract};
    $dc->{publisher}   = [ $pub->{publisher} ]                   if $pub->{publisher};
    $dc->{language}    = $LANG_MAP->{$pub->{language}->{iso}} ? $LANG_MAP->{$pub->{language}->{iso}}
                        : $pub->{language}->{iso} ;

   # identifier
    if ($pub->{issn}) {
        push @{$dc->{source} ||= []}, map { "ISSN: $_" } @{$pub->{issn}};
    }

    if ($pub->{isbn}) {
        if ($pub->{parent}) {
            push @{$dc->{source} ||= []}, map { "ISBN: $_" } @{$pub->{isbn}};
        } else {
            push @{$dc->{identifier} ||= []}, map { "urn:isbn:$_" } @{$pub->{isbn}};
        }
    }

    if (my $doi = $pub->{doi} ||= $pub->{doiInfo}->{doi}) {
        push @{$dc->{identifier}}, "DOI:$doi";
    }

    foreach (qw(isi inspire medline arxiv)) {
    	push (@{$dc->{identifier}}, uc($_).":$pub->{$_}") if $pub->{$_};
    }

   # persons related to publication
    if (my $auth = $pub->{author}) {
        $dc->{creator} = [ map { $_->{fullName} || join(', ', $_->{surname}, $_->{givenName}) } @$auth ];
    }

    if (my $ed = $pub->{editor}) {
	push @{$dc->{contributor} ||= []},
        map { $_->{fullName} || join(', ', $_->{surname}, $_->{givenName}) } @$ed;
    }

    if (my $trans = $pub->{translatedWorkAuthor}) {
	push @{$dc->{contributor} ||= []},
        map { $_->{fullName} || join(', ', $_->{surname}, $_->{givenName}) } @$trans;
    }

    push @{$dc->{contributor} ||= []}, $pub->{corporateEditor} if $pub->{corporateEditor};

   # subjects/keywords
    if (my $subject = $pub->{subject}) {
    	foreach (@$subject) {
       	   push @{$dc->{subject} ||= []}, $_->{name}->[0]->{text};
    	}
    }

    if (my $keyword = $pub->{keyword}) {
        push @{$dc->{subject} ||= []}, @$keyword;
    }

   # dc:source->"citation"
    if ($type eq 'article') {
	my $source = $pub->{publication} if $pub->{publication};
	$source .= ", " . $pub->{volume} if $pub->{volume};
	$source .= " ($pub->{issue})" if $pub->{issue}; 
	$source .= ", " . $pub->{pagesStart} if $pub->{pagesStart};
	$source .= "-" . $pub->{pagesEnd} if $pub->{pagesEnd};
	push @{$dc->{source}}, $source if $source ne '';
    }

   # fulltexts access rights	
    if (my $file = $pub->{file}->[0]) {
       $dc->{format} = [ $file->{contentType} ];
       given ($file->{accessLevel}) {
          when ('openAccess')       { push @{$dc->{rights} ||= []}, "info:eu-repo/semantics/openAccess" }
          when ('lu') { push @{$dc->{rights} ||= []}, "info:eu-repo/semantics/restrictedAccess" }
          when ('admin')    { push @{$dc->{rights} ||= []}, "info:eu-repo/semantics/closedAccess" }
       }
    }

#    foreach my $proj ( @{$pub->{projects}} ) {
#	if ($proj->{eu_id}
#	   && $proj->{eu_framework_programme}
#	   && $proj->{eu_framework_programme} =~ /^FP\d+$/) {
#           push @{$dc->{relation} ||= []}, "info:eu-repo/grantAgreement/EC/$proj->{eu_framework_programme}/$proj->{eu_id}";
#         }
#    }

    $dc;

}

1;
