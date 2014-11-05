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



Ensembl.Panel.LocationNav = Ensembl.Panel.LocationNav.extend({
  
// EG double-arrow buttons move two windows instaed of 1e6  
  updateButtons: function() { // update button hrefs (and loc) at cur. pos
    var panel = this;
    var rs = this.currentLocations();
    var width = rs['r'][2]-rs['r'][1]+1;
    $('.left_2',panel.el).attr('href',panel.arrow(-width * 2));
    $('.left_1',panel.el).attr('href',panel.arrow(-width));
    $('.zoom_in',panel.el).attr('href',panel.zoom(0.5));
    $('.zoom_out',panel.el).attr('href',panel.zoom(2));
    $('.right_1',panel.el).attr('href',panel.arrow(width));
    $('.right_2',panel.el).attr('href',panel.arrow(width * 2));
    $('#loc_r',panel.el).val(rs['r'][0]+':'+rs['r'][1]+'-'+rs['r'][2]);
  },
//   

  rescale: function(rs,input) {
    var config = this.config();
    input = Math.round(input);
    var out = {};
    $.each(rs,function(k,v) {
      var r_2centre = Math.round(v[1]+v[2]);
      var r_start = Math.round((r_2centre-input)/2);
      if(r_start<1) { r_start = 1; }
      var r_end = r_start+input+1;
      if(k=='r') {
// EG - add start boundary (don't assume start == 1)
        if(r_start > config.end)   { r_start = config.end - config.min; }
        if(r_end   > config.end)   { r_end   = config.end; }
        if(r_start < config.start) { r_start = config.start; }
        if(r_end   < config.start) { r_end   = config.start + config.min; }
//        
      }
      if(r_start<1) { r_start = 1; }
      out[k] = [v[0],r_start,r_end,v[3]];
    });
    return out;
  },

  arrow: function(step) { // href for arrow buttons at cur pos. as string
    var config = this.config();
    var rs = this.currentLocations();
    var out =  {};
    $.each(rs,function(k,v) {
      v[1] += step;
      v[2] += step;
      if(k=='r') {
// EG - add start boundary (don't assume start == 1)        
        if(v[1] > config.end)   { v[1] = config.end - config.min; }
        if(v[2] > config.end)   { v[2] = config.end; }
        if(v[1] < config.start) { v[1] = config.start; }
        if(v[2] < config.start) { v[2] = config.start + config.min; }
//        
      }
    });
    return this.newLocation(rs);
  }

});
