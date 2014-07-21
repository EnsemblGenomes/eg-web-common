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

Ensembl.Panel.MultiSpeciesSelector = Ensembl.Panel.MultiSelector.extend({

  // EG-2183 - HACK: do some munging to make it look like the user is selecting sub-genome groups

  init: function () {
    this.mungeGroups();
    return this.base();
  },

  updateSelection: function () {
    this.unMungeGroups();
    this.setSelection();
    return this.base();
  },

  mungeGroups: function () {
    var listItems = $('.multi_selector_list li', this.el);
    var groups    = {};
    var counts    = {};

    // count grouped items
    listItems.each(function() {
      var parts = this.className.split('~~');
      if (parts.length > 1) {
        var group = parts[0];
        if (group in counts) {
          counts[group]++;
        } else {
          counts[group] = 1;
        }
      }
    });

    // replace list items with groups and store the original items for later 
    listItems.each(function() {
      var parts = this.className.split('~~');
      if (parts.length > 1) {
        var group     = parts[0];
        var className = parts[1]; // original name wirth group stripped

        if (!(group in groups)) {
          groups[group] = $('<ul>');
          regions = counts[group] > 1 ? 'regions' : 'region';
          $(this).parent().append($('<li class="group_' + group + '"><span class="switch"></span><span>' + group + ' (' + counts[group] + ' ' + regions + ')</span></li>'));
        }      

        $(this).attr('class', className);
        groups[group].append(this);        
      }
    });

    this.mungedGroups = groups;
  },

  unMungeGroups: function () {
    var listItems = $(".multi_selector_list li[class^='group']", this.el);
    var groups    = this.mungedGroups;

    // replace list items with groups and store the original items for later 
    listItems.each(function() {
      var group = this.className.replace('group_', '');
      var list = $(this).parent();
      groups[group].children().each(function() {
        console.log(this.className);
        list.append(this);
      });
      $(this).remove();
    });
  }
});