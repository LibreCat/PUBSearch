package Catmandu::Fix::MODS_mapping;

use Catmandu::Sane;
use Moo;

#ToDo: bi*-Types
my $genreMap = {
		biBachelorThesis => 'thesis',
		biMasterThesis => 'thesis',
		biDissertation => 'thesis',
		biPostdocThesis => 'thesis',
               dissertation       => 'thesis',
               licentiateThesis   => 'licentiate thesis',
               journalArticle     => 'article',
               preprint           => 'preprint',
               report             => 'report',
               conference         => 'conference paper',
               conferenceEditor   => 'conference publication',
               conferenceAbstract => 'conference abstract',
               workingPaper       => 'working Paper',
               book               => 'book',
               bookEditor         => 'book',
               bookChapter        => 'book chapter',
               newspaperArticle   => 'newspaper article',
               translation        => 'translation',
               review             => 'review',
               studentPaper       => 'student publications',
               caseStudy          => 'case study',
               miscellaneous      => 'miscellaneous',
               encyclopediaArticle => 'encyclopaedia entry',
               preface            => 'preface',
               patent             => 'patent',
               journalEditor      => 'journal editor',
               unknown            => 'article',
           };


# should add this in the database???
my $relationsMap = 
  {
      version => { from => 'earlierVersion', to => 'laterVersion'},
      part    => { from => 'isPart', to => 'hasPart'},
      paper   => { from => 'isPartDiss', to => 'hasPartDiss'},
      edition => { from => 'newEdition', to => 'oldEdition'},
      continued => { from => 'preceeding', to => 'succeeding'},
      translation => { from => 'hasTranslation', to => 'isTranslation'},
      erratum => { from => 'erratum', to => 'erratum'},
      supplementary => { from => 'supplementaryMaterial', to => 'supplementaryMaterial'},
      popular => { from => 'isPopularScience', to => 'hasPopularScience'},
      other => { from => 'otherRelation', to => 'otherRelation'},
  };

my $accessLevelMap = 
{
 'admin' => 'yes',
 'lu' => 'LU/LTH access',
 'openAccess' => 'no',
};


my $identifiersMap = 
  {
   issn => 'issn',
   isbn => 'isbn',
   otherPublicationIdentifier => 'other',
  };


sub fix {
    my ( $self, $pub ) = @_;

    #$pub->{noRoot} = $noRoot;
    $pub->{genre} =  $genreMap->{$pub->{documentType}} if $pub->{documentType};
   
    if ( $pub->{file} ) {
        foreach my $r ( @{$pub->{file}} ) {
            $r->{accessRestriction} =  $accessLevelMap->{ $r->{accessLevel} };
        }
    }

    if ($pub->{relatedMaterial}) {
        my @newRm = ();
        foreach my $r ( @{$pub->{relatedMaterial}} ) {
            my $rmType = $r->{type}{typeName};
            
          #  $r->{relationType}  = $relationsMap->{ $r->{materialRelationType}{materialRelationTypeId}}{$r->{relationRole}} || 'otherRelation';
            if ( $rmType eq 'relatedMaterialRecord') {
                my $otherRecord = 'relates' 
                    . ($r->{relationRole} eq 'to'
                                           ? 'From'
                                           : 'To');
                next unless $r->{$otherRecord}{submissionStatus} eq 'public';
                $r->{title} = $r->{$otherRecord}{mainTitle} || 'N/A';
                $r->{otherRecordOId} = $r->{$otherRecord}{oId};
                delete $r->{$otherRecord};
            } elsif ($rmType eq 'relatedMaterialLink') {
                $r->{accessRestriction} =  $r->{'link'}{hasRestrictedAccess} ? 'yes' : 'no';
                for (qw{contentType description url}) {
                    $r->{$_} = $r->{'link'}{$_};
                }
                $r->{title} =  $r->{'link'}{'linkTitle'};
                delete $r->{'link'};
            } else {#file - access level should always be set
                $r->{accessRestriction} =  $r->{file}{accessLevel} ? $accessLevelMap->{$r->{file}{accessLevel}} : 'yes';
                $r->{fileOId} = $r->{file}{fileOId};
                for (qw{contentType description openAccessDate}) {
                    $r->{$_} = $r->{'file'}{$_};
                }
                $r->{title} =  $r->{file}{'fileTitle'};
                delete $r->{'file'};
            }
            push @newRm, $r;
        }
        $pub->{relatedMaterial} = @newRm ? \@newRm : undef;
        delete $pub->{relatedMaterial} unless $pub->{relatedMaterial};
    }
    
    for (qw/issn isbn otherPublicationIdentifier/) {
        @{$pub->{ $_}} = grep( !/^ISI:/, @{$pub->{$_}})
        if $pub->{$_};
    }

    $pub;
}


1;
