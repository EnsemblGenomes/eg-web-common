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
if (Ensembl.Panel.VEPForm) {
  Ensembl.Panel.VEPForm = Ensembl.Panel.VEPForm.extend({

    // add ajax species selector

    init: function() {
      this.base();
      
      var ajaxSelector = $('select.ajax-species-selector');

      if (ajaxSelector[0]) {

        ajaxSelector.ajaxSpeciesSelector();

        var panel = this;

        // Change the input value on click of the examples link
        this.elLk.form.find('a._example_input').off('click').on('click', function(e) {
          e.preventDefault();

          var species = ajaxSelector.val();

          var text = panel.exampleData[species][this.rel];
          if(typeof(text) === 'undefined' || !text.length) text = "";
          text = text.replace(/\\n/g, "\n");
        
          panel.elLk.dataField.val(text).trigger('change');
        });
      }

    },

    preview: function(val, position) {
    /*
     * renders VEP results preview
     */
      if (!val) {
        return;
      }

      // reset preview div
      this.elLk.previewDiv.empty().removeClass('active').addClass('loading').css(position);

      // get input, format and species
      this.previewInp = {};
      this.previewInp.input   = val;
      this.previewInp.format  = this.detectFormat(val);
// EG    
      var ajaxSelector = $('select.ajax-species-selector'); 
      if (ajaxSelector[0]) {
        this.previewInp.species = $('select.ajax-species-selector').val();
      } else {
        this.previewInp.species = this.elLk.speciesDropdown.find('input:checked').val();
      }
//
      this.previewInp.baseURL = this.params['rest_server_url'] + '/vep/' + this.previewInp.species;
      var url;

      // this switch formats the input into URL for REST API
      switch (this.previewInp.format) {
        case "id":
          url = this.previewInp.baseURL + '/id/' + this.previewInp.input;
          break;

        case "hgvs":
          url = this.previewInp.baseURL + '/hgvs/' + encodeURIComponent(this.previewInp.input);
          break;

        case "ensembl":
          var arr = this.previewInp.input.split(/\s+/);
          url = this.previewInp.baseURL + '/region/' + arr[0] + ':' + arr[1] + '-' + arr[2] + ':' + (arr[4] && arr[4].match(/\-/) ? -1 : 1) + '/' + arr[3].replace(/[ACGTN-]+\//, '');
          break;

        case "vcf":
          var arr = this.previewInp.input.split(/\s+/);
          var c = arr[0];
          var r = arr[3];
          var a = arr[4].split(',')[0];

          // we can't do e.g. structural variants
          if(!a.match(/[ACGTN]+/i)) {
            this.previewError('allele must be [ACGT]');
            return;
          }

          var s = parseInt(arr[1]);
          var e = s + (r.length - 1);

          // adjust coordinates for mismatched substitutions
          if(r.length != a.length) {
            s = s + 1;
            a = a.length === 1 ? '-' : a.substring(1);
          }

          url = this.previewInp.baseURL + '/region/' + c + ':' + s + '-' + e + ':' + 1 + '/' + a;
          break;

        default:
          this.previewError('Failed for ' + this.previewInp.format + ' format');
          return;
      }

      this.elLk.previewDiv.html('<p><img src="/i/ajax-loader.gif"/></p>');

      // do the AJAX request
      $.ajax({
        url       : url,
        type      : "GET",
        dataType  : 'json',
        context   : this,
        success   : function(results) { this.renderPreviewTable(results) },
        error     : function(jqXHR, textStatus, errorThrown) { this.previewError(jqXHR.responseJSON ? jqXHR.responseJSON.error : 'Unknown error'); }
      });
    }

  });
}
