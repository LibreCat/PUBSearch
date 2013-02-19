package PUBSearch::Directoryindex;

use Catmandu::Sane;
use Dancer qw(:syntax);

get '/' => sub {
	forward '/index.html';
};

get qr{/demo/*} => sub {
    forward '/demo/index.html';
};

get qr{/puboa/*} => sub {
    forward '/puboa/index.html';
};

get qr{/pubtheses/*} => sub {
    forward '/pubtheses/index.html';
};

get qr{/workshop/*} => sub {
	forward '/workshop/index.html';
};

get qr{/\(en\)/*} => sub {
	forward '/(en)/index.html';
};

get qr{/\(en\)/demo/*} => sub {
	forward '/(en)/demo/index.html';
};

get qr{/\(en\)/puboa/*} => sub {
	forward '/(en)/puboa/index.html';
};

get qr{/\(en\)/pubtheses/*} => sub {
	forward '/(en)/pubtheses/index.html';
};

1;