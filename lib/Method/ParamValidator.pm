package Method::ParamValidator;

$Method::ParamValidator::VERSION   = '0.01';
$Method::ParamValidator::AUTHORITY = 'cpan:MANWAR';

=head1 NAME

Method::ParamValidator - Automate method parameter validation.

=head1 VERSION

Version 0.01

=cut

use 5.006;
use JSON;
use Data::Dumper;

use Method::ParamValidator::Key::Field;
use Method::ParamValidator::Key::Method;
use Method::ParamValidator::Exception::InvalidMethodName;
use Method::ParamValidator::Exception::MissingParameters;
use Method::ParamValidator::Exception::InvalidParameterDataStructure;
use Method::ParamValidator::Exception::MissingRequiredParameter;
use Method::ParamValidator::Exception::MissingMethodName;
use Method::ParamValidator::Exception::MissingFieldName;
use Method::ParamValidator::Exception::UndefinedRequiredParameter;
use Method::ParamValidator::Exception::FailedParameterCheckConstraint;

use Moo;
use namespace::clean;

has 'fields'  => (is => 'rw');
has 'methods' => (is => 'rw');
has 'config'  => (is => 'ro', predicate => 1);

=head1 DESCRIPTION

It provides easy way to validate method parameters.It currently only supports two
supports two data types i.e. String and Integer.

=head1 SYNOPSIS

=head2 Setting up method validator manually.

    use strict; use warnings;
    use Test::More;
    use Method::ParamValidator;

    my $validator = Method::ParamValidator->new;
    $validator->add_field({ name => 'firstname', type => 's' });
    $validator->add_field({ name => 'lastname',  type => 's' });
    $validator->add_field({ name => 'age',       type => 'd' });
    $validator->add_field({ name => 'sex',       type => 's' });
    $validator->add_method({ name => 'add_user', fields => { firstname => 1, lastname => 1, age => 1, sex => 0 }});

    eval { $validator->is_ok('get_xyz'); };
    like($@, qr/Invalid method name received/);

    eval { $validator->is_ok('add_user'); };
    like($@, qr/Missing parameters/);

    eval { $validator->is_ok('add_user', []); };
    like($@, qr/Invalid parameters data structure/);

    eval { $validator->is_ok('add_user', { firstname => 'F', lastname => 'L', age => 'A' }); };
    like($@, qr/Parameter failed check constraint/);

    eval { $validator->is_ok('add_user', { firstname => 'F', lastname => 'L' }); };
    like($@, qr/Missing required parameter/);

    eval { $validator->is_ok('add_user', { firstname => 'F', lastname => undef }); };
    like($@, qr/Undefined required parameter/);

    eval { $validator->is_ok('add_user', { firstname => 'F' }); };
    like($@, qr/Missing required parameter/);

    done_testing();

=head2 Setting up method validator using configuration file.

Sample configuration file in JSON format.

    { "fields"  : [ { "name" : "firstname", "type" : "s" },
                    { "name" : "lastname",  "type" : "s" },
                    { "name" : "age",       "type" : "d" },
                    { "name" : "sex",       "type" : "s" }
                  ],
      "methods" : [ { "name"  : "add_user",
                      "fields": { "firstname" : "1",  "lastname" : "1", "age": "1", "sex" : "0" }
                    }
                  ]
    }

Then you just need one line to get everything setup using the above configuration file (config.json).

    use strict; use warnings;
    use Test::More;
    use Method::ParamValidator;

    my $validator = Method::ParamValidator->new({ config => "config.json" });

    eval { $validator->is_ok('get_xyz'); };
    like($@, qr/Invalid method name received/);

    eval { $validator->is_ok('add_user'); };
    like($@, qr/Missing parameters/);

    eval { $validator->is_ok('add_user', []); };
    like($@, qr/Invalid parameters data structure/);

    eval { $validator->is_ok('add_user', { firstname => 'F', lastname => 'L', age => 'A' }); };
    like($@, qr/Parameter failed check constraint/);

    eval { $validator->is_ok('add_user', { firstname => 'F', lastname => 'L' }); };
    like($@, qr/Missing required parameter/);

    eval { $validator->is_ok('add_user', { firstname => 'F', lastname => undef }); };
    like($@, qr/Undefined required parameter/);

    eval { $validator->is_ok('add_user', { firstname => 'F' }); };
    like($@, qr/Missing required parameter/);

    done_testing();

=head2 Hooking your own check method

