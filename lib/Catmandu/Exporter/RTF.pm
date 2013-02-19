package Catmandu::Exporter::RTF;

use Catmandu::Sane;
use Catmandu;
use Moo;

extends 'Catmandu::Exporter::Cite';

my $HEADER = <<EOF;
{\\rtf1\\ansi\\deff0\\adeflang1025
{\\fonttbl{\\f0 Arial{\\*\\falt Times New Roman};}}
{\\stylesheet{\\s1\\cf0{\\*\\hyphen2\\hyphlead2\\hyphtrail2\\hyphmax0}\\rtlch\\af6\\afs24\\lang255\\ltrch\\dbch\\af4\\langfe255\\hich\\f0\\fs24\\lang1031\\loch\\f0\\fs24\\lang1031\\snext1 Normal;}
{\\s2\\sb240\\sa120\\keepn\\cf0{\\*\\hyphen2\\hyphlead2\\hyphtrail2\\hyphmax0}\\rtlch\\afs28\\lang255\\ltrch\\dbch\\af5\\langfe255\\hich\\f2\\fs28\\lang1031\\loch\\f2\\fs28\\lang1031\\sbasedon1\\snext3 Heading;}
{\\s3\\sa120\\cf0{\\*\\hyphen2\\hyphlead2\\hyphtrail2\\hyphmax0}\\rtlch\\af6\\afs24\\lang255\\ltrch\\dbch\\af4\\langfe255\\hich\\f0\\fs24\\lang1031\\loch\\f0\\fs24\\lang1031\\sbasedon1\\snext3 Body Text;}
{\\s4\\sa120\\cf0{\\*\\hyphen2\\hyphlead2\\hyphtrail2\\hyphmax0}\\rtlch\\af7\\afs24\\lang255\\ltrch\\dbch\\af4\\langfe255\\hich\\f0\\fs24\\lang1031\\loch\\f0\\fs24\\lang1031\\sbasedon3\\snext4 List;}
{\\s5\\sb120\\sa120\\cf0{\\*\\hyphen2\\hyphlead2\\hyphtrail2\\hyphmax0}\\rtlch\\af7\\afs24\\lang255\\ai\\ltrch\\dbch\\af4\\langfe255\\hich\\f0\\fs24\\lang1031\\i\\loch\\f0\\fs24\\lang1031\\i\\sbasedon1\\snext5 caption;}
{\\s6\\cf0{\\*\\hyphen2\\hyphlead2\\hyphtrail2\\hyphmax0}\\rtlch\\af7\\afs24\\lang255\\ltrch\\dbch\\af4\\langfe255\\hich\\f0\\fs24\\lang1031\\loch\\f0\\fs24\\lang1031\\sbasedon1\\snext6 Index;}
{\\s7\\sb240\\sa120\\keepn\\cf0{\\*\\hyphen2\\hyphlead2\\hyphtrail2\\hyphmax0}\\rtlch\\afs32\\lang255\\ab\\ltrch\\dbch\\af5\\langfe255\\hich\\f2\\fs32\\lang1031\\b\\loch\\f2\\fs32\\lang1031\\b\\sbasedon2\\snext3{\\*\\soutlvl0} heading 1;}
{\\*\\cs9\\cf0\\rtlch\\af3\\afs18\\lang255\\ltrch\\dbch\\af3\\langfe255\\hich\\f3\\fs18\\lang1031\\loch\\f3\\fs18\\lang1031 Bullet Symbols;}
}{\\*\\listtable{\\list\\listtemplateid1
{\\listlevel\\levelnfc23\\leveljc0\\levelstartat1\\levelfollow0{\\leveltext \\'01\\u9679 ?;}{\\levelnumbers;}\\f3\\fs18\\f3\\fs18\\f3\\fs18\\f3\\fi-360\\li720}
{\\*\\soutlvl{\\listlevel\\levelnfc23\\leveljc0\\levelstartat1\\levelfollow0{\\leveltext \\'01\\u9679 ?;}{\\levelnumbers;}\\f3\\fs18\\f3\\fs18\\f3\\fs18\\f3\\fi-360\\li3960}}\\listid1}
}{\\listoverridetable{\\listoverride\\listid1\\listoverridecount0\\ls0}}

\\deftab709
{\\*\\pgdsctbl
{\\pgdsc0\\pgdscuse195\\pgwsxn11905\\pghsxn16837\\marglsxn1134\\margrsxn1134\\margtsxn1134\\margbsxn1134\\pgdscnxt0 Standard;}}
\\paperh16837\\paperw11905\\margl1134\\margr1134\\margt1134\\margb1134\\sectd\\sbknone\\pgwsxn11905\\pghsxn16837\\marglsxn1134\\margrsxn1134\\margtsxn1134\\margbsxn1134\\ftnbj\\ftnstart1\\ftnrstcont\\ftnnar\\aenddoc\\aftnrstcont\\aftnstart1\\aftnnrlc
\\pard\\plain \\sb240\\sa120\\keepn\\f2\\fs32\\b\\f5\\fs32\\b\\fs32\\b \\ltrpar\\s7\\cf0{\\*\\hyphen2\\hyphlead2\\hyphtrail2\\hyphmax0}\\sb240\\sa120\\keepn\\rtlch\\afs32\\lang255\\ab\\ltrch\\dbch\\af5\\langfe255\\hich\\f2\\fs32\\lang1031\\b\\loch\\f2\\fs32\\lang1031\\b {\\rtlch \\ltrch\\loch\\f2\\fs32\\lang1031\\i0\\b Publication List}

EOF

my $FOOTER = <<EOF;
\\par }

EOF


sub encoding { ':utf8' }

sub BUILD {
    $_[0]->{_buf} = $HEADER;
}

sub _add_cite {
    my ($self, $cite) = @_;
    
    # all those hexadecimal characters longer than 2 (\\' in rtf will treat the following two characters as hex - but only two!)
    my $hexlist = {
    	"152" => "\\'4f\\'45", # latin capital letter OE - substituted by capital letters O and E
    	"153" => "\\'6f\\'65", # latin small letter oe - substituted by small letters o and e
    	"160" => "\\'53", # latin capital letter S with caron - substituted by capital letter S
    	"161" => "\\'73", # latin small letter s with caron - substituted by small letter s
    	"178" => "\\'59", # latin capital letter Y with diaeresis - substituted by capital letter Y
    	"192" => "\\'66", # latin small f with hook, function - substituted by small letter f
    	"2013" => "\\endash",
    	"2014" => "\\emdash",
    	"2018" => "\\lquote",
    	"2019" => "\\rquote",
       #"201A" => # single low-9 quotation mark
    	"201C" => "\\ldblquote",
    	"201D" => "\\rdblquote",
       #"201E" => # double low-9 quotation mark
       #"2020" => # dagger
       #"2021" => # double dagger
    	"2022" => "\\bullet",
       #"2026" => # horizontal ellipsis
       #"2030" => # per thousand sign
       #"20AC" => # euro sign
       #"2122" => #trade mark sign
    };
    
    # replace all html tags in the citation with their rtf equivalent
    $cite =~ s/<em>(.*?)<\/em>/\{\\i $1}/g;
    $cite =~ s/&amp;/&/g;
    $cite =~ s/<span style="text-decoration:underline;">(.*?)<\/span>/{\\u $1}/g;
    $cite =~ s/<br \/>/\\line /g;
    
    # convert everything that isn't rtf or a space into hex (necessary for dealing with utf8/non-utf8 characters)
    # utf8::encode worked, but delivered (the Catmandu typical) double encodings in the file
    # utf8::decode got rid of the double encodings but the decoded string was not allowed in the rtf format
    # - so: hex, it is!
    $cite =~ s/([^\\\\u|\\\\i|\\\\line|\{|\}|\s])/sprintf("\\'%x",ord($1))/eg;
    
    # BUT rtf only works with hex codes consisting of 2 characters, everything that's longer gets cut after 2 (see hash above)
    # So, replace everything that has a longer hex representation with stuff from the list or nothing at all
    while ($cite =~ /\\\'(\d{3,4})/){
    	my $hexv = $1;
    	if ($hexlist->{$hexv}){
    		$cite =~ s/\\\'$hexv/$hexlist->{$hexv} /g;
    	}
    	else {
    		$cite =~ s/\\\'$hexv//g;
    	}
    }
    
    #utf8::decode($cite);
    my $citestring = "\\par \\pard\\plain {\\listtext\\pard\\plain \\li720\\ri0\\lin720\\rin0\\fi-360\\f3\\fs18\\f3\\fs18\\f3\\fs18 \\u9679\\'3f\\tab}\\ilvl0 \\ltrpar\\s1\\cf0{\\*\\hyphen2\\hyphlead2\\hyphtrail2\\hyphmax0}\\ls0\\li720\\ri0\\lin720\\rin0\\fi-360\\rtlch\\af6\\afs24\\lang255\\ltrch\\dbch\\af4\\langfe255\\hich\\f0\\fs24\\lang1031\\loch\\f0\\fs24\\lang1031 {\\rtlch \\ltrch\\loch\\f0\\fs24\\lang1031\\i0\\b0 $cite}\n";
    $self->{_buf} .= $citestring;
}

sub commit {
    my ($self) = @_;
    $self->fh->print($self->{_buf} . $FOOTER);
}

1;
