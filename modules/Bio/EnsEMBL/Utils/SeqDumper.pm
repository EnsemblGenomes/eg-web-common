=head1 LICENSE

Copyright [2009-2014] EMBL-European Bioinformatics Institute

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


package Bio::EnsEMBL::Utils::SeqDumper;

use strict;
use Bio::EnsEMBL::Utils::Exception qw(throw warning);

my @COMMENTS = 
   ('This sequence displays annotation from Ensembl Genomes, based on '.
    'underlying annotation from ###SOURCE###. '.
    'See http://www.ensemblgenomes.org for more information. ',
   'All feature locations are relative to the first (5\') base ' .
   'of the sequence in this file.  The sequence presented is '.
   'always the forward strand of the assembly. Features ' .
   'that lie outside of the sequence contained in this file ' .
   'have clonal location coordinates in the format: ' .
   '<clone accession>.<version>:<start>..<end>',

   'The /gene indicates a unique id for a gene, /note="transcript_id=..."' . 
   ' a unique id for a transcript, /protein_id a unique id for a peptide ' .
   'and note="exon_id=..." a unique id for an exon. These ids are ' .
   'maintained wherever possible between versions.'
);


## EG : use full species name + modified comment
sub dump_embl {
  my $self = shift;
  my $slice = shift;
  my $FH   = shift;

  my $len = $slice->length;

  my $version;
  my $acc;

  my $cs = $slice->coord_system();
  my $name_str = $cs->name() . ' ' . $slice->seq_region_name();
  $name_str .= ' ' . $cs->version if($cs->version);

  my $start = $slice->start;
  my $end   = $slice->end;

  #determine if this slice is the entire seq region
  #if it is then we just use the name as the id
  my $slice_adaptor = $slice->adaptor();
  my $full_slice =
    $slice->adaptor->fetch_by_region($cs->name,
                                    $slice->seq_region_name,
                                    undef,undef,undef,
                                    $cs->version);


  my $entry_name = $slice->seq_region_name();



  if($full_slice->name eq $slice->name) {
    $name_str .= ' full sequence';
    $acc = $slice->seq_region_name();
    my @acc_ver = split(/\./, $acc);
    if(@acc_ver == 2) {
      $acc = $acc_ver[0];
      $version = $acc_ver[0] . '.'. $acc_ver[1];
    } elsif(@acc_ver == 1 && $cs->version()) {
      $version = $acc . '.'. $cs->version();
    } else {
      $version = $acc;
    }
  } else {
    $name_str .= ' partial sequence';
    $acc = $slice->name();
    $version = $acc;
  }

  $acc = $slice->name();



  #line breaks are allowed near the end of the line on ' ', "\t", "\n", ',' 
  $: = (" \t\n-,");

  #############
  # dump header
  #############
  
  # move at the end of file in case the file
  # is open more than once (i.e. human chromosome Y, 
  # two chromosome slices
  #
  # WARNING
  #
  # When the file is open not for the first time,
  # it must be in read/write mode
  #
  seek($FH, 0, SEEK_END);
  
  my $EMBL_HEADER = 
'@<   ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<~
';

  #ID and moltype
  # HTG = High Throughput Genome division, probably most suitable
  #       and it would be hard to come up with another appropriate division
  #       that worked for all organisms (e.g. plants are in PLN but human is
  #       in HUM).
  my $VALUE = "$entry_name    standard; DNA; HTG; $len BP.";
  $self->write($FH, $EMBL_HEADER, 'ID', $VALUE);  
  $self->print( $FH, "XX\n" );

  #Accession
  $self->write($FH, $EMBL_HEADER, 'AC', $acc);
  $self->print( $FH, "XX\n" );

  #Version
  $self->write($FH, $EMBL_HEADER, 'SV', $version);
  $self->print( $FH, "XX\n" );

  #Date
  $self->write($FH, $EMBL_HEADER, 'DT', $self->_date_string);
  $self->print( $FH, "XX\n" );
  
  
  my $meta_container = $slice->adaptor()->db()->get_MetaContainer();

  #Description
## EG : 
  my $providers  =  join ' ,',  @{ $meta_container->list_value_by_key('provider.name') };
  
  $self->write($FH, $EMBL_HEADER, 'DE', $meta_container->get_scientific_name() .
               " $name_str $start..$end " . ($providers ? "annotated by $providers" : ''));
  $self->print( $FH, "XX\n" );

  #key words
  $self->write($FH, $EMBL_HEADER, 'KW', '.');
  $self->print( $FH, "XX\n" );

  #Species
  my $species_name = $meta_container->get_scientific_name();
  if(my $cn = $meta_container->get_common_name()) {
    $species_name .= " ($cn)";
  }

  $self->write($FH, $EMBL_HEADER, 'OS', $species_name);

  #Classification
  my @cls = @{$meta_container->get_classification()};
  $self->write($FH, $EMBL_HEADER, 'OC', join('; ', reverse(@cls)) . '.');
  $self->print( $FH, "XX\n" );
  
  #References (we are not dumping refereneces)

  #Database References (we are not dumping these)

  my $ds = $self->{_data_source} || 'EMBL';
  #comments

  foreach my $comment (@COMMENTS) {
      $comment =~ s/\#\#\#SOURCE\#\#\#/$ds/;

    $self->write($FH, $EMBL_HEADER, 'CC', $comment);
    $self->print( $FH, "XX\n" );
  }

  ####################
  #DUMP FEATURE TABLE
  ####################
  $self->print( $FH, "FH   Key             Location/Qualifiers\n" );

  my $FEATURE_TABLE = 
'FT   ^<<<<<<<<<<<<<<<^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<~
';
  $self->_dump_feature_table($slice, $FH, $FEATURE_TABLE);  

  #write an XX after the feature tables
  $self->print( $FH, "XX\n" );

  ###################
  # DUMP SEQUENCE
  ###################

  # record position before writing sequence header, so that 
  # after printing the sequence and having the base counts
  # we can seek to this position and write the proper sequence 
  # header
  my $sq_offset = tell($FH);
  $sq_offset == -1 and throw "Unable to get offset for output fh";

  # print a sequence header template, to be replaced with a real
  # one containing the base counts
  $self->print($FH, "SQ   Sequence ########## BP; ########## A; ########## C; ########## G; ########## T; ########## other;\n");
  
  # dump the sequence and get the base counts
  my $acgt = $self->write_embl_seq($slice, $FH);
  
  # print the end of EMBL entry
  $self->print( $FH, "//\n" );
  my $end_of_entry_offset = tell($FH);
  $end_of_entry_offset == -1 and throw "Unable to get offset for output fh";

  # seek backwards to the position of the sequence header and 
  # write it with the actual base counts
  seek($FH, $sq_offset, SEEK_SET) 
    or throw "Cannot seek backward to sequence header position";
  $self->print($FH, sprintf "SQ   Sequence %10d BP; %10d A; %10d C; %10d G; %10d T; %10d other;", 
    $acgt->{tot}, $acgt->{a}, $acgt->{c}, $acgt->{g}, $acgt->{t}, $acgt->{n});

  # move forward to end of file to dump the next slice
  seek($FH, $end_of_entry_offset, SEEK_SET) 
    or throw "Cannot seek forward to end of entry";

  # Set formatting back to normal
  $: = " \n-";
}

