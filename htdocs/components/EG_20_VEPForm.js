/*
 * Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
 * 
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 * 
 *      http://www.apache.org/licenses/LICENSE-2.0
 * 
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

Ensembl.Panel.VEPForm = Ensembl.Panel.VEPForm.extend({

  init: function() {
    this.base();
    
    
    //EG Start - Adding AJAX type species selector to VEP form
    $('select.ajax-species-selector').each(function(){ $(this).ajaxSpeciesSelector() });
    //EG End

    this.resetSpecies(this.elLk.form.find('input[name=default_species]').remove().val());

    this.previewData = JSON.parse(this.params['preview_data']);
    delete this.params['preview_data'];
    
    this.exampleData = JSON.parse(this.params['example_data']);
    delete this.params['example_data'];

    // this.autocompleteData = JSON.parse(this.params['plugin_auto_values']);
    // delete this.params['plugin_auto_values'];

    var panel = this;

    // Change the input value on click of the examples link
    this.elLk.form.find('a._example_input').on('click', function(e) {
      e.preventDefault();

      var species = panel.elLk.form.find('input[name=species]:checked').val();
      var text = panel.exampleData[species][this.rel];
      if(typeof(text) === 'undefined' || !text.length) text = "";
      text = text.replace(/\\n/g, "\n");
    
      panel.elLk.dataField.val(text).trigger('change');
    });

    // Preview button
    this.elLk.previewButton = panel.elLk.form.find('[name=preview]').hide().on('click', function(e) {
      e.preventDefault();
      panel.preview();
    });

    // Preview div
    this.elLk.previewDiv = $('<div class="top-margin">').appendTo(this.elLk.previewButton.parent()).hide();

    // show hide preview button acc to the text in the input field
    this.elLk.dataField = this.elLk.form.find('textarea[name=text]').on({
      'input paste keyup click change': function(e) {

        panel.elLk.previewButton.toggle(!!this.value.length);

        if ($(this).data('previousValue') === this.value) {
          return;
        } else {
          $(this).data('previousValue', this.value);
        }

        if (!!this.value.length) {

          // check format
          var format      = panel.detectFormat(this.value.split(/[\r\n]+/)[0]);
          var enablePrev  = format === 'id' || format === 'vcf' || format === 'ensembl' || format === 'hgvs';

          panel.elLk.previewButton.toggleClass('disabled', !enablePrev).prop('disabled', !enablePrev);
        }
      }
    });
    
    this.elLk.form.find('.plugin_enable').change(function() {

      panel.elLk.form.find('.plugin-highlight').removeClass('plugin-highlight');

      // find any sub-fields enabling this plugin shows
      panel.elLk.form.find('._stt_' + this.name).addClass('plugin-highlight', 100, 'linear');
    });

    // also remove highlighting when option changes
    this.elLk.form.find('.plugin_enable').each(function() {
      panel.elLk.form.find('._stt_' + this.name).find(':input').change(function() {
        panel.elLk.form.find('.plugin-highlight').removeClass('plugin-highlight');
      });
    });

    this.editExisting();
  }
});
