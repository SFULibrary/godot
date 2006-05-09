//Rollovers

function MM_swapImgRestore() { //v3.0

  var i,x,a=document.MM_sr; for(i=0;a&&i<a.length&&(x=a[i])&&x.oSrc;i++) x.src=x.oSrc;

}

function MM_preloadImages() { //v3.0

  var d=document; if(d.images){ if(!d.MM_p) d.MM_p=new Array();

    var i,j=d.MM_p.length,a=MM_preloadImages.arguments; for(i=0; i<a.length; i++)

    if (a[i].indexOf("#")!=0){ d.MM_p[j]=new Image; d.MM_p[j++].src=a[i];}}

}

function MM_findObj(n, d) { //v4.01

  var p,i,x;  if(!d) d=document; if((p=n.indexOf("?"))>0&&parent.frames.length) {

    d=parent.frames[n.substring(p+1)].document; n=n.substring(0,p);}

  if(!(x=d[n])&&d.all) x=d.all[n]; for (i=0;!x&&i<d.forms.length;i++) x=d.forms[i][n];

  for(i=0;!x&&d.layers&&i<d.layers.length;i++) x=MM_findObj(n,d.layers[i].document);

  if(!x && d.getElementById) x=d.getElementById(n); return x;

}

function MM_swapImage() { //v3.0

  var i,j=0,x,a=MM_swapImage.arguments; document.MM_sr=new Array; for(i=0;i<(a.length-2);i+=3)

   if ((x=MM_findObj(a[i]))!=null){document.MM_sr[j++]=x; if(!x.oSrc) x.oSrc=x.src; x.src=a[i+2];}

}

function confirmDelete() {
	var agree = confirm("Delete record(s)?");
	if (agree) 
		return true;
	else 
		return false;
}

function CheckAll(chkName) {
	for (i=0; i < document.forms[0].elements.length; i++) {
		if (document.forms[0].elements[i].name == chkName) {
			document.forms[0].elements[i].checked = 1;
		}
	}
}


function showLevel(level, prefix, max_level, max_lines) {
	var done = 0;

	var linecount = 0;
	while (linecount < max_lines) {
		linecount = linecount + 1;
		
		var levelcount = 0;

		while (levelcount < max_level) {
			levelcount = levelcount + 1;
			var objname = prefix + '_' + levelcount + '_' + linecount;

			if (document.all) {   // IE
				if (document.all[objname]) {
					if (levelcount > level) {
						document.all[objname].style.display = 'none';
					} else {
						document.all[objname].style.display = '';
					}
				}
			} else if (document.getElementById) {  // Mozilla, Safari, etc.
				if (document.getElementById(objname)) {
					if (levelcount > level) {
						document.getElementById(objname).style.display = 'none';
					} else {
						document.getElementById(objname).style.display = '';
					}
				}
			}
		}
	}

	return false;
}


function createCookie(name,value,days) {
  // document.write("here we are in create cookie ", name, " ", value, " ", days, "<BR>");
  if (days) {
    var date = new Date();
    date.setTime(date.getTime()+(days*24*60*60*1000));
    var expires = "; expires="+date.toGMTString();
  }
  else expires = "";
  document.cookie = name+"="+value+expires+"; path=/";
}

function readCookie(name) {
  var nameEQ = name + "=";
  var ca = document.cookie.split(';');
  for(var i=0;i < ca.length;i++) {
    var c = ca[i];
    while (c.charAt(0)==' ') c = c.substring(1,c.length);
    if (c.indexOf(nameEQ) == 0) return c.substring(nameEQ.length,c.length);
  }
  return null;
}


/* 
    -------------------------------------------------------------------
    = For local_configuration screen
    -------------------------------------------------------------------
*/

function showGrouping(prefix, max_lines) {
                
	var linecount = 0;

	while (linecount < max_lines) {
		linecount = linecount + 1;
		
		var objname = prefix + '.' + linecount;
                var mycookie  = 'gc_lc_grouping_' + prefix;

		if (document.all) {   // IE
		        if (document.all[objname]) {
                                if (document.all[objname].style.display == 'none') {                         
				        document.all[objname].style.display = '';
                                        createCookie(mycookie, 1, 7); 
                                } else {
                                        document.all[objname].style.display = 'none';    
                                        createCookie(mycookie, 0, 7);
                                }         
			}
		} else if (document.getElementById) {  // Mozilla, Safari, etc.
			if (document.getElementById(objname)) {

                                if (document.getElementById(objname).style.display == 'none') {
				        document.getElementById(objname).style.display = '';
                                        createCookie(mycookie, 1, 7);                                         

                                } else {
                                        document.getElementById(objname).style.display = 'none';
                                        createCookie(mycookie, 0, 7); 
                                }                                
			}
		}
	}

	return false;
}

