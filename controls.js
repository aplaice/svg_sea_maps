let map_data;
let svg_element = document.documentElement;
let current_sea = svg_element.dataset.currentSea;
let lon_0 = "0";
if (svg_element.dataset.lon_0 !== undefined) {
  lon_0 = svg_element.dataset.lon_0;
}

let not_zoomed = false;
if (svg_element.dataset.notZoomed !== undefined) {
  not_zoomed = true;
} // else {
//   const not_zoomed = false;
// }

const svg_width = 500;

// window.alert("hi");

// https://stackoverflow.com/questions/12460378/how-to-get-json-from-url-in-javascript
// https://stackoverflow.com/questions/24468459/sending-a-json-to-server-and-retrieving-a-json-in-return-without-jquery

async function send_json() {
  // send json
  let xhr = new XMLHttpRequest();
  let url = "http://localhost:8123/b4801f52-7f87-454a-9fd7-c6367b976fff/set_json";
  xhr.open("POST", url, true);
  xhr.send(JSON.stringify(map_data));
}



// get json
function get_json() {
  let data;
  let xhr = new XMLHttpRequest();
  let url = "http://localhost:8123/b4801f52-7f87-454a-9fd7-c6367b976fff/get_json";
  xhr.open("GET", url, true);
  xhr.onload = function () {
    if (xhr.readyState === 4 && xhr.status === 200) {
      map_data = JSON.parse(xhr.responseText);
      ensure_data_for_current_sea_is_defined(not_zoomed);
      refresh_svg(map_data);
    };
  };
  xhr.send();
}

get_json();

function ensure_data_for_current_sea_is_defined(not_zoomed) {
  let objects;
  if (not_zoomed) {
    objects = [["highlighted_ids", []], ["zoomed", false]];
  } else {
    objects = [["x_offset", 500], ["y_offset", 500], ["width", 1000], ["highlighted_ids", []]];
  }
  if (current_sea in map_data) {
    for (let i=0; i < objects.length; i++) {
      let o_k = objects[i][0];
      let o_v = objects[i][1];
      if (! (o_k in map_data[current_sea])) {
	map_data[current_sea][o_k] = o_v;
      }
    }
  } else {
    map_data[current_sea] = {};
    for (let i=0; i < objects.length; i++) {
      let o_k = objects[i][0];
      let o_v = objects[i][1];
      map_data[current_sea][o_k] = o_v;
    }
    // override whatever was in the old map_data!
    map_data[current_sea]["lon_0"] = lon_0;
  }
}
    
function refresh_svg(map_data) {
  // assume that ensure_data_for_current_sea_is_defined has been run
  let d = map_data[current_sea];
  let x_offset = d.x_offset;
  let y_offset = d.y_offset;
  let width = d.width;
  let highlighted_ids = d.highlighted_ids;
  let scale = svg_width/width;

  let main_map = document.getElementById("Main_map");
  if (main_map !== null) {
    main_map.setAttribute("transform", `scale(${scale}) translate(${-x_offset} ${-y_offset})`);
  }

  let currently_highlighted_elements = document.getElementsByClassName("selected");
  while (currently_highlighted_elements.length > 0) {
    currently_highlighted_elements[0].setAttribute("fill", "#B3DFF5");
    currently_highlighted_elements[0].setAttribute("stroke", "#B3DFF5");
    currently_highlighted_elements[0].setAttribute("class", "");
  }
  
  for (let i=0; i < highlighted_ids.length; i++) {
    if (document.getElementById(highlighted_ids[i]) === null) {
      console.log(highlighted_ids[i]);
    } else {
      document.getElementById(highlighted_ids[i]).setAttribute("fill", "#4790c8");
      document.getElementById(highlighted_ids[i]).setAttribute("stroke", "#4790c8");
      document.getElementById(highlighted_ids[i]).setAttribute("class", "selected");
    }
  }

  let mini_map_marker_g = document.getElementById("Marker");
  if (mini_map_marker_g !== null) {
    let mini_map_markers = mini_map_marker_g.children;
    let height = 9/16 * width;
    for (let i=0; i < mini_map_markers.length; i++) {
      m = mini_map_markers[i];
      // width of mini_map globe is 1/32 that of the main globe
      m.setAttribute("x", x_offset/32);
      m.setAttribute("y", y_offset/32);
      m.setAttribute("width", width/32);
      m.setAttribute("height", height/32);
    }
  }

  document.title = current_sea;
}


function onkeydown(event) {
  if (event.ctrlKey) {
    return 0;
  }
  let delta, multiplier;
  if (event.shiftKey) {
    delta = 1;
    multiplier = 1.01;
  } else {
    delta = 10;
    multiplier = 1.05;
  }
  switch (event.code) {
    case "KeyJ":
      map_data[current_sea].y_offset += delta;
      break;
    case "KeyK":
      map_data[current_sea].y_offset -= delta;
      break;
    case "KeyL":
      map_data[current_sea].x_offset += delta;
      break;
    case "KeyH":
      map_data[current_sea].x_offset -= delta;
      break;
    case "Equal":
      map_data[current_sea].width *= 1/multiplier;
      break;
    case "Minus":
      map_data[current_sea].width *= multiplier;
      break;
    case "KeyS":
      send_json();
      break;
    case "KeyA":
      // "add"
      select_id_to_add();
      break;
    case "KeyR":
      // "remove"
      select_id_to_remove();
      break;
    case "KeyG":
      // like "C-g"
      stop_mouse_listeners();
      break;
    case "KeyO":
      // ~ "open"
      change_current_sea_dialog();
      event.preventDefault();
      break;
    case "KeyC":
      // "comment"
      comment_dialog();
      event.preventDefault();
      break;
    // default:
    //   console.log("no!");
    //   break;
  }
  refresh_svg(map_data);
}

