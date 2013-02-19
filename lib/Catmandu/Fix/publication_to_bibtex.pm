package Catmandu::Fix::publication_to_bibtex;

use lib '/home/bup/perl5/lib/perl5';
use Catmandu::Sane;
use Moo;
use Catmandu::Util qw(:array trim);
use Dancer qw(:syntax config);

my $TYPES = {
    book             => 'book',
    bookChapter      => 'inbook',
    bookEditor       => 'book',
    conference       => 'inproceedings',
    dissertation     => 'phdthesis',
    biDissertation   => 'phdthesis',
    journalArticle   => 'article',
};

sub fix {
    my ($self, $pub) = @_;

    my $type = $TYPES->{$pub->{documentType}} ||= 'misc';
	
    my $bib; 
    $bib->{_citekey} = $pub->{_id};
    $bib->{_type}    = $type;
    $bib->{title}    = $pub->{mainTitle} if $pub->{mainTitle};
    $bib->{language} = $pub->{language}->{name} if $pub->{language}->{name};
   # $bib->{keyword  => $pub->{keywords} if,
    $bib->{volume}   = trim($pub->{volume}) if $pub->{volume};
    $bib->{number}   = $pub->{issue} if $pub->{issue};
    $bib->{year}     = $pub->{publishingYear} if $pub->{publishingYear};

    my $val;

    if ( $pub->{publication} ) {
       given ($type) {
          when (/article/) { $bib->{journal}   = $pub->{publication} if $pub->{publication}}
          when (/^book/) { $bib->{booktitle} = $pub->{publication} if $pub->{publication}}
          default { $bib->{series}    = $pub->{publication} if $pub->{publication}}
       }
    }

    if (my $au = $pub->{author}) {
      #  $val = array_group_by $val, 'role';
        $bib->{author} = [ map { "$_->{givenName} $_->{surname}" } @$au ];
    }
    
    if (my $ed = $pub->{editor}) {
    	$bib->{editor} = [ map { "$_->{givenName} $_->{surname}" } @$ed ];
    }

    if ($val = $pub->{isbn} and @$val) {
        $bib->{isbn} = $val->[0];
    }

    if ($val = $pub->{issn} and @$val) {
        $bib->{issn} = $val->[0];
    }

    if ($val = $pub->{doi} ||= $pub->{doiInfo}->{doi}) {
        $bib->{url} = "http://dx.doi.org/" . $val;
    }
   # if ($val = $pub->{link}) { 
   #	push @{$bib->{url}},  $val->[0]->{url};
   # }

    $bib->{publisher} = $pub->{publisher} if $pub->{publisher};

    if ($val = $pub->{abstract} and @$val) {
        $bib->{abstract} = $val->[0]->{text};
    }

    if ($val = $pub->{conference}) {
        $bib->{location} = $val->{location};
    }

    if ($pub->{documentType} =~/^bi/) {
        $bib->{school} = "Bielefeld University";#config->{institution};
    }

    if ($pub->{pagesStart} && $pub->{pagesEnd}) {
            $bib->{pages} = join '--', $pub->{pagesStart}, $pub->{pagesEnd};
    }

    $bib;
}

1;
