package Hash::CoerceToArray;

use 5.010001;
use strict;

use Exporter;
our @ISA     = qw/Exporter/;
our $VERSION = '0.01';

use Carp qw/croak/;

our @EXPORT_OK = qw/coerceArray getMaxDepth/;

our ($hashRefLocal,$depth);
sub coerceArray {
    my ($hashRef, $givenDepth) = @_;

    ## This would be changed in called functions
    ## hence 'local' declaration
    local $hashRefLocal = $hashRef;  ## This would be 

    ## die if not a HASH REFERENCE    
    if (ref($hashRefLocal) ne 'HASH') {
        croak "Please provide a HashRef\n";
    }

    ## Use the maximum depth if not given one
    ## This depth should be accessible to all local functions
    ## hence 'local' declaration       
    local $depth = getMaxDepth($hashRefLocal) if (!$givenDepth);
    $depth = $givenDepth if($givenDepth);

    ## Recursive iteration to go where HASH REFERENCE
    ## to ARRAY REFERENCE coercion is sought
    my $counter = 1;
    foreach my $rec (keys %$hashRefLocal) {
        _goDeepAndCoerce($$hashRefLocal{$rec},$counter,$rec);
    }

    return $hashRefLocal;

}

sub _goDeepAndCoerce {
    my ($hashRef,$counter,$key) = @_;

    if ($depth == ($counter+1)) {

        ## Keys would be used as breadcrumb
        ## to change the key value at any level
        my $keyString = '$hashRefLocal->';

        foreach my $rec (split /\:/, $key) {
            $keyString .= "{'$rec'}";
        } 

        ## Put the key, values as elements to an ARRAY
        my $arrayRef;
        if(!ref $hashRef) {
            $arrayRef = $hashRef;
        }
        else {
            while(my ($keyLocal, $valueLocal) = each %$hashRef) {
                push @$arrayRef, $keyLocal, $valueLocal;
            }
        }

        ## Do in-place replacement and return
        eval "$keyString = \$arrayRef";
        return;
    }

    return if (ref ($hashRef) ne 'HASH');

    $counter++; 
    foreach my $rec (keys %$hashRef) {
        _goDeepAndCoerce($$hashRef{$rec},$counter,"$key:$rec");
    }
}

sub getMaxDepth {
    my ($hashRef) = @_;

    ## Used to keep track which key at certain level
    ## has value with maximum depth
    my $max_depth_this_level;

    foreach my $rec (keys %$hashRef) {
        ## Increment and recursively call getMaxDepth
        ## If value is a hash refearence
        if (ref($$hashRef{$rec}) eq 'HASH') {
            $$max_depth_this_level{$rec} = 1+getMaxDepth($$hashRef{$rec})
        }
        else {
            $$max_depth_this_level{$rec} = 1;
        }
    }
    
    ## Return the maximum depth as obtained in one level
    my $max_depth = (sort {$b<=>$a} values %$max_depth_this_level)[0];

    return $max_depth;
}

1;

=head1 NAME

Hash::CoerceToArray - Find the depth of any multi-hierarchical HASH REFERENCE structure
                    - Go to any level of the HASH REFERENCE randomly and convert the value 
                      against a key to an ARRAY REFERENCE if it is HASH REFERENCE
                       
=head1 SYNOPSIS

  use Hash::CoerceToArray qw /coerceArray getMaxDepth/;
  
  my $maxDepth = getMaxDepth (\%hash);

  my $hashRef = coerceArray(\%hash);
  my $hashRef = coerceArray(\%hash, $maxDepth);

  
  map {$hashRef = coerceArray($hashRef,$_);} (1..$maxDepth)
  
=head1 ABSTRACT

  This module allow the user the user to get maximum depth of a HASH REFERENCE
  variable in a multilevel structure where values are HASH REFERENCES themselves.

  Also, user is allowed to change the HASH REFERENCE value at any level randomly
  to an ARRAY REFERENCE. By selecting the deepest level of the HASH REFERENCE
  structure first and calling coerceArray() subroutine from thereon to depth level
  of 1 sequentially, user can change the whole HASH REFERENCE structure
  to an ARRAY REFERENCE hierarchy. 

=head1 DESCRIPTION

  Example HashRef.

  my $hashRef = { 'L1_1' => {'L2_1' => {'L3_1' => 'V1',
                                     'L3_2' => 'V2',
                                     'L3_3' => 'V3'
                                    },
                          'L2_2' => {'L3_1' => {'L4_1' => 'V1',
                                                'L4_2' => 'V2',
                                               },
                                    },
                         },
              };
  print getMaxDepth($hashRef)
  >>>> 4

  $hashRef = coerceArray($hashRef);
  print Dumper $hashRef; 
  >>>>>
       { 
          'L1_1' => {
                      'L2_1' => {
                                  'L3_2' => 'V2',
                                  'L3_3' => 'V3',
                                  'L3_1' => 'V1'
                                },
                      'L2_2' => {
                                  'L3_1' => [
                                              'L4_1',
                                              'V1',
                                              'L4_2',
                                              'V2'
                                            ]
                                }
                    }
        }; 

  $hashRef = coerceArray($hashRef,2);
  print Dumper $hashRef;
  >>>>>
       {
          'L1_1' => [
                      'L2_1',
                      {
                        'L3_2' => 'V2',
                        'L3_3' => 'V3',
                        'L3_1' => 'V1'
                      },
                      'L2_2',
                      {
                        'L3_1' => [
                                    'L4_1',
                                    'V1',
                                    'L4_2',
                                    'V2'
                                  ]
                      }
                    ]
        };

=head1 CAVEATS

  The coerceArray() routine as of now works only if the Hash References are found continuously,
  if any other reference like Array References occur in between, it won't work as desired.

  Eg. take the following Hash Reference which has Array Reference at Level 1

      {
          'L1_1' => [
                      'L2_1',
                      {
                        'L3_2' => 'V2',
                        'L3_3' => 'V3',
                        'L3_1' => 'V1'
                      },
                      'L2_2',
                      {
                        'L3_1' => [
                                    'L4_1',
                                    'V1',
                                    'L4_2',
                                    'V2'
                                  ]
                      }
                    ]
        }; 
  Now here $hashRef = coerceArray($hashRef,2);
           print Dumper $hashRef; - won't work as desired.
  I will look to improve it in a future release.

=head1 SUPPORT

  debashish@cpan.org

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2013 Debashish Parasar, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