document.addEventListener("keydown", onkeydown);


function select_id_to_add() {
  document.getElementById("Seas").addEventListener("click", highlight_id);
}

function select_id_to_remove() {
  document.getElementById("Seas").addEventListener("click", unhighlight_id);
}

function highlight_id(e) {
  document.getElementById("Seas").removeEventListener("click", highlight_id);
  let elem = e.target;
  id = elem.getAttribute("id");
  if (id) {
    if (!map_data[current_sea].highlighted_ids.includes(id)) {
      map_data[current_sea].highlighted_ids.push(id);
      refresh_svg(map_data);
      window.alert(id);
    }
  }
}

function unhighlight_id(e) {
  document.getElementById("Seas").removeEventListener("click", unhighlight_id);
  let elem = e.target;
  id = elem.getAttribute("id");
  if (id) {
    if (map_data[current_sea].highlighted_ids.includes(id)) {
      map_data[current_sea].highlighted_ids = map_data[current_sea].highlighted_ids.filter(i => i !== id);
      refresh_svg(map_data);
      window.alert(id);
    }
  }
}

function stop_mouse_listeners() {
  document.getElementById("Seas").removeEventListener("click", highlight_id);
  document.getElementById("Seas").removeEventListener("click", unhighlight_id);
}  


function clone_current_sea(old_current_sea, new_current_sea) {
  if (new_current_sea in map_data) {
    window.alert("Current sea already exists! Switching but not copying.");
  } else {
    map_data[new_current_sea] = {};
    map_data[new_current_sea].x_offset = map_data[old_current_sea].x_offset;
    map_data[new_current_sea].y_offset = map_data[old_current_sea].y_offset;
    map_data[new_current_sea].width = map_data[old_current_sea].width;
    map_data[new_current_sea].lon_0 = map_data[old_current_sea].lon_0;
    map_data[new_current_sea].highlighted_ids = [];
    // don't copy highlight_ids as that will be changed anyway
  }
}

function change_current_sea() {
  let old_current_sea = current_sea;
  let f = document.getElementById("change_current_sea_dialog_holder");
  let textarea = document.getElementById("change_current_sea_dialog");
  let new_current_sea = textarea.value;

  clone_current_sea(old_current_sea, new_current_sea);
  current_sea = new_current_sea;
  refresh_svg(map_data);

  textarea.remove();
  f.remove();
  document.removeEventListener("keydown", change_current_sea_keydown);
  document.addEventListener("keydown", onkeydown);
}

function change_current_sea_keydown(e) {
  if (e.ctrlKey && (e.code === "Enter")) {
    change_current_sea();
  }
}

function change_current_sea_dialog() {
  let f = document.createElementNS("http://www.w3.org/2000/svg", "foreignObject");
  let textarea = document.createElementNS("http://www.w3.org/1999/xhtml", "textarea");
  f.setAttribute("id", "change_current_sea_dialog_holder");
  f.setAttribute("x", 20);
  f.setAttribute("y", 90);
  f.setAttribute("width", 400);
  f.setAttribute("height", 200);
  textarea.setAttribute("id", "change_current_sea_dialog");
  textarea.value = "";

  document.rootElement.append(f);
  f.append(textarea);

  document.removeEventListener("keydown", onkeydown);

  document.addEventListener("keydown", change_current_sea_keydown);
  textarea.focus()
}


function add_comment() {
  let f = document.getElementById("comment_dialog_holder");
  let textarea = document.getElementById("comment_dialog");
  let comment = textarea.value;

  if (comment !== "") {
    map_data[current_sea].comment = comment;
  }

  textarea.remove();
  f.remove();
  document.removeEventListener("keydown", comment_keydown);
  document.addEventListener("keydown", onkeydown);
}

function comment_keydown(e) {
  if (e.ctrlKey && (e.code === "Enter")) {
    add_comment();
  }
}

function comment_dialog() {
  let f = document.createElementNS("http://www.w3.org/2000/svg", "foreignObject");
  let textarea = document.createElementNS("http://www.w3.org/1999/xhtml", "textarea");
  f.setAttribute("id", "comment_dialog_holder");
  f.setAttribute("x", 20);
  f.setAttribute("y", 90);
  f.setAttribute("width", 400);
  f.setAttribute("height", 200);
  textarea.setAttribute("id", "comment_dialog");
  if ("comment" in map_data[current_sea]) {
    textarea.value = map_data[current_sea].comment;
  } else {
    textarea.value = "";
  }

  document.rootElement.append(f);
  f.append(textarea);

  document.removeEventListener("keydown", onkeydown);

  document.addEventListener("keydown", comment_keydown);
  textarea.focus()
}

// let s = document.getElementById("Seas")
// let cs = s.children;
// for (let i=0; i < cs.length; i++) {
//   let c = cs[i]
//   if (c.getAttribute("id") === null) {
//     c.setAttribute("stroke", "red");
//     c.setAttribute("stroke-width", "50px");
//   }
// }
