package Catmandu::Fix::publication_to_xmdp;

use Catmandu::Sane;
use Moo;
use Dancer qw(:syntax setting);
#use Digest::SHA1 qw(sha1);

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
    workingPaper => 'workingPaper',
    preprint => 'preprint',
    report => 'report',
    patent => 'patent',
    newspaperArticle =>  'contributionToPeriodical',
    
};

my $DINI_TYPES = {
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
    workingPaper => 'workingPaper',
    preprint => 'preprint',
    report => 'report',
    patent => 'patent',
    newspaperArticle =>  'contributionToPeriodical',
};

my $XMDP_MAP = {
	language => 'language',
	author => 'author',
	abstract => 'abstract',
	keyword => 'subject',
	urn => 'urn',
	mainTitle => 'title',
	_id => '_id',
	file => 'file',
	publishingYear => 'date',
	defenseDate => 'defenseDate',
	supervisor => 'supervisor',
	citations => 'citations',
	doi => 'doi',
};

my $uni = setting('institution');

sub fix {
    my ($self, $pub) = @_;
	
	my $xmdp;
	
    $xmdp->{diniType} = $DINI_TYPES->{$pub->{documentType}} || 'other';
    foreach (keys %$XMDP_MAP) {
    	$xmdp->{$XMDP_MAP->{$_}} = $pub->{$_};
    }
    
    if ($pub->{documentType} =~ /^bi/)
    {
    	given ($pub->{documentType}) {
    		when ('biBachelorThesis') {$xmdp->{thesisLevel} = 'bachelor'}
    		when ('biMasterThesis') {$xmdp->{thesisLevel} = 'master'}
    		when ('biDissertation') {$xmdp->{thesisLevel} = 'thesis.doctoral'}
    		when ('biPostdocThesis') {$xmdp->{thesisLevel} = 'thesis.habilitation'}
    	}
    	$xmdp->{thesis} = '1';
    }
	$xmdp->{uni} = $uni;
	    
    $xmdp;
}

1;
