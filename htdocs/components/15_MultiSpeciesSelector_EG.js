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

    parseClassName = function(className) {
      var parts = className.split('~~');
      var data  = {};
      if (parts.length > 1) {
        data['displayGroup'] = parts[0];
        data['group']        = parts[0].replace(/\s/g, '_');
        data['className']    = parts[1];
      } else {
        data['className']    = parts[0];
      }
      return data;
    }

    // count grouped items
    listItems.each(function() {
      var item = parseClassName(this.className);
      if ('group' in item) {
        if (item.group in counts) {
          counts[item.group]++;
        } else {
          counts[item.group] = 1;
        }
      }
    });

    // bunch items into groups and store the original items for later 
    listItems.each(function() {
      var item = parseClassName(this.className);
      if ('group' in item) {
        var group = item.group;
        
        if (!(group in groups)) {
          groups[group] = $('<ul>');
          regions = counts[group] > 1 ? 'regions' : 'region';
          $(this).parent().append($('<li class="group_' + group + '"><span class="switch"></span><span>' + item.displayGroup + ' (' + counts[group] + ' ' + regions + ')</span></li>'));
        }      

        $(this).attr('class', item.className);
        groups[group].append(this);        
      }
    });

    this.mungedGroups = groups;
  },

  unMungeGroups: function () {
    var listItems = $(".multi_selector_list li[class^='group_']", this.el);
    var groups    = this.mungedGroups;

    // re-instate the items and drop the groups
    listItems.each(function() {
      var group = this.className.replace('group_', '');
      var list = $(this).parent();
      groups[group].children().each(function() {
        list.append(this);
      });
      $(this).remove();
    });
  }
});