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

// EG constrain to a given window and handle circular regions
  
  zoom: function(factor) { // href for +/- buttons at cur pos. as string
    var config = this.config();
    var rs     = this.currentLocations();
    var start  = rs['r'][1];
    var end    = rs['r'][2];
    var width  = start > end ? end + config.end - start + 1 : end - start + 1;
    rs = this.rescale(rs,width*factor);
    if(factor>1) {
      $.each(rs,function(k,v) {
        if(v[1] == v[2]) { v[2]++; }
      });
    }
    return this.newLocation(rs);
  },

  rescale: function(rs,input) {
    var panel = this;
    var config = this.config();
    input = Math.round(input);
    var out = {};
    $.each(rs,function(k,v) {
      var start  = v[1];
      var end    = v[2];
      var width  = start > end ? end + config.end - start + 1 : end - start + 1;
      var centre = start + Math.round(width / 2);
      if (start > end  && centre > config.end) centre = centre - config.end + 1; // wrap for circular regions
      var new_start = centre - Math.round(input / 2);
      var new_end   = centre + Math.round(input / 2);
      out[k] = panel.constrainRegion([v[0], new_start, new_end, v[3]]);
    });
    return out;
  },

  arrow: function(step) { // href for arrow buttons at cur pos. as string
    var panel = this;
    var config = this.config();
    var rs = this.currentLocations();
    $.each(rs,function(k,v) {
      rs[k] = panel.constrainRegion([v[0], v[1] + step, v[2] + step, v[3]]);
    });
    return this.newLocation(rs);
  },

  constrainRegion: function(r) {
    var c = this.constrain(r[1], r[2]);
    return [r[0], c.start, c.end, r[3]];
  },

  constrain: function(s, e) {
    var config = this.config();
    if (config.isCircular && config.start == 1) {
      // it's a circular region and we could potentially overlap the origin
      var max = config.end;
      var window_size = (s <= e ? e - s : e + max - s) + 1; 
      if (window_size >= max) {
        // window covers whole region
        s = 1;
        e = max;
      } else {
        // wrap start pos
        if (s < 0)   s += max;
        if (s > max) s -= max;
        if (s == 0)  s = 1;
        // wrap end pos
        if (e < 0)   e += max;
        if (e > max) e -= max;
        if (e == 0)  e = 1;
      }
    } else {
      if (s > config.end)   s = config.end - config.min;
      if (e > config.end)   e = config.end;
      if (s < config.start) s = config.start;
      if (e < config.start) e = config.start + config.min;
    }
    return {start: s, end: e};
  },

  val2pos: function () { // from 0-100 on UI slider to bp
    var panel     = this;
    
    var rs        = panel.currentLocations();
    var start     = rs['r'][1];
    var end       = rs['r'][2];
    var input     = start > end ? end + config.end - start + 1 : end - start + 1;
    var config    = panel.config();
    var slide_mul = ( Math.log(config.max) - Math.log(config.min) ) / 100;
    var slide_off = Math.log(config.min);
    var out       = (Math.log(input)-slide_off)/slide_mul;
    
    if(out < 0) { return 0; }
    if(out > 100) { return 100; }
    
    return out;
  }

//  

});
