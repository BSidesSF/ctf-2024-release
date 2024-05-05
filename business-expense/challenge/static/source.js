window.addEventListener("load", () => {
	updateTable();

	document.querySelector("#addrow").onclick = () => addButton.addRow(document.querySelector("#table").children[1]);
	document.querySelector("#save").onclick = () => saveButton.saveExpenses(document.querySelector("#table"));
	document.querySelector("#submit").onclick = () => {saveButton.saveExpenses(document.querySelector("#table"));submitButton.submitExpenses();}
	checkStatus();
});

function checkStatus(){
	var xhttp = new XMLHttpRequest();

	xhttp.onreadystatechange = function() {
		if (xhttp.readyState == XMLHttpRequest.DONE){
			statusDiv = document.getElementById("status");
			statusDiv.innerHTML=xhttp.responseText;
		}
	}

	xhttp.open("GET", "/api/getStatus");
	xhttp.send();

	setTimeout(checkStatus, 5000);
}


function updateTable(){
	for (let cell of document.querySelectorAll(".editable td:not(.static)")) {
		cell.ondblclick = () => editable.edit(cell);
	}

	for (let button of document.querySelectorAll(".remove")){
		button.onclick = () => remove.remove(button.parentElement.parentElement);
	}


}

var submitButton = {
	submitExpenses : () => {
		var xhttp = new XMLHttpRequest();
		xhttp.open("POST", "/api/addToQueue");
		xhttp.send();
	}
}

var saveButton = {
	saveExpenses : table => {
		payload = tableToJson(table);

		xhttp = new XMLHttpRequest();

		xhttp.open("POST", "/api/saveExpenses");

		xhttp.setRequestHeader("Content-Type", "application/json;charset=UTF-8");
		xhttp.send(JSON.stringify(payload));
	}
}

var editable = {
	selected: null,
	oldValue: "",
	type: "",

	edit : cell => {
		cell.ondblclick = ""

		cell.contentEditable = true;
		cell.focus();

		cell.classList.add("edit");
		editable.selected = cell;
		editable.oldValue = cell.innerHTML;
		editable.type = cell.classList[0];

		window.addEventListener("click", editable.close);
		cell.onkeydown = evt => { if (evt.key=="Enter" || evt.key=="Escape"){

			editable.close(editable.close(evt.key=="Enter" ? true:false));
			
			return false;
		}};
	},
	
	close : evt => { if (evt && evt.target != editable.selected){
		if(evt === false ||
		   (editable.type == "expense" && editable.selected.textContent.length > 50) ||
		   (editable.type == "cost" && (isNaN(editable.selected.textContent))) || 
		   (editable.type == "currency" && editable.selected.textContent.length > 10)){
			editable.selected.innerHTML = editable.oldValue;
		}

		window.getSelection().removeAllRanges();
		editable.selected.contentEditable = false;

		window.removeEventListener("click", editable.close);
		let cell = editable.selected;
		cell.onkeydown = "";
		cell.ondblclick = () => editable.edit(cell);

		editable.selected.classList.remove("edit");
		editable.selected = null;
		editable.oldValue = "";

		if (evt !== false){
			console.log(cell.innerHTML);
			//This is where I'd make a post request to the server to update it
			//Or maybe just keep it as is and only submit the table when the user presses a button
			//IDK I'll figure it out on Saturday
		}
	}}
};

var remove = {
	remove : row => {
		row.remove();
	}
};

var addButton = {
	addRow : table => {
		newRow = document.createElement("tr");
		cell = document.createElement("td");
		cell.className="expense";
		newRow.appendChild(cell);

		cell = document.createElement("td");
		cell.className="cost";
		newRow.appendChild(cell);
		
		cell = document.createElement("td");
		cell.className="currency";
		newRow.appendChild(cell);
		

		button = document.createElement("button");
		button.className = "static remove";
		text = document.createTextNode("x");
		button.appendChild(text)

		cell = document.createElement("td");
		cell.className = "static";
		cell.appendChild(button);
		newRow.appendChild(cell);
		table.appendChild(newRow);
		updateTable();
	}
};

function tableToJson(table){
	var data = [];

	var headers = [];

	for(var i=0; i<table.rows[0].cells.length; i++){
		headers[i] = table.rows[0].cells[i].classList[0];
	}

	for(var i=1; i<table.rows.length; i++){
		var tableRow = table.rows[i];
		var rowData ={};

		for (var j=0; j<tableRow.cells.length-1; j++){
			rowData[headers[j]] = tableRow.cells[j].textContent.trim();
		}

		data.push(rowData);

	}
	alert
	return data;
}