It allows you to provide your own method for validating a field as shown below:

    use strict; use warnings;
    use Test::More;
    use Method::ParamValidator;

    my $validator = Method::ParamValidator->new;

    my $LOCATION = { 'USA' => 1, 'UK' => 1 };
    sub lookup { exists $LOCATION->{uc($_[0])} };

    $validator->add_field({ name => 'location', type => 's', check => \&lookup });
    $validator->add_method({ name => 'check_location', fields => { location => 1 }});

    eval { $validator->is_ok('check_location', { location => 'X' }); };
    like($@, qr/Parameter failed check constraint/);

    done_testing();

The above can be achieved using the configuration file as shown below:

    { "fields"  : [
                     { "name" : "location", "type" : "s", "source": [ "USA", "UK" ] }
                  ],
      "methods" : [
                     { "name"  : "check_location", "fields": { "location" : "1" } }
                  ]
    }

Using the above configuration file test the code as below:

    use strict; use warnings;
    use Test::More;
    use Method::ParamValidator;

    my $validator = Method::ParamValidator->new({ config => "config.json" });

    eval { $validator->is_ok('check_location', { location => 'X' }); };
    like($@, qr/Parameter failed check constraint/);

    done_testing();

=cut

sub BUILD {
    my ($self) = @_;

    if ($self->has_config) {
        my $data = do {
            open (my $fh, "<:encoding(utf-8)", $self->config);
            local $/;
            <$fh>
        };

        my $config = JSON->new->decode($data);

        my ($fields);
        foreach (@{$config->{fields}}) {
           my $source = {};
           if (exists $_->{source}) {
               foreach my $v (@{$_->{source}}) {
                   $source->{uc($v)} = 1;
               }
           }

           $self->add_field({
               name   => $_->{name},
               format => $_->{format},
               source => $source,
           });
        }

        foreach my $method (@{$config->{methods}}) {
            # TODO: if method already defined then skip
            $self->add_method($method);
        }
    }

    # TODO: throw exception if neither methods nor config passed in,
}

=head1 METHODS

=head2 is_ok($method_name, \%parameters)

Throws exception if validation fail.

=cut

sub is_ok {
    my ($self, $key, $values) = @_;

    my @caller = caller(0);
    @caller = caller(2) if $caller[3] eq '(eval)';

    Method::ParamValidator::Exception::InvalidMethodName->throw({
        method   => $key,
        filename => $caller[1],
        line     => $caller[2] }) unless (exists $self->{methods}->{$key});

    Method::ParamValidator::Exception::MissingParameters->throw({
        method   => $key,
        filename => $caller[1],
        line     => $caller[2] }) unless (defined $values);

    Method::ParamValidator::Exception::InvalidParameterDataStructure->throw({
        method   => $key,
        filename => $caller[1],
        line     => $caller[2] }) unless (ref($values) eq 'HASH');

    my $method = $self->{methods}->{$key};
    foreach my $field (keys %{$method->{fields}}) {
        if ($method->{fields}->{$field}->{required}) {
            Method::ParamValidator::Exception::MissingRequiredParameter->throw({
                method   => $key,
                field    => sprintf("(%s)", $field),
                filename => $caller[1],
                line     => $caller[2] }) unless (exists $values->{$field});
            Method::ParamValidator::Exception::UndefinedRequiredParameter->throw({
                method   => $key,
                field    => sprintf("(%s)", $field),
                filename => $caller[1],
                line     => $caller[2] }) unless (defined $values->{$field});
        }

        my $f = $method->{fields}->{$field}->{object};
        Method::ParamValidator::Exception::FailedParameterCheckConstraint->throw({
            method   => $key,
            field    => sprintf("(%s)", $field),
            filename => $caller[1],
            line     => $caller[2] }) if (defined $values->{$field} && !$f->valid($values->{$field}));
    }
}

=head2 query_param($method, \%values)

Returns the query param for the given method C<$method> and C<\%values>.

=cut

