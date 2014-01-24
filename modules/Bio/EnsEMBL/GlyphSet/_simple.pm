package Bio::EnsEMBL::GlyphSet::_simple;

use strict;

sub label_overlay { return 1; }
sub feature_label { return undef unless ($_[0]->my_config('show_labels') eq 'yes'); return $_[1]->display_label; }

sub title {
  my ($self, $f)    = @_;
  my ($start, $end) = $self->slice2sr($f->start, $f->end);
  my $score_label = $self->my_config('score_label') || 'score';
  my $score = $f->score ? sprintf('%s: %s;', $score_label, $f->score) : '';
  return sprintf '%s: %s; %s bp: %s', $f->analysis->logic_name, $f->display_label, $score, "$start-$end";
}

1;
