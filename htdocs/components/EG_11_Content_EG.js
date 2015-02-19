/*
 * Copyright [1999-2014] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
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

Ensembl.Panel.Content = Ensembl.Panel.Content.extend({

  init: function() {
    this.base.apply(this, arguments);

    this.enaButtonEnabled = false;
    Ensembl.EventManager.register('runEnaSeq', this, this.runEnaSeq);
  },

  enableBlastButton: function(seq) {
    // enable original BLAST button
    this.base.apply(this, arguments);
    
    // also enable ENA button
    var panel = this;

    if (seq && !this.enaButtonEnabled) {

      this.elLk.enaButton = this.el.find('._enasearch_button').removeClass('hidden').on('click', function(e) {
        e.preventDefault();
        panel.runEnaSeq();
      });

      if (this.elLk.enaButton.length) {

        this.elLk.enaForm = $('<form>').appendTo(document.body).hide()
          .attr({action: this.elLk.enaButton.attr('href'), method: 'post'})
          .append($('<input type="hidden" name="_query_sequence" value="' + seq + '" />'))
          .append($('<input type="hidden" name="evalue" value="1" />'));

        this.enaButtonEnabled = true;
      }
    }

    return this.enaButtonEnabled;
  },

  runEnaSeq: function(seq) {
    if (this.elLk.enaForm) {
      if (seq) {
        this.elLk.enaForm.find('input[name=_query_sequence]').val(seq);
      }
      this.elLk.enaForm.submit();
    }
  }
});
