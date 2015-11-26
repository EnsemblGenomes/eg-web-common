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

  // add ajax species selector

  init: function() {
    this.base();
    
    $('select.ajax-species-selector').each(function(){ $(this).ajaxSpeciesSelector() });

    var panel = this;

    // Change the input value on click of the examples link
    this.elLk.form.find('a._example_input').off('click').on('click', function(e) {
      console.log('EG click');
      e.preventDefault();

      var species = $('select.ajax-species-selector').val();
      console.log('sp', species);

      var text = panel.exampleData[species][this.rel];
      if(typeof(text) === 'undefined' || !text.length) text = "";
      text = text.replace(/\\n/g, "\n");
    
      panel.elLk.dataField.val(text).trigger('change');
    });

  }
});
