package Lism::CLI;
use Any::Moose;

our $VERSION = '0.10';

use Encode;
use Email::MIME;
use Email::MIME::Creator;
use Email::Send;
use FindBin;
use File::Find;
use File::stat;
use Getopt::Long;
use POSIX;
use Sys::Hostname;

has 'config' => (
    is  => 'rw',
    isa => 'Config::YAML',
);

# executed options
has 'opt' => (
    is  => 'rw',
    isa => 'HashRef',
);

# options definitions
has 'options' => (
    is      => 'ro',
    isa     => 'ArrayRef',
    default => sub { [qw/debug help verbose/] },
);

has 'debug' => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
);

has 'error_level' => (
    is      => 'rw',
    isa     => 'Str',
    default => 'notice',
);

has 'failed' => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
);

has 'start_time' => (
    is      => 'rw',
    isa     => 'Str',
    default => sub { strftime("%Y/%m/%d %H:%M:%S", localtime) },
);

# Don't call until  your script finished.
has 'finish_time' => (
    is      => 'rw',
    isa     => 'Str',
    lazy    => 1,
    default => sub { strftime("%Y/%m/%d %H:%M:%S", localtime) },
);

has 'hostname' => (
    is      => 'rw',
    isa     => 'Str',
    lazy    => 1,
    default => sub { Sys::Hostname::hostname },
);

has 'log' => (
    is      => 'rw',
    isa     => 'Str',
    default => '',
);

our $USAGE = <<'END_USAGE';
command - description
  Usage: command [options] args

  Options:
    -d(--debug)    debug mode
    -h(--help)     show this help
    -v(--verbose)  verbose mode

Written by your name<email>
END_USAGE

sub get_options {
    my ($self) = @_;
    my %opt;
    my @options = (\%opt, @{$self->options});
    GetOptions(@options) or $self->usage;
    $self->usage if $opt{ help };
    $self->debug(1) if $opt{ debug };
    $self->opt(\%opt);
}

sub usage {
    our $USAGE;
    my $self = shift;
    my $class = ref $self;
    eval 'print $' . $class . '::USAGE'; ## no critic
    exit 1;
}

sub run {
    my ($self, @args) = @_;
    $self->get_options;
    my $result;
    eval { $result = $self->main(@args) };
    if ( $@ ) {
        $self->logging($@, 'error');
    }
    $self->detect_error_level;
    return $result;
}

sub main {
    my ($self, @args) = @_;
    Carp::croak 'implement your command';
}

sub report {
    my ($self) = @_;
    my $body = sprintf "running %s on %s at %s\n",
        $FindBin::Script, $self->hostname, $self->start_time;
    $body .= "-" x 40 . "\n";
    $body .= $self->log;
    chomp $body;
    $body .= "\n" . "-" x 40 . "\nfinished at " . $self->finish_time . "\n";
}

sub _escape {
    my ($self, $text) = @_;
    $text =~ s/\e\[\d+m//g;
    return $text;
}

sub send_report {
    my ($self) = @_;
    Carp::croak 'config undefined' unless $self->config;
    my $alert_lv = $self->error_level || 'notice';
    my $args = {
        from    => $self->config->{ mail_from },
        to      => $self->config->{ alert_email }->{ $alert_lv },
        subject => "[$alert_lv] running $FindBin::Script",
        body    => $self->report,
    };
    my $method = $self->debug ? '_print_mail' : '_send_mail';
    $self->$method($args);
}

sub _send_mail {
    my ($self, $args) = @_;
    Carp::croak 'From: is required' unless $args->{ from };
    Carp::croak 'To: is required' unless $args->{ to };
    my $mail = Email::MIME->create(
        header => [
            From    => $args->{ from },
            To      => $args->{ to },
            Subject => Encode::encode('MIME-Header-ISO_2022_JP', $args->{ subject }),
        ],
        parts => [
            encode('iso-2022-jp', $self->_escape($args->{ body })),
        ],
    );
    my $sender = Email::Send->new({ mailer => 'Sendmail' });
    $sender->send($mail);
}

sub _print_mail {
    my ($self, $args) = @_;
    printf "   From: %s\n     To: %s\nSubject: %s\n\n%s",
        $args->{ from }, $args->{ to }, $args->{ subject }, $args->{ body };
}

sub detect_error_level {
    my ($self) = @_;
    my $log = $self->log;
    if ( $log =~ /^\[warn\]/m ) {
        $self->error_level('warn');
    }
    if ( $log =~ /^\[error\]/m ) {
        $self->error_level('crit');
        $self->failed(1);
    }
}

sub confirm {
    my ($self, $msg) = @_;
    print $msg, " (y/[n]) ";
    my $ok = readline(*STDIN);
    $ok =~ /^y/i;
}

sub logging {
    my ($self, $msg, $level) = @_;
    $level ||= 'info';
    chomp $msg;
    $self->log($self->log . "[$level] $msg\n");
}

1;
__END__

=head1 NAME

Lism::CLI -

=head1 SYNOPSIS

  package Your::App;
  use Any::Moose;
  extends 'Lism::CLI';

  sub main { ... your logic ... }

  package main;
  my $config = Config::YAML->new(config => $filename);
  my $app = Your::App->new(config => $config);
  $app->run;
  $app->send_report if $app->failed || $app->opt->{ verbose };

=head1 DESCRIPTION

Lism::CLI is

=head1 PROPERTIES

=over 4

=item config

Config::YAML object.

=item opt

Command line options.

=item options

Definition of options.

=item failed

Application executed failed or not.

=item start_time
=item finish_time
=item hostname
=item log

=back

=head1 METHODS

=over 4

=item get_options

=item usage

=item run( @args )

=item main( @args )

You need to override this method.

=item report

Return report.

=item _escape( $text )

Remove escape sequence.

=item send_report

Send report to email or stdout (depends on debug mode).

=item _send_mail( $args )

Send mail. $args takes "from", "to", "subject" and "body" as its key.

=item _print_mail( $args )

Print mail data instead of send acutual e-mail.

=item confirm( $msg )

Input by readline.

=item logging( $msg (, $default) )

Logging $msg. default level is 'info'.

  $app->logging('info message');
  $app->logging('file not found', 'error');

=back

=head1 AUTHOR

Ryo Miyake E<lt>ryo.studiom@gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
