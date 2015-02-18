Ensembl.Panel.Ontology = Ensembl.Panel.extend({
  constructor: function (id) {
    this.base.apply(this, arguments);
    
    this.tabImageMatch = new RegExp(/[?;&]tab=i/);
    
    this.oX = 0;
    this.oY = 0;
  },

  init: function() {
    this.base.apply(this, arguments);

    var panel = this;

    $("area[id^=node]", panel.el).each(function(){
      $(this).click(function(){ 
        panel.nodeMenu( $(this).attr('title') ) 
        return false;
      });
    });
    
    $("#hideMenuDialog", panel.el).click(function(){ panel.hideMenu('dialog') }).css('cursor', 'pointer');
    
    $(document).mousemove(function(e){
      panel.oX = e.pageX;
      panel.oY = e.pageY;
    }); 
        
    $('#tabImage', panel.el).click(function(){ panel.selectActiveTab('tabImage') });
    $('#tabTable', panel.el).click(function(){ panel.selectActiveTab('tabTable') });
    
    panel.selectActiveTab();
  },

  nodeMenu: function(term) {
    this.clearMenu("nodenote");
    this.clearMenu("nodetitle");
    
    var ph = 0;

    var link = window.location.href;
    var link2 = link.replace(/go=([^;&]+)([;&]?)/g, '');
    link2 = link2 + ';go='+ term;
    var alink = '<a style="padding-left:10px;" href="'+link2+'" alt="Term ancestors"><img title="View the ancestors of this term only" align="absmiddle" src="/i/find.png" /></a>';
    this.printMenu("nodetitle", term + alink);	
    var data = ontology_data[term];
    ph += 50;
    
    var eLinks = ontology_settings.extlinks;
    
    for (var i=0; i < eLinks.length; i++) {
	    var link = eLinks[i];
      if (link) { 
  	    var label = link.name;
  	    var url = link.link.replace(/###ID###/g, term);
  	    //			alert(label + " * " + url);
  	    var mItem  = '<b>'+label+': </b> <a href="'+url+'">'+term+'</a>';
  	    this.printMenu("nodenote", mItem);
  	    ph+=20;
      }
    }
    
    if (data.note) {
      var notes = data.note.split("#");
    	if (notes.length < 4) {
	      for(var i = 0; i < notes.length; i++){
		      var p = notes[i].split("=");
		      this.printMenu("nodenote", "<b>"+p[0]+":</b> " + unescape(p[1]));
		      ph+=20;
	      }			
	    } else {
	      var nlist = '';
	      for(var i = 0; i < notes.length; i++){
		      var p = notes[i].split("=");
		      nlist = nlist + "<p><b>"+p[0]+":</b> " + unescape(p[1]) + "</p>";
	       }
              this.printMenu("nodenote", "<div class=\"scroll\">" + nlist + "</div>");
              ph+=80
            }
	  }

    if (data.ext) {
	    this.printMenu("nodenote","<b>Extensions:</b>");
	    var notes = data.ext.split("#");
	    if (notes.length < 4) {
	      for(var i = 0; i < notes.length; i++){
		      this.printMenu("nodenote", " * " + unescape(notes[i]));
		      ph+=20;
	      }			
	    } else {
	      var nlist = '';
	      for(var i = 0; i < notes.length; i++){
		      nlist = nlist + "<p> * " + unescape(notes[i]) + "</p>";
	      }			
	      this.printMenu("nodenote", "<div class=\"scroll\">" + nlist + "</div>");			
	      ph+=80;
	    }
    }
    
    if (data.def.length > 100) {
	    this.printMenu("nodenote", "<div class=\"scroll\"><b>Description:</b> " + data.def + "</div>");
	    ph+=80;
    } else {
	    this.printMenu("nodenote", "<b>Description:</b> " + data.def);		
	    ph+=25;
    }
    
    if (data.ss) {
	    if (data.ss.length > 50) {
	      this.printMenu("nodenote", "<div class=\"scroll\" style=\"height:30px\"><b>Datasets:</b> " + data.ss + "</div>");
	      ph+=40;
	    } else {
	      this.printMenu("nodenote", "<b>Dataset:</b> " + data.ss);
	      ph+=20;
		  }
    }
    
    var pm = document.getElementById('dialog');
	  pm.style.top = this.menuY();
    pm.style.left = this.menuX();
    pm.style.visibility = 'visible';
    
    var $id =$("#dialog", this.el);
    $id.css('top', this.menuY());
    $id.css('left', this.menuX());
    $id.height(ph);
    $id.fadeIn('fast');
    $id.css('visibility', 'visible');
  },
  
  menuX: function() {
  	var mX = this.oX - 200;
  	return mX + 'px';
  },
  
  menuY: function() {
  	var mY = this.oY - 60;
  	return mY + 'px';
  },
  
  clearMenu: function(menu) {
  	document.getElementById(menu).innerHTML = "";
  },
  
  printMenu: function(menu, msg) {
  	document.getElementById(menu).innerHTML += '<p style="padding-bottom:5px">' + msg + "</p>"
  },  
  
  hideMenu: function(menu) {
  	document.getElementById(menu).style.visibility = 'hidden';
  },
  
  selectActiveTab: function(xid) {
    if (!xid) {
      xid = window.location.href.match(this.tabImageMatch) ? 'tabImage' : 'tabTable'
    }
    
    var tabs = document.getElementById("ontologyTabs").childNodes; //gets all the tabs ( divs ) 
    
    for(i=0;i<tabs.length;i++){
      if (tabs[i].tagName == "div") {
  	    tabs[i].removeClass('selectedTab');
  	  }
  	  tabs[i].className="oTab"; //removes the classname from all the LI
    }
  
    $('#' + xid).addClass( 'selectedTab' );
  
    if (xid.match(/Image/)) {
  	  Ensembl.updateURL({"tab": "i"});
  	  $('#tabTableContent', this.el).css('display', 'none');
  	  $('#tabImageContent', this.el).css('display', 'block');
    } else {
  	  Ensembl.updateURL({"tab": "t"});
  	  $('#tabTableContent', this.el).css('display', 'block');
  	  $('#tabImageContent', this.el).css('display', 'none');
    }    
  }
});
