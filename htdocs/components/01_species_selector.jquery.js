/*
 Description:   Reusable species selector component
 Dependencies:  chosen.jquery.js, chosen-ajaxadition.js
 Useage:        $('select').speciesSelect();
*/

(function ($) {
  
  var chosenDefaults = {
    enable_split_word_search: false,
    search_contains: true,
    placeholder_text_single: 'Select a species...'
  };
  
  //---------------------------------------------------------------------------
  // Chosen inline selector
  //---------------------------------------------------------------------------
  
  $.fn.speciesSelector = function (options) {
    var settings = $.extend({}, chosenDefaults, options);
    return $(this).chosen(settings)
  };
  
  //---------------------------------------------------------------------------
  // Chosen ajax selector 
  //---------------------------------------------------------------------------
  
  $.fn.ajaxSpeciesSelector = function (options, chosenOptions) {
       
    var defaults = {
      minLength: 3,
      processItems: function(data){ 
        var results = [];
        $.each(data.results, function (i, val) {
          results.push({ 
            id:   val.production_name, 
            text: val.value 
          });
        });
        return results;  
      },
      generateUrl: function(q){ 
        return '/Multi/Ajax/species_autocomplete?result_format=chosen&term=' + q 
      },
      loadingImg: '/i/chosen-loading.gif'
    };
    
    var settings = $.extend({}, defaults, options);
    var chosenSettings = $.extend({}, chosenDefaults, chosenOptions);
    
    var ajaxSettings = { 
      dataType: 'json', 
      type: 'GET' 
    };   
    
    return $(this).ajaxChosen(ajaxSettings, settings, chosenSettings)
  };
  
})(jQuery);
