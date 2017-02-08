package Mojolicious::Plugin::JSUrlFor::Angular;
use Mojo::Base 'Mojolicious::Plugin';
use JSON::PP;

my $json = JSON::PP->new->utf8(0)->pretty;

our $VERSION = '0.17';

#~ use Mojo::ByteStream qw/b/;
#~ use Data::Dumper;
#~ use v5.10;

sub register {
    my ( $self, $app, $config ) = @_;

    #~ if ( $config->{route} ) {
        #~ $app->routes->get( $config->{route} => sub {
            #~ my $c = shift;
            #~ $c->render(
                #~ inline => $c->app->_js_url_for_code_only(),
                #~ format => 'js'
            #~ );
        #~ } )->name('js_url_for');
    #~ }

    #~ $app->helper(
        #~ js_url_for => sub {
            #~ my $c      = shift;
            #~ state $b_js; # bytestream for $js

            #~ if ( $b_js && $app->mode eq 'production' ) {
                #~ return $b_js;
            #~ }

            #~ my $js = $app->_js_url_for_code_only;

            #~ $b_js = b('<script type="text/javascript">'.$js.'</script>');
            #~ return $b_js;
        #~ }
    #~ );

    $app->helper(
        _js_url_for_code_only => sub {
            my $c      = shift;
            my $endpoint_routes = $self->_collect_endpoint_routes( $app->routes );

            #~ my %names2paths;
            my @names2paths;
            foreach my $route (@$endpoint_routes) {
                next unless $route->name;

                my $path = $self->_get_path_for_route($route);
                $path =~ s{^/*}{/}g; # TODO remove this quickfix

                #~ $names2paths{$route->name} = $path;
                push @names2paths, sprintf("'%s': '%s'", $route->name, $path);
            }

            #~ my $json_routes = $c->render_to_string( json => \%names2paths );
            my $json_routes = $json->encode(\@names2paths);
            $json_routes =~ s/"//g;
            $json_routes =~ s/\[/{/g;
            $json_routes =~ s/\]/}/g;
            #~ utf8::decode( $json_routes );

            my $js = <<"JS";
(function () {
'use strict';
/*
Маршрутизатор
*/
  
var moduleName = "appRoutes";

try {
  if (angular.module(moduleName)) return function () {};
} catch(err) { /* failed to require */ }

var routes = $json_routes;
function url_for(route_name, captures) {
    var pattern = routes[route_name];
    if(!pattern) return route_name;

    // Fill placeholders with values
    if (!captures) captures = {};
    for (var placeholder in captures) { // TODO order placeholders from longest to shortest
        var re = new RegExp('[:*]' + placeholder, 'g');
        pattern = pattern.replace(re, captures[placeholder]);
    }

    // Clean not replaces placeholders
    pattern = pattern.replace(/[:*][^/.]+/g, '');

    return pattern;
}

var factory = {
  routes: routes,
  url_for: url_for
};

angular.module(moduleName, [])

.run(function (\$window) {
  \$window['angular.'+moduleName] = factory;
})

.factory(moduleName, function () {
  return factory;
})

;
JS
            return $js;
        } );
}


sub _collect_endpoint_routes {
    my ( $self, $route ) = @_;
    my @endpoint_routes;

    foreach my $child_route ( @{ $route->children } ) {
        if ( $child_route->is_endpoint ) {
            push @endpoint_routes, $child_route;
        } else {
            push @endpoint_routes, @{ $self->_collect_endpoint_routes($child_route) };
        }
    }
    return \@endpoint_routes
}

sub _get_path_for_route {
    my ( $self, $parent ) = @_;

    my $path = $parent->pattern->unparsed // '';

    while ( $parent = $parent->parent ) {
        $path = ($parent->pattern->unparsed//'') . $path;
    }

    return $path;
}

1;
__END__

=encoding utf8

=head1 NAME

Mojolicious::Plugin::JSUrlFor::Angular - Mojolicious routes for angular javascript

=head1 SYNOPSIS

  # Instead of helper use generator for generating static file
  
  perl script/app.pl generate js_url_for_angular > static/url_for.js
  

In output file:

  удалить ненужные маршруты remove not needs routes


=head1 DESCRIPTION

Генерация маршрутов для Angular1

=head1 HELPERS

None public

=head1 CONFIG OPTIONS

None

=head1 GENERATORS

=head2 C<js_url_for_angular>

  perl script/app.pl generate js_url_for_angular > path/to/relative_file_name


=head1 METHODS

L<Mojolicious::Plugin::JSUrlFor> inherits all methods from
L<Mojolicious::Plugin> and implements the following new ones.

=head2 C<register>

  $plugin->register;

Register plugin in L<Mojolicious> application.

=head1 AUTHOR

Viktor Turskyi <koorchik@cpan.org>

=head1 BUGS

Please report any bugs or feature requests to Github L<https://github.com/mche/Mojolicious-Plugin-JSUrlFor-Angular/>

Also you can report bugs to CPAN RT

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicio.us>.

=cut