function groupingStyleDisplay(prefix) {
        
        var value = readCookie('gc_lc_grouping_' + prefix);

        if (value == 1) { return 'display: '; }
        else            { return 'display: none'; }
}


/* 
    -------------------------------------------------------------------
    = For local_configuration_options screen
    -------------------------------------------------------------------
*/

function toggleLayer(layer_id, hide_message, show_message) {
        layer = 'layer_' + layer_id;

        if (document.layers) {
                if (document.layers[layer].display == 'none') {
                        document.layers[layer].display = '';
                        toggleShowLayer(layer_id, 1, hide_message, show_message);
                } else {
                        document.layers[layer].display = 'none';
                        toggleShowLayer(layer_id, 0, hide_message, show_message);
                }
        }
        if (document.all) {
                if (document.all[layer].style.display == 'none') {
                        document.all[layer].style.display = '';
                        toggleShowLayer(layer_id, 1, hide_message, show_message);
                } else {
                        document.all[layer].style.display = 'none';
                        toggleShowLayer(layer_id, 0, hide_message, show_message);
                }
        }
        if (!document.all && document.getElementById) {
                if (document.getElementById(layer).style.display == 'none') {
                        document.getElementById(layer).style.display = '';
                        toggleShowLayer(layer_id, 1, hide_message, show_message);
                } else {
                        document.getElementById(layer).style.display = 'none';
                        toggleShowLayer(layer_id, 0, hide_message, show_message);
                }
        }
}

