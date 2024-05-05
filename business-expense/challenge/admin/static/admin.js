
window.addEventListener("load", () => {

	document.querySelector("#approve").onclick = () => statusButtons.updateStatus("Accepted", document.getElementById("approve").value);
	document.querySelector("#deny").onclick = () => statusButtons.updateStatus("Denied", document.getElementById("deny").value);
	
	setTimeout(statusButtons.updateStatus, 1000, "Accepted", document.getElementById("approve").value);
});



var statusButtons = {
	updateStatus : (message, popID) => {
		var xhttp = new XMLHttpRequest();
		xhttp.open("POST", "/api/updateExpenseStatus")
		xhttp.setRequestHeader("Content-Type", "application/json")
		xhttp.onreadystatechange = () => {location.reload();};
		xhttp.send(JSON.stringify({"popID": popID, "status": message}))
		console.log(xhttp.status)
	}
}
