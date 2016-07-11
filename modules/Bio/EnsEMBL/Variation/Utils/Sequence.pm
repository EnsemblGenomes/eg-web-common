=head1 LICENSE

Copyright [2009-2016] EMBL-European Bioinformatics Institute

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut


=head1 CONTACT

 Please email comments or questions to the public Ensembl
 developers list at <dev@ensembl.org>.

 Questions may also be sent to the Ensembl help desk at
 <helpdesk@ensembl.org>.

=cut

# EnsEMBL module for Bio::EnsEMBL::Variation::Utils::Sequence
#
#

=head1 NAME

Bio::EnsEMBL::Variation::Utils::Sequence - Utility functions for sequences

=head1 SYNOPSIS

  use Bio::EnsEMBL::Variation::Utils::Sequence qw(ambiguity_code variation_class);

  my $alleles = 'A|C';

  print "my alleles = $alleles\n";

  my $ambig_code = ambiguity_code($alleles);

  print "my ambiguity code is $ambig_code\n";

  print "my SNP class is = variation_class($alleles)";


=head1 METHODS

=cut


use strict;
use warnings;

package Bio::EnsEMBL::Variation::Utils::Sequence;

use Bio::EnsEMBL::Utils::Exception qw(warning);

## EG - ovewrite the functions below .. 
sub ambiguity_code {
    my $alleles = shift;
    my %duplicates; #hash containing all alleles to remove duplicates
    map {$duplicates{$_}++} split /[\|\/\\]/, $alleles;
    $alleles = uc( join '', sort keys %duplicates );
    #my %ambig = qw(AC M ACG V ACGT N ACT H AG R AGT D AT W CG S CGT B CT Y 
#GT K C C A A T T G G - - -A -A -C -C -G -G -T -T A- A- C- C- G- G- T- T-); #for now just make e.g. 'A-' -> 'A-'
	my %ambig = qw(AC M ACG V ACGT N ACT H AG R AGT D AT W CG S CGT B CT Y GT K C C A A T T G G - -);

    my $ambig_code = ($ambig{$alleles} ? $ambig{$alleles} : '');

    if ($ambig_code eq '' && length($alleles) == 1)
    {
        $ambig_code = $alleles;
    }

    return($ambig_code);
}

sub variation_class {

    my ($alleles, $is_somatic) = @_;

    my $class;

    if ($alleles =~ /^[ACGTN]([\|\\\/][A-Z])+$/i) {
	$class = 'snp';
    }
    elsif (($alleles eq 'cnv') || ($alleles eq 'CNV')) {
	$class = 'cnv';
    }
    elsif ($alleles =~ /CNV\_PROBE/i) {
	$class = 'cnv probe';
    }
    elsif ($alleles =~ /HGMD\_MUTATION/i) {
	$class = 'hgmd_mutation';
    }
    else {
	my @alleles = split /[\|\/\\]/, $alleles;

	if (@alleles == 1) {
           #(HETEROZYGOUS) 1 allele
	    $class =  'het';
	}
	elsif(@alleles == 2) {
              if ((($alleles[0] =~ tr/ACTGN//)== length($alleles[0]) && ($alleles[1] =~ tr/-//) == 1) ||
                  (($alleles[0] =~ tr/-//) == 1 && ($alleles[1] =~ tr/ACTGN//) == length($alleles[1])) ){
                  #A/- 2 alleles
                  $class =  'in-del'
		  }
              elsif (($alleles[0] =~ /LARGE|INS|DEL/) || ($alleles[1] =~ /LARGE|INS|DEL/)){
                  #(LARGEDELETION) 2 alleles
                  $class = 'named'
		  }
              elsif (($alleles[0] =~ tr/ACTG//) > 1 || ($alleles[1] =~ tr/ACTG//) > 1){
                  #AA/GC 2 alleles
                  $class = 'substitution'
		  }
              else {
                  warning("not possible to determine class for  @alleles");
                  $class = '';
              }
	  }
	elsif (@alleles > 2) {

	    if ($alleles[0] =~ /\d+/) {
                  #(CA)14/15/16/17 > 2 alleles, all of them contain the number of repetitions of the allele
                  $class = 'microsat'
		  }

	    elsif ((grep {/-/} @alleles) > 0) {
                  #-/A/T/TTA > 2 alleles
                  $class = 'mixed'
		  }
	    else {
                  #  warning("not possible to determine class of alleles " . @alleles);
		$class = '';
	    }
	}
	else{
	    warning("no alleles available ");
	    $class = '';
	}
    }

    if ($is_somatic) {
	if ($class eq '') {
           # for undetermined classes just call it somatic
	    $class = 'somatic';
	}
	else {
           # somatic mutations aren't polymorphisms, so change SNPs to SNVs
	    $class = 'snv' if $class eq 'snp';

           # and prefix the class with 'somatic'
	    $class = 'somatic_'.$class;
	}
    }

    return $class;
} 

1;
