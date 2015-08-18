#!perl

use 5.006;
use strict; use warnings;

use Test::More;
use Method::ParamValidator;

my $validator = Method::ParamValidator->new({ config => "t/config.json" });

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

eval { $validator->is_ok('add_user', { firstname => 'F', lastname => 'L', age => 40, location => 'X' }); };
like($@, qr/Parameter failed check constraint/);

eval { $validator->is_ok('add_user', { firstname => 'F', lastname => 'L', age => 40, location => 'UK' }); };
like($@, qr//);

eval { $validator->is_ok('add_user', { firstname => 'F', lastname => 'L', age => 40, location => 'uk' }); };
like($@, qr//);

done_testing();
