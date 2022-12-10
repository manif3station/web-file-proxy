package Web::File::Proxy;

use Dancer2 appname => 'Web';

use Web::Content;
use HTTP::API::Client;
use File::MimeInfo::Magic;

my $content = Web::Content->new;
my $api =
  HTTP::API::Client->new( browser_id =>
'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/107.0.0.0 Safari/537.36',
  );

get qr{^/fp/(.+)} => sub {
    my ($path) = splat;

    $path =~ s/\//./g;
    $path =~ s/\.{2,}/./g;

    my $url = $content->get($path);

    if ( !$url || $url !~ m{^https?\://} || $url =~ /\s/ ) {
        status 'not_found';
        halt '404 File Not Found';
    }

    delayed {
        my $resp = $api->get($url);
        my $content = $resp->decoded_content;
        my $type = do {
            open my $fh, '<', \$content;
            mimetype $fh;
        };
        response_header "content-type" => $type;
        flush;
        content $content;
        done;
    }
    on_error => sub {
        my ($error) = @_;
        warning qq{File Proxey found error with "$path"\nError: $error};
    };
};

1;
