function hideTheBodies() {
  document.querySelectorAll("[id^='body-']").forEach((node) => {
    node.classList.add("d-none");
  });
};

function showBody(which) {
  document.querySelector("#body-" + which).classList.remove("d-none");
};

function renderHome() {
  showBody("home");
};

async function renderFiles() {
  // TODO: support directory structure
  const fileTable = document.getElementById("file-table");
  const tbody = fileTable.querySelector("tbody");
  const fileResponse = await fetch("/api/list", {
    cache: "no-store",
    credentials: "same-origin",
    headers: {
      "X-App-Id": "CWA",
    },
    method: "GET",
    mode: "same-origin",
  });
  if (fileResponse.status !== 200) {
    showBody("login");
    return;
  }
  const fileItems = await fileResponse.json();
  console.log("items", fileItems);
  const elements = new Array();
  fileItems.forEach((item) => {
    const row = document.createElement("tr");
    const nameNode = row.appendChild(document.createElement("td"));
    nameNode.classList.add("file-name");
    const nameLink = nameNode.appendChild(document.createElement("a"));
    //nameLink.setAttribute("download", item.name);
    nameLink.setAttribute("href", "/f/" + item.path);
    nameLink.textContent = item.name;
    const sizeNode = row.appendChild(document.createElement("td"));
    sizeNode.textContent = ((item.size >= 0) ? _sizify(item.size) : "");
    sizeNode.classList.add("file-size");
    const aclNode = row.appendChild(document.createElement("td"));
    aclNode.textContent = item.acl;
    aclNode.classList.add("file-acl");
    elements.push(row);
  });
  tbody.replaceChildren(...elements);
  showBody("files");
};

const logk = 1/Math.log(1024);
function _sizify(sz) {
  const sizes = ["B", "KiB", "MiB", "GiB", "TiB"];
  const idx = Math.min(Math.floor(Math.log(sz) * logk), sizes.length-1);
  const trunc = (sz / Math.pow(1024, idx)).toFixed(idx > 0 ? 1 : 0);
  return trunc + " " + sizes[idx];
};

function renderLogin() {
  showBody("login");
};

function renderNotFound() {
  showBody("notfound");
};

async function doLogout() {
  const response = await fetch("/api/logout", {
    cache: "no-store",
    credentials: "same-origin",
    headers: {
      "X-App-Id": "CWA",
    },
    method: "POST",
    mode: "same-origin",
  });
  if (response.status !== 200) {
    console.log("Got non-200 status %d on logout", response.status);
    return false;
  }
  return true;
};

async function handleLoginForm(form) {
  const formData = new FormData(form);
  const response = await fetch("/api/login", {
    body: formData,
    cache: "no-store",
    credentials: "same-origin",
    headers: {
      "X-App-Id": "CWA",
    },
    method: "POST",
    mode: "same-origin",
  });
  if (response.status === 200) {
    if (!isLoggedIn()) {
      console.log("200 status but not logged in!");
    } else {
      navigatePage("/files");
    }
  } else {
    // Display error
  }
};

function addClickHandler(selector, func) {
  document.querySelectorAll(selector).forEach((node) => {
    node.addEventListener("click", (evt) => {
      console.log("click event, node", evt, node);
      evt.preventDefault();
      func(evt, node);
    });
  });
};

function isLoggedIn() {
  const cookieSearch = "cwaid=";
  const cookiePieces = document.cookie.split(';');
  for (let i=0; i<cookiePieces.length; i++) {
    const piece = cookiePieces[i].trim();
    if (piece.startsWith(cookieSearch) && piece.length > cookieSearch.length) {
      // Assume any cookie value is valid
      return true;
    }
  }
  return false;
};

function setupHandlers() {
  addClickHandler("#menu-home", (e, n) => {
    if (isLoggedIn()) {
      navigatePage("/files");
    } else {
      navigatePage("/");
    }
  });
  addClickHandler("#menu-login", (e, n) => {
    navigatePage("/login");
  });
  addClickHandler("#menu-logout", async (e, n) => {
    hideTheBodies();
    if (await doLogout()) {
      navigatePage("/");
    }
  });
  const loginform = document.querySelector("#login-form");
  if (loginform !== null) {
    loginform.addEventListener("submit", (evt) => {
      evt.preventDefault();
      handleLoginForm(evt.target);
    });
    const loginButton = loginform.querySelector("#login-submit");
    if (loginButton !== null) {
      loginButton.addEventListener("click", (evt) => {
        evt.preventDefault();
        handleLoginForm(loginform);
      });
    }
  }
};

const pageHandlers = {
  "/": renderHome,
  "/files": renderFiles,
  "/login": renderLogin,
};

function navigatePage(path) {
  history.pushState({}, "", path);
  renderForPath(path);
};

function renderForPath(path) {
  hideTheBodies();
  if (path in pageHandlers) {
    pageHandlers[path]();
  } else {
    renderNotFound();
  }
};

function setup() {
  console.log('path', window.location.pathname);
  setupHandlers();
  renderForPath(window.location.pathname);
};

(function(){
  if (document.readyState === "loading") {
    window.addEventListener("DOMContentLoaded", (event) => {
      setup();
    });
  } else {
    setup();
  }
}());
