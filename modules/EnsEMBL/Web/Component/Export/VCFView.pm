package EnsEMBL::Web::Component::Export::VCFView;

use base 'EnsEMBL::Web::Component::Export';
use Data::Dumper;

sub _init {
    my $self = shift;
    $self->cacheable(0);
    $self->ajaxable(1);
}

sub content {
  my $self  = shift;
  my $hub   = $self->hub;
  my $pos   = $hub->param('pos');  
  my $vcf   = $hub->param('vcf');
  my $object = $self->object;
  my $species  = $object->{data}->{'_referer'}->{ENSEMBL_SPECIES};

  return qq{ <div class="ajax genotype_panel">
             <input type="hidden"  class="ajax_load" name="genotype$pos" value="/genotype?pos=$pos;vcf=$vcf;sp=$species;" />
             </div>};

}

1;
