use 5.010;
use strict;
use warnings;

package Dist::Zilla::Plugin::Git::Init;
# ABSTRACT: initialize git repository on dzil new

our %transform = (
  lc => sub { lc shift },
  uc => sub { uc shift },
  '' => sub { shift },
);

use Moose;
use Git::Wrapper;
use String::Formatter method_stringf => {
  -as => '_format_string',
  codes => {
    n => sub { "\n" },
    N => sub { $transform{$_[1] || ''}->( $_[0]->zilla->name ) },
  },
};

with 'Dist::Zilla::Role::AfterMint';

has commit_message => (
    is      => 'ro',
    isa     => 'Str',
    default => 'initial commit',
);

has remotes => (
  is   => 'ro',
  isa  => 'ArrayRef[Str]',
  default => sub { [] },
);

sub mvp_multivalue_args { qw(remotes) }
sub mvp_aliases { return { remote => 'remotes' } }

sub after_mint {
    my $self = shift;
    my ($opts) = @_;
    my $git = Git::Wrapper->new($opts->{mint_root});
    $self->log("Initializing a new git repository in " . $opts->{mint_root});
    $git->init;
    $git->add($opts->{mint_root});
    $git->commit({message => _format_string($self->commit_message, $self)});
    foreach my $remoteSpec (@{ $self->remotes }) {
      my ($remote, $url) = split ' ', _format_string($remoteSpec, $self), 2;
      $self->log("Adding remote $remote as $url");
      $git->remote(add => $remote, $url);
    }
}

1;
__END__

=for Pod::Coverage
    after_mint mvp_aliases mvp_multivalue_args


=head1 SYNOPSIS

In your F<profile.ini>:

    [Git::Init]
    commit_message = initial commit  ; this is the default
    remote = origin git@github.com:USERNAME/%{lc}N.git ; no default

=head1 DESCRIPTION

This plugin initializes a git repository when a new distribution is
created with C<dzil new>.


=head2 Plugin options

The plugin accepts the following options:

=over 4

=item * commit_message - the commit message to use when checking in
the newly-minted dist. Defaults to C<initial commit>.

=item * remote - a remote to add to the repository.  No remotes are
added by default.  A remote is specified as C<NAME URL>.  This may be
specified multiple times to add multiple remotes.

=back

=head2 Formatting options

You can use the following codes in C<commit_message> or C<remote>:

=over 4

=item C<%n>

A newline.

=item C<%N>

The distribution name.  You can also use C<%{lc}N> or C<%{uc}N> to get
the name in lower case or upper case, respectively.

=back