function toggleShowLayer(layer_id, toggle, hide_message, show_message) {
        layer = 'showhide' + layer_id;

        var mycookie  = 'gc_lc_option_' + layer_id;
        createCookie(mycookie, toggle, 7);

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


function toggleLinkText(layer_id, hide_message, show_message) {

        var mycookie  = 'gc_lc_option_' + layer_id;
        var value = readCookie(mycookie);

        if (value == 1) { return hide_message; }
        else            { return show_message; }
}


function layerStyleDisplay(layer_id) {
        
        var mycookie  = 'gc_lc_option_' + layer_id;
        var value = readCookie(mycookie);

        if (value == 1) { return 'display: '; }
        else            { return 'display: none'; }
}


/*
    -------------------------------------------------------------------
    = List processing code follows
    -------------------------------------------------------------------
*/


var undefined;
function isUndefined(property) {
  return (typeof property == 'undefined');
}

// Array.is_in() - Returns index if value is in array (TH)
if (isUndefined(Array.prototype.is_in) == true) {
 Array.prototype.is_in = function (test_value) {
  for (var i = 0; i < this.length; i++) {
   if (this[i] == test_value) { return i }
  }
  return null;
 };
}


/*

  create_array - sets up global variables for storing the array.

  Parameters:

       form        - the form which various input fields will be in
       group       - the prefix to all fields/variables for the array group
       array_count - number of fields in the array group
       required_fields - string with field numbers for field which are required to be
                         filled out when adding
       key_fields  - string with which field numbers have values removed when they're added
                     to the main array.  Pass in field numbers that are comma separated
                     starting with 0.  key_field values MUST BE UNIQUE and the field
                     value has to be the same as the display value... for now.
       delimiter   - character(s) to delimit values in hidden fields for CGI submission

*/


function create_array(form, group, array_count, required_fields, key_fields, delimiter) {
	var array_name = group + "_array";

	// Global variable with form name that input fields will be under

	window[group + "_form"] = form;


	// Global variable with count of arrays for the group

        // alert('group:  ' + group + ', array_count:  ' + array_count);

	window[group + "_array_count"] = array_count;  


	// Global variable holding the main array for the group

	window[array_name] = new Array();              
	var array = window[array_name];


	// Set up required fields array.

	if (required_fields != null) {
		var required_fields_array = required_fields.split(',');
		window[group + '_required_fields'] = required_fields_array;
	} else {
		window[group + '_required_fields'] = new Array();
	}

	// Set up key fields array.

	if (key_fields != null) {
		var key_fields_array = key_fields.split(',');
		window[group + '_key_fields'] = key_fields_array;
	} else {
		window[group + '_key_fields'] = new Array();
	}


	// Store field delimiter for values

	if (delimiter == null) {
		delimiter = '|';	
	}

	window[group + "_delimiter"] = delimiter;		

	return true;
}


function init_array() {
	var group = init_array.arguments[0];
	var array_name = group + "_array";
	var array = window[array_name];
	var array_count = window[group + "_array_count"];
	var key_fields = window[group + '_key_fields'];

	// Initialize main array

	var count = -1;
	var array_index = -1;
	var field_number;
	for (var x = 1; x < init_array.arguments.length; x++) {
		count++;

		// Create an internal array if we've processed enough arguments to go to
		// another line.

		if ((count % array_count) == 0) {
			array.push(new Array());
			array_index++;
			field_number = 0;
		} else {
			field_number++;
		}

		if (key_fields.is_in(field_number) != null) {
			var field_name = group + '_' + field_number;
			remove_option_by_value(group, field_name, init_array.arguments[x]);
		}

		array[array_index].push(init_array.arguments[x]);
	}

	display_array(group, 0);

	return true;
}

function add_option_value (group, field_name, option_value) {
	var form = window[group + "_form"];

	var field = document.forms[form][field_name];
	var tmpArray = new Array();

	for (var i = 0; i < field.length; i++) {
		if (field.options[i].value != option_value) {
			var tmpObj = new Object();
			tmpObj.text = field.options[i].text;
			tmpObj.value = field.options[i].value;
			tmpArray.push(tmpObj);
		}
	}
	
	var tmpObj = new Object();
	tmpObj.text = option_value;
	tmpObj.value = option_value;
	tmpArray.push(tmpObj);

	tmpArray.sort(function(a,b) { return a.value < b.value ? -1 : a.value > b.value ? 1 : 0;});

	field.length = tmpArray.length;

	for (var i = 0; i < tmpArray.length; i++) {
		field.options[i].text = tmpArray[i].text;
		field.options[i].value = tmpArray[i].value;

		if (tmpArray[i].value == option_value) {
			field.options[i].selected = true;
		}
	}

	return true;
}



function remove_option_by_value (group, field_name, option_value) {
	var form = window[group + "_form"];
       
	var field = document.forms[form][field_name];

        if (! field) { return true; }
        // alert("form:  " + form + field_name + field);

	var tmpArray = new Array();

	for (var i = 0; i < field.length; i++) {
		if (field.options[i].value != option_value) {
			var tmpObj = new Object();
			tmpObj.text = field.options[i].text;
			tmpObj.value = field.options[i].value;
			tmpArray.push(tmpObj);
		}
	}

	field.length = tmpArray.length;

	for (var i = 0; i < tmpArray.length; i++) {
		field.options[i].text = tmpArray[i].text;
		field.options[i].value = tmpArray[i].value;
	}

	return true;
}	

function add_before (group, array_count) {
	do_add(group, 0);
}

function add_after (group, array_count) {
	do_add(group, 1);
}

function do_add (group, offset) {

        // initialize error message
        write_into(group + '_error_message', '');

	var display    = group + "_display";
	var field      = display + "_field";
	var form       = document.forms[window[group + "_form"]];
	var array_name = group + "_array";

	// Grab global variable shortcuts

	var array_count     = window[group + "_array_count"];
	var array           = window[array_name];
	var key_fields      = window[group + '_key_fields'];
	var required_fields = window[group + '_required_fields'];

	// Get index of current selection

	var index = get_radio_index(form, field);

	// Get values from fields into arrays

	var new_array = new Array();

        // alert("1 -- here in do_add -- key_fields: " + key_fields + ' -- ' + array_count);

	for (var x = 0; x < array_count; x++) {

                // alert("3 -- here in do_add: " + x );

		var field_name = group + '_' + x;
		var value;

		if (form[field_name].type == 'select-one') {
			value = get_select_value(form, field_name);
		} else if (form[field_name].type == 'text') {                 
			value = get_text_value(form, field_name);
		} else if (form[field_name].type == 'checkbox') {                 
			value = get_checkbox_value(form, field_name);
		} else {
			alert('Unrecognized field type: ' + form[field_name].type);
		}

                // strip off leading and trailing whitespace
                if (value != null) {
                        value = value.replace(/^\s+/,'');
                        value = value.replace(/\s+$/,'');
                }

		if (value == null) {
			if (required_fields.is_in(x) != null) {
                                write_into(group + '_error_message', 'You did not select values for all the required fields.');
				return false;
			}

			value = '';
		}

                if (key_fields.is_in(x) != null) {                       

   	                // if it is a key field then no duplicates are allowed

                        for (var y = 0; y < array.length; y++) {
                                var inner_array = array[y];
                                if (value == inner_array[x]) { 
                                        write_into(group + '_error_message', 'No duplicates allowed.')
                                        return false;
                                }
                        }       

                        // can't have blank value in key fields

                        if (value.match(/^\s*$/)) {
                                write_into(group + '_error_message', 'Field must not be blank.')
                                return false;
                        }
 
                }

		new_array.push(value);

                // alert("4 -- here in do_add -- value:  " + value );
	}

        // alert("2 -- here in do_add");

	// Remove key field options from selects

	for (var x = 0; x < array_count; x++) {
		if (key_fields.is_in(x) != null) {
			var field_name = group + '_' + x;
			remove_option_by_value(group, field_name, new_array[x]);			
		}
	}

	array.splice(index + offset, 0, new_array);
	display_array(group, index + offset);

	return true;
}




function do_delete (group) {

        // initialize error message
        write_into(group + '_error_message', '');

	var display = group + "_display";
	var field = display + "_field";
	var form = document.forms[window[group + "_form"]];
	var array_name = group + "_array";
	var key_fields = window[group + '_key_fields'];
	var array = window[array_name];
	var array_count = window[group + "_array_count"];

	// Get index of item to delete

	if (array.length > 0) {
		var index = get_radio_index(form, field);

		// Delete item and return deleted data

		var removed_array = array.splice(index, 1);
		removed_array = removed_array[0];

		// Loop through key fields to add items back to key field selects

		for (var i = 0; i < key_fields.length; i++) {
			var field_number = key_fields[i];
			var field_name = group + '_' + field_number;

                        if (form[field_name].type == 'select-one') {
			        add_option_value(group, field_name, removed_array[field_number]);
                        }
		}

		// Check other fields - if they're text boxes, stick the text value in there.

		for (var i = 0; i < array_count; i++) {
			var field_name = group + '_' + i;
			if (form[field_name].type == 'text') {
				form[field_name].value = removed_array[i];
                        } else if (form[field_name].type == 'checkbox') {
                                form[field_name].checked = false;
                                if (removed_array[i] == 't') {
                                        form[field_name].checked = true;
                                }
			} else if (form[field_name].type == 'select-one') {
				for (var x = 0; x < form[field_name].length; x++) {
					if (form[field_name].options[x].value == removed_array[i]) {
						form[field_name].options[x].selected = true;
					}
				}
			}
		}

		display_array(group, index);

	}
	
	return true;
}


function write_into (id, text) {

	var div;
	
	if (document.getElementById) {
		div = document.getElementById(id);
	} else if (document.all) {
		div = document.all[id];
	} else {
		return false;
	}

        if (! div) { return false; }

	div.innerHTML = '';
	div.innerHTML = text;

	return true;
}

function get_text_value (form, field) {
	return form[field].value;
}

function get_checkbox_value (form, field) {

        if (form[field].checked) {
            return form[field].value;
        }
        
	return '';
}



function get_select_value (form, field) {
	if (form[field].selectedIndex >= 0) {
		return form[field].options[form[field].selectedIndex].value;
	} else {
		return null;
	}
}

function get_select_index (form, field) {
	return form[field].selectedIndex;
}

function get_radio_index (form, field) {
	var index = -1;

	if (!form[field]) {
		return index;
	}

	if (form[field].length) {
		for (var x = 0; x < form[field].length; x++) {
			if (form[field][x].checked) {
				index = x;
			}
		}
	} else {
		if (form[field].checked) {
			index = 0;
		}
	}

	return index;
}

function display_array (group, selected_index) {

	var array_name = group + "_array";
	var display = group + "_display";
	var field = display + "_field";

	// Grab global variable shortcut

	array = window[array_name];

	var output = '';  // Buffer all the output for a single big write

	// Make sure the index isn't out of bounds

	if (selected_index == null) {
		selected_index = 0;
	} else if (selected_index >= array.length) {
		selected_index = array.length - 1;
	}

	output += '<table id="' + group + '-display" class="form-list-tool-display">';
	
	for (var x = 0; x < array.length; x++) {
		var inner_array = array[x];

		// Start a new row and put in a radio button for the line

		output += '<tr><td>';
		output += '<input type="radio" name="' + field + '" value="' + x + '"';
		if (selected_index == x) {
			output += ' checked="1"';
		}
		output += ' />';
		
		// Add a hidden field for submitting the data

		output += '<input type="hidden" name="' + group + '_value_' + x + '" value="';

		// Grab inner array contents for values
		
		for (var y = 0; y < inner_array.length; y++) {
			output += inner_array[y];
			if (y < (inner_array.length - 1)) {
				output += window[group + '_delimiter'];
			}
		}

		output += '" />';


		output += '</td>';

		// Grab inner array contents for display

		for (y = 0; y < inner_array.length; y++) {
			output += '<td>';
			output += inner_array[y];
			output += '</td>';
		}

		output += '</tr>';
	}

	output += '</table>';

	write_into(display, output);
}

