window.onload = function () {
	var param_array = new String();
	//console.log(parent.document.location.search.substr(location.search.indexOf("?")+1));
	var url_params_string = parent.document.location.search.substr(location.search.indexOf("?") + 1);
	//console.log(url_params_string);
	var params = url_params_string.split("&");

	// split param and value into individual pieces
	for (var i = 0; i < params.length; i++) {
		temp = params[i].split("=");
		//if ( [temp[0]] == sname ) { sval = temp[1]; }
		param_array[temp[0]] = temp[1];
	}
	console.log('page_id  '+param_array['page_id']);
	console.log('app_id  '+param_array['app_id']);
	console.log('id_number  '+param_array['id_number']);
	console.log('tabname='+top.TabHandler.GetSelectedTabName()); //('linky_tab');
	top.TabHandler.SelectTab('linky_tab');
	console.log('checking for values from the URL');
	if (param_array['page_id'] != undefined && param_array['app_id'] != undefined && param_array['id_number'] != undefined) {
		if (top.TabHandler.GetSelectedTabName() == 'linky_tab') {
			console.log("tab is linkytab");
			try {
				setTimeout(function () {
					top.TabHandler.RedirectTab('Action.aspx?PageId=' + param_array['page_id'] + '&AppId=' +
					param_array['app_id'] + '&idnumber=' + param_array['id_number']);
				}, 1000);
				
			} catch (ex) {
				console.log("something went wrong");
				console.log(ex);
			}
		} else {
			console.log("tab is NOT linkytab");
			top.TabHandler.AddTab('Action.aspx?PageId=' + param_array['page_id'] + '&AppId=' + param_array[
				'app_id'] + '&idnumber=' + param_array['id_number'], 1000, 'linky_tab');
		}
	}
} 
