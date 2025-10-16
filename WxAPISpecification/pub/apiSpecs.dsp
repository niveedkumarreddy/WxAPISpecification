<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>API Specifications</title>
<meta http-equiv="Expires" content="-1">
<meta http-equiv="Pragma" content="no-cache;must-revalidate">
<meta http-equiv="refresh" content="600">
<style>
html, body {
  margin: 0;
  padding: 0;
  height: 100%;
  width: 100%;
  font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
  background-color: #fff;
  color: #222;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: flex-start;
}
h1 {
  margin: 20px 0;
  font-size: 2em;
  color: #333;
  text-align: center;
}
.content {
  flex: 1;
  width: 95%;
  max-width: 1400px;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: flex-start;
  overflow: auto;
}
table {
  width: 100%;
  border-collapse: collapse;
  background: #fafafa;
  border-radius: 10px;
  overflow: hidden;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
  table-layout: auto;
  word-wrap: break-word;
}
caption {
  font-size: 1.3em;
  font-weight: 600;
  color: #444;
  padding: 12px;
  background: #f0f0f0;
  border-bottom: 2px solid #ddd;
}
th, td {
  padding: 14px 18px;
  text-align: center;
  border-bottom: 1px solid #ddd;
}
th {
  background: #f5f5f5;
  text-transform: uppercase;
  font-size: 0.9em;
  color: #555;
}
tr:hover {
  background-color: #f1f7ff;
  transition: background 0.3s ease-in-out;
}
td {
  font-size: 0.95em;
  color: #333;
}
td:nth-child(4) {
  word-break: break-all;
}
a.endpoint-link {
  color: #0077cc;
  text-decoration: none;
  cursor: pointer;
  word-break: break-all;
}
a.endpoint-link:hover {
  text-decoration: underline;
  color: #005999;
}
select, input[type="text"] {
  margin-right: 10px;
  padding: 5px;
  font-size: 1em;
  max-width: 200px;
}
button {
  padding: 6px 12px;
  background-color: #e0e0e0;
  border: 1px solid #ccc;
  border-radius: 4px;
  font-size: 1em;
  cursor: pointer;
  transition: background-color 0.2s;
}
button:hover {
  background-color: #d5d5d5;
}
</style>
</head>
<body>
<div class="container">
<h1>API Specifications</h1>

%invoke WxAPISpecification.v1.services:getAPISpec%

<!-- Dropdown Filters -->
<div style="margin-bottom: 20px;">
  <label>Package Name:
    <select id="packageFilter" onchange="onPackageChange()">
      <option value="">All</option>
    </select>
  </label>
  <label>API Name:
    <select id="apiFilter" onchange="filterTable()">
      <option value="">All</option>
    </select>
  </label>
  <label>Type:
    <select id="typeFilter" onchange="filterTable()">
      <option value="">All</option>
    </select>
  </label>
  <label>Search:
    <input type="text" id="globalSearch" placeholder="Search package or API..." oninput="filterTable()">
  </label>
  <button onclick="clearFilters()">Clear Filters</button>
</div>

<table id="apiTable">
  <caption>API Details</caption>
  <thead>
    <tr>
      <th>Package Name</th>
      <th>API Name</th>
      <th>Type</th>
      <th>Endpoint URL</th>
    </tr>
  </thead>
  <tbody>
  %loop apiDetailsList%
    <tr data-package="%value packageName%" data-api="%value apiName%" data-type="%value type%" data-url="%value endpointUrl%">
      <td>%value packageName%</td>
      <td class="apiNameCell">%value apiName%</td>
      <td>%value type%</td>
      <td><a href="#" class="endpoint-link">Download</a></td>
    </tr>
  %endloop%
  </tbody>
</table>

%onerror%
<p class="error">The server encountered a temporary error and could not complete your request.<br>Please try again later.</p>
<p class="error" style="color: red">%value none errorMessage%</p>
%endinvoke%
</div>

<script>
// Helper: get substring after colon
function afterColon(str) {
  const idx = str.indexOf(':');
  return idx >= 0 ? str.substring(idx + 1).trim() : str;
}

