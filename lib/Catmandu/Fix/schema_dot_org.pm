package Catmandu::Fix::schema_dot_org;

use Catmandu::Sane;
use Dancer qw(:syntax);
use Moo;

my $TYPES_MAP = {
   book => 'Book',
   bookEditor => 'Book', 
   review => 'Review',
   journalArticle => 'ScholarlyArticle',
   conference => 'ScholarlyArticle',
   preprint => 'ScholarlyArticle',
   dissertation => 'DoctoralThesis',
   biDissertation => 'DoctoralThesis',
   newspaperArticle => 'NewArticle',
   default => 'CreativeWork',
};

# IETF BCP 47 Standard
#my $LANG_MAP = {
#
#};



sub fix {
   my ($self, $pub) = @_;
   my $schema_org;
   my $type = $TYPES_MAP->{$pub->{documenttype}} ||= $TYPES_MAP->{default};
   my $inLanguage;

   $pub->{schema}->{type} = $type;

   return $pub;   
}

1;