## EG : use full species name + modified comment

sub dump_genbank {
  my ($self, $slice, $FH) = @_;

  #line breaks are allowed near the end of the line on ' ', "\t", "\n", ',' 
  $: = " \t\n-,";

  my $GENBANK_HEADER = 
'^<<<<<<<<<  ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<~~
';

  my $GENBANK_SUBHEADER =
'  ^<<<<<<<  ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<~~
';

  my $GENBANK_FT =
'     ^<<<<<<<<<<<<<< ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<~~
';

  my $version;
  my $acc;

  my $cs = $slice->coord_system();

  my $name_str = $cs->name() . ' ' . $slice->seq_region_name();

  $name_str .= ' ' . $cs->version if($cs->version);

  #determine if this slice is the entire seq region
  #if it is then we just use the name as the id
  my $slice_adaptor = $slice->adaptor();
  my $full_slice =
    $slice->adaptor->fetch_by_region($cs->name,
                                    $slice->seq_region_name,
                                    undef,undef,undef,
                                    $cs->version);


  my $entry_name = $slice->seq_region_name();

  if($full_slice->name eq $slice->name) {
    $name_str .= ' full sequence';
    $acc = $slice->seq_region_name();
    my @acc_ver = split(/\./, $acc);
    if(@acc_ver == 2) {
      $acc = $acc_ver[0];
      $version = $acc_ver[0] . $acc_ver[1];
    } elsif(@acc_ver == 1 && $cs->version()) {
      $version = $acc . $cs->version();
    } else {
      $version = $acc;
    }
  } else {
    $name_str .= ' partial sequence';
    $acc = $slice->name();
    $version = $acc;
  }

  $acc = $slice->name();     # to keep format consistent for all

  my $length = $slice->length;
  my $start = $slice->start();
  my $end   = $slice->end();

  my $date = $self->_date_string;

  my $meta_container = $slice->adaptor()->db()->get_MetaContainer();

  # move at the end of file in case the file
  # is open more than once (i.e. human chromosome Y, 
  # two chromosome slices
  #
  # WARNING
  #
  # When the file is open not for the first time,
  # it must be in read/write mode
  #
  seek($FH, 0, SEEK_END);

  #LOCUS
  my $tag   = 'LOCUS';
  my $value = "$entry_name $length bp DNA HTG $date";
  $self->write($FH, $GENBANK_HEADER, $tag, $value);

  #DEFINITION
  $tag   = "DEFINITION";
  $value = $meta_container->get_scientific_name() .
    " $name_str $start..$end reannotated via EnsEMBL";
  $self->write($FH, $GENBANK_HEADER, $tag, $value);

  #ACCESSION
  $self->write($FH, $GENBANK_HEADER, 'ACCESSION', $acc);

  #VERSION
  $self->write($FH, $GENBANK_HEADER, 'VERSION', $version);

  # KEYWORDS
  $self->write($FH, $GENBANK_HEADER, 'KEYWORDS', '.');

  # SOURCE
  my $common_name = $meta_container->get_common_name();
  $common_name = $meta_container->get_scientific_name() unless $common_name;
  $self->write($FH, $GENBANK_HEADER, 'SOURCE', $common_name);

  #organism
  my @cls = @{$meta_container->get_classification()};
  shift @cls;
  $self->write($FH, $GENBANK_SUBHEADER, 'ORGANISM', $meta_container->get_scientific_name());
  $self->write($FH, $GENBANK_SUBHEADER, '', join('; ', reverse @cls) . ".");
  
  #refereneces

  #comments
  my $ds = $self->{_data_source} || 'EMBL';
  foreach my $comment (@COMMENTS) {
      $comment =~ s/###SOURCE###/$ds/;
    $self->write($FH, $GENBANK_HEADER, 'COMMENT', $comment);
  }

  ####################
  # DUMP FEATURE TABLE
  ####################
  $self->print( $FH, "FEATURES             Location/Qualifiers\n" );
  $self->_dump_feature_table($slice, $FH, $GENBANK_FT);

  ####################
  # DUMP SEQUENCE
  ####################

  # record position before writing sequence header, so that 
  # after printing the sequence and having the base counts
  # we can seek to this position and write the proper sequence 
  # header
  my $sq_offset = tell($FH);
  $sq_offset == -1 and throw "Unable to get offset for output fh";

  # print a sequence header template, to be replaced with a real
  # one containing the base counts
  $self->print($FH, "BASE COUNT  ########## a ########## c ########## g ########## t ########## n\nORIGIN\n");
  
  # dump the sequence and get the base counts
  my $acgt = $self->write_genbank_seq($slice, $FH);
  
  # print the end of genbank entry
  $self->print( $FH, "//\n" );
  my $end_of_entry_offset = tell($FH);
  $end_of_entry_offset == -1 and throw "Unable to get offset for output fh";

  # seek backwards to the position of the sequence header and 
  # write it with the actual base counts
  seek($FH, $sq_offset, SEEK_SET) 
    or throw "Cannot seek backward to sequence header position";
  $self->print($FH, sprintf "BASE COUNT  %10d a %10d c %10d g %10d t %10d n", 
         $acgt->{a}, $acgt->{c}, $acgt->{g}, $acgt->{t}, $acgt->{n});

  seek($FH, $end_of_entry_offset, SEEK_SET) 
    or throw "Cannot seek forward to end of entry";

  # Set formatting back to normal
  $: = " \n-";
}



1;   
