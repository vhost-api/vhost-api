(function ($) {
	$.fn.serializeFormJSON = function (someAttrList) {
		var o = {};
		var attrList = someAttrList;
		var a = this.serializeArray();
		$.each(a, function () {
			if (o[this.name]) {
				if (!o[this.name].push) {
					o[this.name] = [o[this.name]];
				}
				o[this.name].push(this.value || '');
			} else {
				if (this.name in attrList) {
					switch(attrList[this.name]) {
						case 'int':
							o[this.name] = parseInt(this.value) || 0;
							break;
						default:
							break;
					}
				} else {
					o[this.name] = this.value || '';
				}
			}
		});
		return o;
	};
})(jQuery);

function submitMyForm() {
	var myForm = $("#edit_mailaccount");
	var formURL = myForm.attr("action");
	var formMethod = myForm.attr("method");
	var attrList = {};
	myForm.find('input').each(function() {
		e = $(this);
		if (e.data('type')) {
			attrList[e.attr('name')] = e.data('type');
		}
	});
	// console.log(attrList);

	var _formData = myForm.serializeFormJSON(attrList);
	// console.log(_formData);

	// remove '_method' key, we do not want to send that
	delete _formData["_method"];

	// find unchecked checkboxes and their values to the _formData
	myForm.find("input:checkbox").each(function() {
		var value = "false";
		if ($(this).is(':checked')) {
			value = "true";
		}
		// console.log('adding value "' + value + '" for "' + $(this).attr('name') + '"');
		_formData[$(this).attr('name')] = value;
	});

	// console.log(_formData);

	var formData = JSON.stringify(_formData);

	// console.log("Processing ajax...");
	$.ajax({
		type: formMethod,
		url: formURL,
		data: formData,
		success: function(data, textStatus, jqXHR) {
			console.log("Status: " + textStatus);
			console.log(data);
		},
		error: function(jqXHR, textStatus, errorThrown) {
			console.log("Status: " + textStatus);
			console.log("Error: " + errorThrown + " " + jqXHR.responseText);
		},
		dataType: "json",
		contentType: "application/json"
	});
}

function formatSizeUnits(bytes){
	if      (bytes>=1073741824) {bytes=(bytes/1073741824).toFixed(2)+' GB';}
	else if (bytes>=1048576)    {bytes=(bytes/1048576).toFixed(2)+' MB';}
	else if (bytes>=1024)       {bytes=(bytes/1024).toFixed(2)+' KB';}
	else if (bytes>1)           {bytes=bytes+' bytes';}
	else if (bytes==1)          {bytes=bytes+' byte';}
	else                        {bytes='0 byte';}
	return bytes;
}

$(document).ready(function() {
	// $("[data-format='filesize']").each(function() {
	// var intval = parseInt($(this).html());
	// $(this).html(formatSizeUnits(intval));
	// });
});

