var open_divs = new Array();

function toggleServicesLayer(layer_id, hide_message, show_message) {
        layer = 'others' + layer_id;

        if (document.layers) {
                if (document.layers[layer].display == 'none') {
                        document.layers[layer].display = '';
                        toggleShowServicesLayer(layer_id, 1, hide_message, show_message);
                } else {
                        document.layers[layer].display = 'none';
                        toggleShowServicesLayer(layer_id, 0, hide_message, show_message);
                }
        }
        if (document.all) {
                if (document.all[layer].style.display == 'none') {
                        document.all[layer].style.display = '';
                        toggleShowServicesLayer(layer_id, 1, hide_message, show_message);
                } else {
                        document.all[layer].style.display = 'none';
                        toggleShowServicesLayer(layer_id, 0, hide_message, show_message);
                }
        }
        if (!document.all && document.getElementById) {
                if (document.getElementById(layer).style.display == 'none') {
                        document.getElementById(layer).style.display = '';
                        toggleShowServicesLayer(layer_id, 1, hide_message, show_message);
                } else {
                        document.getElementById(layer).style.display = 'none';
                        toggleShowServicesLayer(layer_id, 0, hide_message, show_message);
                }
        }
}

function toggleShowServicesLayer(layer_id, toggle, hide_message, show_message) {
        layer = 'showhide' + layer_id;
        if (toggle == 1) {
                message = hide_message;
        } else {
                message = show_message;
        }
        writeLayer(layer, message);
}

function writeLayer(layer, s) {
        if (document.layers) {
                document.layers[layer].open();
                document.layers[layer].write(s);
                document.layers[layer].close();

        }
        if (document.all) {
                document.all[layer].innerHTML = s;
        }
        if (!document.all && document.getElementById) {
                document.getElementById(layer).innerHTML = s;
        }
}

function toggleAll(layer_prefix, message_layer, hide_message, show_message, default_state) {
	var done = 0;
	var open;
	if (! (open_divs[message_layer] == 1 || open_divs[message_layer] == 0)) {
		open_divs[message_layer] = default_state;
	}

	if (open_divs[message_layer] == 1) {
		open_divs[message_layer] = 0;
		writeLayer(message_layer, show_message);
		open = 0;
	} else {
		open_divs[message_layer] = 1;
		writeLayer(message_layer, hide_message);
		open = 1;
	}

	var x = 1;
	while (!done) {
		var layer = 'others' + layer_prefix + '.' + x++;
	        if (document.layers) {
			if (document.layers[layer]) { 
				if (open) {
		       	                document.layers[layer].display = '';
		                } else {
		       	                document.layers[layer].display = 'none';
				}
	       	        } else {
				done = 1;
			}
	        }
		if (document.all) {
			if (document.all[layer]) {
				if (open) {
		       	                document.all[layer].style.display = '';
		                } else {
		       	                document.all[layer].style.display = 'none';
		                }
			} else {
				done = 1;
			}
	        } 
		if (!document.all && document.getElementById) {
			if (document.getElementById(layer)) {
		                if (open) {
		       	                document.getElementById(layer).style.display = '';
	        	        } else {
	       	        	        document.getElementById(layer).style.display = 'none';
		                }
		        } else {
				done = 1;
			}
	        }
	}
}
