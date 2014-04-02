var ENA_Timer = 0; 

Ensembl.Panel.ENASearch = Ensembl.Panel.extend({
	constructor: function (id) {
	    this.base(id);	    

	    var bform = $("#blastForm");
	    var panel = this;

	    bform.submit(function(e) {
		    e.preventDefault();
		    panel.showMessage("Contacting ENA ...", 0);
		    panel.clearResults();
		    var args = new Array();

		    var seq = $("#ena-seq").val().replace(">Example Sequence\n", "");
		    args.push("_query_sequence="+ seq);		    
		    args.push("evalue="+escape($("#evalue").val()));
		    args.push("splicing="+($("#splicing").is(":checked") ? 1 : 0));
		    args.push("sdomain="+escape($("#sdomain").val()));
		    var formData = args.join('&');

		    $.ajax({
			    url: '/Multi/enasubmit', 
			    type: 'post', 	
			    data : formData,
			    success: function(response) {	  
				if (response.success) {
				    ENA_TIMER = setInterval(function() {
					    panel.checkStatus(response.job, panel);}, 900
					);
				} else {
				    panel.showMessage(response.msg, -1);
				}
			    }, 
			    error: function(response) {
				panel.showMessage("Error submitting the job. ", -1);
			    }
			});
		});
	},
	showMessage: function(msg, progress) {
	    var pm = $("#progress-msg");
	    pm.html(msg);
	    var pb = $("#progress-bar");
	    pb.css('width', progress + '%');
	    if (progress > 99) {
		pb.addClass("completed");
	    } else {
		pb.removeClass("completed");
	    }
	},
	checkStatus: function(jobId, panel) {
	    $.ajaxSetup({ cache: false });
	    $.ajax({
		    url: '/Multi/enastatus', 
			type: 'get', 	
			data : 'job='+jobId,
			success: function(response) 
			{	  
			    if (response.success) {
				if (panel.updateStatus(response, panel)) {
				    panel.loadResults(jobId, panel);
				}
			    }
			}, 
			error: function(response) 
			{
			    panel.showMessage("Error checking status. ", -1);
			}
		});
	},
	updateStatus: function(data, panel) {
	    var message = 'Contacting ENA ...';
	    if (data.status == 'COMPLETE') {
		message = "Completed.  Found " + data.count + " hits.";
		data.progress = 100;
		clearInterval(ENA_TIMER);
		panel.showMessage(message, data.progress);
		return 1;
	    } 
	    if (data.progress > -1) {
		message = 'Running search [ ' + data.progress + '% ]';
	    }
	    panel.showMessage(message, data.progress);
	    return 0;
	},
	clearResults: function() {
	    el = $('#ena-results');
	    el.html('');
	},
	loadResults: function(jobId, panel, order, page) {
	    el = $('#ena-results');
	    el.html(' Mapping results ... ');
	    var args = new Array();
	    args.push("job=" + jobId);
	    if (order) {
		args.push("order="+order);
	    }
	    if(page) {
		args.push("page="+page);
	    }
	    $.ajax({
		    url: '/Multi/enaresult', 
		    type: 'get', 	
		    data : args.join('&'),
			success: function(jsontext) 
			{	  
			    el.html(jsontext);
			    // To prevent multiple attachment of the event handler first set off

			    $(document).off('click', '.ena-alignment').on('click', ".ena-alignment", panel.showAlignment);

			    $(document).off('click', ".ena-sort").on('click', ".ena-sort", function(e) { 
				    e.preventDefault(); 
				    var col = this.id.replace("sort-", "");
				    panel.loadResults(jobId, panel, col);
				});

			    $(document).off('click',".ena-pager").on('click', ".ena-pager", function(e) {
				    e.preventDefault(); 
				    var page = this.id.replace("page-", "");
				    panel.loadResults(jobId, panel, order, page);
				});
			}, 
			error: function(response) 
			{
			    panel.showMessage("Error retrieving results. ", -1);
			    console.log(response);
			}
		});

	},
	showAlignment: function(e) {
	    e.preventDefault();
	    var id = '#' + this.id.replace("link", "hit");
	    var html = $(id).html();
	    var w = window.open();
	    w.document.writeln(html);
	}
    });
