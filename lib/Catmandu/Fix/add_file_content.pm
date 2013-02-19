package Catmandu::Fix::add_file_content;

use Catmandu::Sane;
use Moo;
use Dancer qw(:syntax config);
use MIME::Base64;
use HTTP::Tiny;

my $http = HTTP::Tiny->new;

sub fix {
    my ($self, $pub) = @_;

    if (my $files = $pub->{file}) {
        for my $file (@$files) {
            next unless $file->{access} eq 'open';
            next unless $file->{name} =~ /\.(?:pdf|doc|docx|txt|rtf)$/;

            my $res = $http->get(sprintf(config->{fileresolve}, $pub->{_id}, $file->{_id}));

            if ($res->{success} && length($res->{content})) {
                $file->{content} = encode_base64($res->{content});
            }
        }
    }

    $pub;
}

1;
