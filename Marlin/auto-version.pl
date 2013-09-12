use strict;

my $REV = `git rev-parse --short HEAD`;
my $INFO = "$ENV{BUILT_PRODUCTS_DIR}/$ENV{WRAPPER_NAME}/Contents/Info.plist";
 
my $version = $REV;
die "$0: No Git revision found" unless $version;
 
open(FH, "$INFO") or die "$0: $INFO: $!";
my $info = join("", <FH>);
close(FH);
 
$info =~ s/([\t ]+<key>CFBundleVersion<\/key>\n[\t ]+<string>).*?(<\/string>)/$1$version$2/;
 
open(FH, ">$INFO") or die "$0: $INFO: $!";
print FH $info;
close(FH);
