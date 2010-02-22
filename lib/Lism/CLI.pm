package Lism::CLI;
use Any::Moose;

our $VERSION = '0.01';

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

has 'conf' => (
    is  => 'rw',
    isa => 'Lism::Config',
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
    default => sub { ['help'] },
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
    -h(--help)    show this help

Written by your name<email>
END_USAGE

sub BUILD {
    #my $mailbody  = "running $script on $hostname at $starttime\n" . "-" x 40 . "\n";
}

sub get_options {
    my ($self) = @_;
    my %opt;
    my @options = (\%opt, @{$self->options});
    GetOptions(@options) or $self->usage;
    $self->usage if $opt{ help };
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
        $self->failed(1);
        $self->log($self->log . "\n[ERROR!] $@\n");
    }
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

sub plain_report {
    my ($self) = @_;
    my $report = $self->report;
    $report =~ s/\e\[\d+m//g;
    return $report;
}

sub send_mail {
    my ($self, $args) = @_;
    my $mail = Email::MIME->create(
        header => [
            From    => $args->{ from },
            To      => $args->{ to },
            Subject => Encode::encode('MIME-Header-ISO_2022_JP', $args->{ subject }),
        ],
        parts => [
            encode('iso-2022-jp', $args->{ body }),
        ],
    );
    my $sender = Email::Send->new({ mailer => 'Sendmail' });
    $sender->send($mail);
}

sub print_report {
    my ($self, $args) = @_;
    printf "   From: %s\n     To: %s\nSubject: %s\n\n%s",
        $args->{ from }, $args->{ to }, $args->{ subject }, $self->report;
}

sub confirm {
    my ($self, $msg) = @_;
    print $msg, " (y/[n]) ";
    my $ok = readline(*STDIN);
    $ok =~ /^y/i;
}

1;
__END__

=head1 NAME

Lism::CLI -

=head1 SYNOPSIS

  use Lism::CLI;

=head1 DESCRIPTION

Lism::CLI is

=head1 AUTHOR

Ryo Miyake E<lt>ryo.studiom@gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
