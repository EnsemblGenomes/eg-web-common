// $Revision: 1.7 $

Ensembl.Panel.SpeciesList = Ensembl.Panel.extend({  
  init: function () {
    this.base();
    
    var ac = $("#species_autocomplete", this.el);
    ac.autocomplete({
      minLength: 3,
      source:   '/Multi/Ajax/species_autocomplete',
      select:   function(event, ui) { if (ui.item) Ensembl.redirect('/' + ui.item.production_name + '/Info/Index') },
      search:   function() { ac.addClass('loading') },
      response: function(event, ui) {
        ac.removeClass('loading');
        if (ui.content.length || ac.val().length < 3) {
          ac.removeClass('invalid');
        } else {
          ac.addClass('invalid');
        } 
      }
    }).focus(function(){
      // add placeholder text
      if($(this).val() == $(this).attr('title')) {
        ac.val('');
        ac.removeClass('inactive');
      } else if($(this).val() != '')  {
        ac.autocomplete('search');
      }
    }).blur(function(){
      // remove placeholder text
      ac.removeClass('invalid');
      ac.addClass('inactive');
      ac.val($(this).attr('title'));
    }).keyup(function(){
      ac.removeClass('invalid');
    }).data("ui-autocomplete")._renderItem = function (ul, item) {
      // highlight the term within each match
      var words = this.term.split(/\s+/);
      for (var i = 0; i < words.length; i++) {
        var word = words[i];
        var regex = new RegExp("(?![^&;]+;)(?!<[^<>]*)(" + $.ui.autocomplete.escapeRegex(word) + ")(?![^<>]*>)(?![^&;]+;)", "gi");
        item.label = item.label.replace(regex, "<strong>$1</strong>");
      }
      return $("<li></li>").data("ui-autocomplete-item", item).append("<a>" + item.label + "</a>").appendTo(ul);
    };
    
    $(window).bind("unload", function() {}); // hack - this forces page to reload if user returns here via the Back Button

  }
});
