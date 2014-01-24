Ensembl.Panel.LocalContext = Ensembl.Panel.LocalContext.extend({
  relocateTools: function () {
    this.base.apply(this, arguments);

    var toolButtons = $('.tool_buttons', this.el);

    $('a.seq_ena', toolButtons).on('click', function () {
      $('form.seq_ena', toolButtons).submit();
      return false;
    });
  }
});