document.addEventListener('DOMContentLoaded', function() {
  const trs = document.querySelectorAll('#apiTable tbody tr');
  const packages = new Set();
  const types = new Set();
  const apiMap = {};
  const allApis = new Set();

  trs.forEach(tr => {
    const pkg = tr.getAttribute('data-package');
    const fullApi = tr.getAttribute('data-api');
    const type = tr.getAttribute('data-type');
    const api = afterColon(fullApi);

    // Replace displayed API name
    tr.querySelector('.apiNameCell').textContent = api;

    packages.add(pkg);
    types.add(type);
    allApis.add(api);

    if (!apiMap[pkg]) apiMap[pkg] = new Set();
    apiMap[pkg].add(api);

    // Download handler
    const link = tr.querySelector('a.endpoint-link');
    link.addEventListener('click', async (e) => {
      e.preventDefault();
      const url = tr.getAttribute('data-url');
      let finalUrl = url;
      let fileName = api;

      // Adjust based on type
      if (type.toLowerCase().includes('swagger')) {
        finalUrl = url.includes('swagger.json') ? url : url + '?swagger.json';
        fileName += '_swagger.json';
      } else if (type.toLowerCase().includes('openapi')) {
        finalUrl = url.includes('openapi.json') ? url : url + '?openapi.json';
        fileName += '_openapi.json';
      } else if (type.toLowerCase().includes('wsdl')) {
        if (!url.toLowerCase().endsWith('.wsdl')) finalUrl = url + '?wsdl';
        fileName += '.wsdl';
      } else {
        fileName += '.json';
      }

      try {
        const res = await fetch(finalUrl);
        if (!res.ok) throw new Error('Network response was not ok');
        const blob = await res.blob();
        const a = document.createElement('a');
        a.href = URL.createObjectURL(blob);
        a.download = fileName;
        a.click();
        URL.revokeObjectURL(a.href);
      } catch (err) {
        alert('Failed to download: ' + err.message);
      }
    });
  });

  // Populate dropdowns
  const packageFilter = document.getElementById('packageFilter');
  const apiFilter = document.getElementById('apiFilter');
  const typeFilter = document.getElementById('typeFilter');

  packages.forEach(p => {
    const opt = document.createElement('option');
    opt.value = p;
    opt.textContent = p;
    packageFilter.appendChild(opt);
  });
  types.forEach(t => {
    const opt = document.createElement('option');
    opt.value = t;
    opt.textContent = t;
    typeFilter.appendChild(opt);
  });
  allApis.forEach(a => {
    const opt = document.createElement('option');
    opt.value = a;
    opt.textContent = a;
    apiFilter.appendChild(opt);
  });

  window.onPackageChange = function() {
    const selected = packageFilter.value;
    apiFilter.innerHTML = '<option value="">All</option>';
    let apiSet = new Set();

    if (selected && apiMap[selected]) {
      apiSet = apiMap[selected];
    } else {
      allApis.forEach(a => apiSet.add(a));
    }

    apiSet.forEach(a => {
      const opt = document.createElement('option');
      opt.value = a;
      opt.textContent = a;
      apiFilter.appendChild(opt);
    });

    filterTable();
  };
});

// Unified filter logic
function filterTable() {
  const packageFilter = document.getElementById('packageFilter').value.toLowerCase();
  const apiFilter = document.getElementById('apiFilter').value.toLowerCase();
  const typeFilter = document.getElementById('typeFilter').value.toLowerCase();
  const globalSearch = document.getElementById('globalSearch')?.value.toLowerCase() || '';

  const trs = document.querySelectorAll('#apiTable tbody tr');
  trs.forEach(tr => {
    const tdPackage = tr.cells[0].textContent.toLowerCase();
    const tdApi = tr.cells[1].textContent.toLowerCase();
    const tdType = tr.cells[2].textContent.toLowerCase();

    const show =
      (tdPackage === packageFilter || !packageFilter) &&
      (tdApi === apiFilter || !apiFilter) &&
      (tdType === typeFilter || !typeFilter) &&
      (tdPackage.includes(globalSearch) || tdApi.includes(globalSearch));

    tr.style.display = show ? '' : 'none';
  });
}

// Clear filters
function clearFilters() {
  document.getElementById('packageFilter').value = '';
  document.getElementById('apiFilter').value = '';
  document.getElementById('typeFilter').value = '';
  document.getElementById('globalSearch').value = '';
  onPackageChange();
  filterTable();
}
</script>
</body>
</html>
