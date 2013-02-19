package Catmandu::Fix::hiddenFor_info;

use Catmandu::Sane;
use Dancer qw(:syntax);
use Moo;


sub fix {
   my ($self, $pub) = @_;
   (!$pub->{hide}) && (return $pub);

   my $hide = $pub->{hide};
   delete $pub->{hide};
   foreach (@$hide) {
	push @{$pub->{hide}}, $_->{personNumber};
   }

   $pub;

}

1;
