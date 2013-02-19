package PUBSearch::Thumbnail;

use Catmandu::Sane;
use Catmandu::Util qw(:array);
use Dancer qw(:script :syntax);
use PUBSearch::Helper;
 
# path helper
sub thumbnail_path {
	my $recid = shift;
    my ($file) = @_;
    my $base_path = config->{thumbnail_path}; # thumbnail dir
    my $name = $file->{fileName};
    $name =~ s/\.\w{1,4}$//g;
    my $path = $base_path . "/$recid/$name.png"; # thumbnail file path
    return $path;
    return;
}

 
# the route
get '/thumbnail/:id/:filename' => sub {
    my $id = params->{id};
    my $filename = params->{filename};
 
    # get the publication
    if (my $pub = h->publications->get($id)) {
        return status 404 unless $pub->{submissionStatus} eq 'public'; # check if it's public
        my $files = $pub->{file} || return status 404;
 
        for my $file (@$files) {
            if ($file->{fileName} eq $filename) { # found the file
                if ($file->{accessLevel} eq 'admin') {
                    return status 404;
                }
                if ($file->{accessLevel} eq 'lu') { # check if ip is in range
                    return status 401 unless request->address =~ config->{ip_range};
                }
                my $path = thumbnail_path($id, $file) // return status 404; # is there a thumbnail?
                # send the file
                send_file $path,
                    system_path  => 1,
                    content_type => 'image/png';
            }
        }
    }
    status 404;
};

1;
