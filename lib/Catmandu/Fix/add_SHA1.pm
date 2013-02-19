package Catmandu::Fix::add_SHA1;

use Catmandu::Sane;
use Moo;

use Digest::SHA1;

sub fix {
	
	my @files = @_;
	
	#die "Usage: $0 file ..\n" unless @_;
	return 0 unless @_;
	
	foreach my $file (@files) {
  		my $fh;
  		unless (open $fh, $file) {
    		warn "$0: open $file: $!";
    		next;
  		}

  		my $sha1 = Digest::SHA1->new;
  		$sha1->addfile($fh);
  		#print $sha1->hexdigest, "  $file\n";
		
  		close $fh;
		sha1->hexdigest;
		
	}

}

=head1 NAME

Catmandu::Fix::add_SHA1 - computes SHA1 key for files 

=head1 SYNOPSIS

   # 
   add_SHA1('foo.txt');

=head1 SEE ALSO

L<Catmandu::Fix>

=cut

1;