sub query_param {
    my ($self, $key, $values) = @_;

    my @caller = caller(0);
    @caller = caller(2) if $caller[3] eq '(eval)';

    Method::ParamValidator::Exception::MissingMethodName->throw({
        method   => 'query_param',
        filename => $caller[1],
        line     => $caller[2] }) unless (defined $key);

    Method::ParamValidator::Exception::InvalidMethodName->throw({
        method   => $key,
        filename => $caller[1],
        line     => $caller[2] }) unless (exists $self->{methods}->{$key});

    Method::ParamValidator::Exception::MissingParameters->throw({
        method   => $key,
        filename => $caller[1],
        line     => $caller[2] }) unless (defined $values);

    Method::ParamValidator::Exception::InvalidParameterDataStructure->throw({
        method   => $key,
        filename => $caller[1],
        line     => $caller[2] }) unless (ref($values) eq 'HASH');

    my $method = $self->{methods}->{$key};
    my $query_param = '';
    foreach my $field (keys %{$method->{fields}}) {
        if (exists $method->{fields}->{$field}) {
            my $_key = "&$key=%" . $self->get_field($field)->format;
            $query_param .= sprintf($_key, $values->{$field}) if defined $values->{$field};
        }
    }

    return $query_param;
}

=head2 add_field(\%param)

Add field to the validator.

=cut

sub add_field {
    my ($self, $param) = @_;

    $self->{fields}->{$param->{name}} = Method::ParamValidator::Key::Field->new($param);
}

=head2 get_field($name)

Returns an object of type L<Method::ParamValidator::Key::Field>, matching field name C<$name>.

=cut

sub get_field {
    my ($self, $name) = @_;

    my @caller = caller(0);
    @caller = caller(2) if $caller[3] eq '(eval)';

    Method::ParamValidator::Exception::MissingFieldName->throw({
        method   => 'get_field',
        filename => $caller[1],
        line     => $caller[2] }) unless (defined $name);

    return $self->{fields}->{$name};
}

=head2 add_method(\%param)

Add method to the validator.

=cut

sub add_method {
    my ($self, $param) = @_;

    my $method = { name => $param->{name} };
    foreach my $field (keys %{$param->{fields}}) {
        $method->{fields}->{$field}->{object}   = $self->{fields}->{$field};
        $method->{fields}->{$field}->{required} = $param->{fields}->{$field};
    }

    $self->{methods}->{$param->{name}} = Method::ParamValidator::Key::Method->new($method);
}

=head2 get_method($name)

Returns an object of type L<Method::ParamValidator::Key::Method>, matching method name C<$name>.

=cut

sub get_method {
    my ($self, $name) = @_;

    my @caller = caller(0);
    @caller = caller(2) if $caller[3] eq '(eval)';

    Method::ParamValidator::Exception::MissingMethodName->throw({
        method   => 'get_method',
        filename => $caller[1],
        line     => $caller[2] }) unless (defined $name);

    return $self->{methods}->{$name};
}

=head1 AUTHOR

Mohammad S Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/Manwar/Method-ParamValidator>

=head1 BUGS

Please report any  bugs or feature requests to C<bug-method-paramvalidator at rt.cpan.org>,
or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Method-ParamValidator>.
I will  be notified and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Method::ParamValidator

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Method-ParamValidator>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Method-ParamValidator>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Method-ParamValidator>

=item * Search CPAN

L<http://search.cpan.org/dist/Method-ParamValidator/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2015 Mohammad S Anwar.

This program  is  free software; you can redistribute it and / or modify it under
the  terms  of the the Artistic License (2.0). You may obtain  a copy of the full
license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any  use,  modification, and distribution of the Standard or Modified Versions is
governed by this Artistic License.By using, modifying or distributing the Package,
you accept this license. Do not use, modify, or distribute the Package, if you do
not accept this license.

If your Modified Version has been derived from a Modified Version made by someone
other than you,you are nevertheless required to ensure that your Modified Version
 complies with the requirements of this license.

This  license  does  not grant you the right to use any trademark,  service mark,
tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge patent license
to make,  have made, use,  offer to sell, sell, import and otherwise transfer the
Package with respect to any patent claims licensable by the Copyright Holder that
are  necessarily  infringed  by  the  Package. If you institute patent litigation
(including  a  cross-claim  or  counterclaim) against any party alleging that the
Package constitutes direct or contributory patent infringement,then this Artistic
License to you shall terminate on the date that such litigation is filed.

Disclaimer  of  Warranty:  THE  PACKAGE  IS  PROVIDED BY THE COPYRIGHT HOLDER AND
CONTRIBUTORS  "AS IS'  AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES. THE IMPLIED
WARRANTIES    OF   MERCHANTABILITY,   FITNESS   FOR   A   PARTICULAR  PURPOSE, OR
NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY YOUR LOCAL LAW. UNLESS
REQUIRED BY LAW, NO COPYRIGHT HOLDER OR CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT,
INDIRECT, INCIDENTAL,  OR CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE
OF THE PACKAGE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

1; # End of Method::ParamValidator
