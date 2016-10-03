=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016] EMBL-European Bioinformatics Institute

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

package ORM::EnsEMBL::DB::Accounts::Object::Record;

### NAME: ORM::EnsEMBL::DB::Accounts::Object::Record
### ORM class for the record table in user db

use strict;
use warnings;

use ORM::EnsEMBL::Utils::Helper qw(random_string load_package);

use parent qw(ORM::EnsEMBL::DB::Accounts::Object);

use constant TABLE_NAME => 'all_record';

my $VIRTUAL_COLUMNS = {
  'history'           => [qw(object value url name species param)],
  'bookmark'          => [qw(name description url object click)],
  'specieslist'       => [qw(favourites list)],
  'urls'              => [qw(format cloned_from)],
  'invitation'        => [qw(invitation_code email)],
  'upload'            => [qw(file filename filesize name description md5 format species assembly assemblies share_id analyses browser_switches renderers style display nearest site timestamp cloned_from no_attach)],
  'favourite_tracks'  => [qw(tracks)],
## EG  
  'genefamilyfilter'  => [qw(filter)],
##  
};

__PACKAGE__->_meta_setup;

sub _meta_setup {
  ## Initialises database schema
  my $class = shift;
  my $meta  = $class->meta;

  # Setup meta object using the setup method from session record table (MI on objects does not work with Rose objects)
  load_package('ORM::EnsEMBL::DB::Session::Object::Record')->can('_meta_setup')->($class);

  $meta->column('record_type')->values(['user', 'group']);
  $meta->column('record_type')->constraint_values(['user', 'group']);
  $meta->virtual_columns(map {$_ => {'column' => 'data'}} keys %{{ map { map {$_ => 1} @$_ } values %$VIRTUAL_COLUMNS }}),
  $meta->trackable(1);
}

sub get_invitation_code {
  ## For invitation record only for record_type group
  ## Gets a url code for invitation type group record
  ## @return Code string
  return sprintf('%s-%s', $_[0]->invitation_code, $_[0]->record_id);
}

sub reset_invitation_code_and_save {
  ## For invitation record only for record_type group
  ## Resets the code and saves the object
  ## @params Same as save method
  my $self = shift;
  $self->invitation_code(random_string(10));
  return $self->save(@_);
}

1;
