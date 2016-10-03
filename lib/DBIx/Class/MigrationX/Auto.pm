use 5.20.0;
use strict;
use warnings;

package DBIx::Class::MigrationX::Auto;

# ABSTRACT: Short intro
# AUTHORITY
our $VERSION = '0.0100';

use base 'App::Spec::Run';
use Moo;
use Cwd;
use File::Find();
use Module::Load;
use Try::Tiny;
use Carp qw/confess/;
use DBIx::Class::Migration;
use experimental qw/signatures postderef/;
use lib 'lib';

has config_class => (
    is => 'ro',
    builder => '_build_config_class',
);
sub _build_config_class {
    # Finds a *::Config class in the executing directory's child directories.
    my $config_class;
    File::Find::find(
        {
            wanted => sub {
                my $file = $_ =~ s{^.*/lib/}{}r;
                return if $file !~ m{/Config\.pm$};
                $file =~ s{/}{::}g;
                $file =~ s{\.pm}{};

                load $file;
                $config_class = $file;
            },
            no_chdir => 1,
        },
        getcwd(). '/lib'
    );

    return $config_class->new;
}
has schema => (
    is => 'ro',
    lazy => 1,
    default => sub ($self) {
        my $schema_class = $self->config_class->get('db/schema_class');
        load $schema_class;
        return $schema_class->connect;
    },
);

has migration => (
    is => 'ro',
    lazy => 1,
    builder => '_build_migrator',
    handles => [qw/
        prepare
        install
        upgrade
        status
        drop_tables
        dump_all_sets
        populate
    /],
);
sub _build_migrator($self) {
    return DBIx::Class::Migration->new({
        schema => $self->schema,
        dbic_dh_args => $self->options,
    });
}
before status => sub ($self) {
    say ref $self->schema;
};
before prepare => sub ($self) {
    $self->status;
};

1;

__END__

=pod

=head1 SYNOPSIS

    use DBIx::Class::Migrator;

=head1 DESCRIPTION

DBIx::Class::Migrator is ...

=head1 SEE ALSO

=cut
