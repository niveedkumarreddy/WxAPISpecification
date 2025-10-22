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
  margin: 0; padding: 0; height: 100%; width: 100%;
  font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
  background-color: #fff; color: #222;
  display: flex; flex-direction: column; align-items: center; justify-content: flex-start;
}
h1 { margin: 20px 0; font-size: 2em; color: #333; text-align: center; }
.content { flex: 1; width: 95%; max-width: 1400px; display: flex; flex-direction: column; align-items: center; overflow: auto; }
table { width: 100%; border-collapse: collapse; background: #fafafa; border-radius: 10px;
  box-shadow: 0 4px 12px rgba(0,0,0,0.1); }
th, td { padding: 14px 18px; text-align: center; border-bottom: 1px solid #ddd; }
th { background: #f5f5f5; text-transform: uppercase; font-size: 0.9em; color: #555; }
tr:hover { background-color: #f1f7ff; transition: background 0.3s ease-in-out; }
a.endpoint-link { color: #0077cc; cursor: pointer; text-decoration: none; }
a.endpoint-link:hover { text-decoration: underline; color: #005999; }
button {
  padding: 6px 12px; background-color: #e0e0e0; border: 1px solid #ccc;
  border-radius: 4px; font-size: 1em; cursor: pointer;
}
button:hover { background-color: #d5d5d5; }

/* --- Modal Styles --- */
.modal {
  display: none; position: fixed; z-index: 1000; left: 0; top: 0;
  width: 100%; height: 100%; background: rgba(0,0,0,0.5);
  align-items: center; justify-content: center;
}
.modal-content {
  background: #fff; padding: 20px; border-radius: 10px;
  width: 80%; max-width: 900px; max-height: 80vh; overflow-y: auto;
  box-shadow: 0 4px 20px rgba(0,0,0,0.2);
}
.modal-header { display: flex; justify-content: space-between; align-items: center; }
.modal-header h2 { margin: 0; font-size: 1.2em; }
.modal-header button {
  background: #d33; color: white; border: none; padding: 5px 10px;
}
pre {
  background: #f8f9fa; border: 1px solid #ddd; padding: 10px; border-radius: 6px;
  white-space: pre-wrap; word-break: break-word; max-height: 65vh; overflow-y: auto;
}
.copy-btn, .download-btn {
  margin-top: 10px;
  background: #0077cc;
  color: white;
  border: none;
  border-radius: 4px;
  padding: 6px 12px;
  cursor: pointer;
}
.copy-btn:hover { background: #005fa3; }
.download-btn { background: #28a745; }
.download-btn:hover { background: #1f8a36; }
.btn-group { display: flex; gap: 10px; justify-content: center; margin-top: 10px; }
</style>
</head>
<body>
<div class="container">
<h1>API Specifications</h1>

%invoke WxAPISpecification.v1.services:getAPISpec%

<!-- Filters -->
<div style="margin-bottom: 20px;">
  <label>Package Name:
    <select id="packageFilter" onchange="onPackageChange()"><option value="">All</option></select>
  </label>
  <label>API Name:
    <select id="apiFilter" onchange="filterTable()"><option value="">All</option></select>
  </label>
  <label>Type:
    <select id="typeFilter" onchange="filterTable()"><option value="">All</option></select>
  </label>
  <label>Search:
    <input type="text" id="globalSearch" placeholder="Search..." oninput="filterTable()">
  </label>
  <button onclick="clearFilters()">Clear Filters</button>
</div>

<table id="apiTable">
  <thead>
    <tr>
      <th>Package Name</th>
      <th>API Name</th>
      <th>Type</th>
      <th>Download</th>
      <th>View</th>
    </tr>
  </thead>
  <tbody>
  %loop apiDetailsList%
    <tr data-package="%value packageName%" data-api="%value apiName%" data-type="%value type%" data-url="%value endpointUrl%">
      <td>%value packageName%</td>
      <td class="apiNameCell">%value apiName%</td>
      <td>%value type%</td>
      <td><a href="#" class="endpoint-link">Download</a></td>
      <td><button class="view-btn">View</button></td>
    </tr>
  %endloop%
  </tbody>
</table>

%onerror%
<p style="color:red">%value none errorMessage%</p>
%endinvoke%
</div>

<!-- Modal -->
<div id="specModal" class="modal">
  <div class="modal-content">
    <div class="modal-header">
      <h2>API Specification</h2>
      <button id="closeModal">&times;</button>
    </div>
    <pre id="specContent">Loading...</pre>
    <div class="btn-group">
      <button class="copy-btn" id="copySpec">Copy to Clipboard</button>
      <button class="download-btn" id="downloadSpec">Download</button>
    </div>
  </div>
</div>

<script>
function afterColon(str) {
  const idx = str.indexOf(':');
  return idx >= 0 ? str.substring(idx + 1).trim() : str;
}

let modalApiName = '', modalType = '', modalUrl = '';

document.addEventListener('DOMContentLoaded', function() {
  const trs = document.querySelectorAll('#apiTable tbody tr');
  const packages = new Set(), types = new Set(), apiMap = {}, allApis = new Set();

  trs.forEach(tr => {
    const pkg = tr.dataset.package, fullApi = tr.dataset.api, type = tr.dataset.type, api = afterColon(fullApi);
    tr.querySelector('.apiNameCell').textContent = api;
    packages.add(pkg); types.add(type); allApis.add(api);
    if (!apiMap[pkg]) apiMap[pkg] = new Set(); apiMap[pkg].add(api);

    tr.querySelector('a.endpoint-link').addEventListener('click', e => {
      e.preventDefault(); handleDownload(tr, api, type);
    });

    tr.querySelector('.view-btn').addEventListener('click', e => {
      e.preventDefault(); handleView(tr, api, type);
    });
  });

  populateFilters(packages, types, allApis, apiMap);
});

function populateFilters(packages, types, allApis, apiMap) {
  const pkgSel = document.getElementById('packageFilter');
  const typeSel = document.getElementById('typeFilter');
  const apiSel = document.getElementById('apiFilter');
  packages.forEach(p => pkgSel.append(new Option(p, p)));
  types.forEach(t => typeSel.append(new Option(t, t)));
  allApis.forEach(a => apiSel.append(new Option(a, a)));

  window.onPackageChange = function() {
    const selected = pkgSel.value;
    apiSel.innerHTML = '<option value="">All</option>';
    const apis = selected && apiMap[selected] ? apiMap[selected] : allApis;
    apis.forEach(a => apiSel.append(new Option(a, a)));
    filterTable();
  };
}

function filterTable() {
  const pkg = document.getElementById('packageFilter').value.toLowerCase();
  const api = document.getElementById('apiFilter').value.toLowerCase();
  const type = document.getElementById('typeFilter').value.toLowerCase();
  const search = document.getElementById('globalSearch').value.toLowerCase();

  document.querySelectorAll('#apiTable tbody tr').forEach(tr => {
    const [p,a,t] = [tr.cells[0].textContent, tr.cells[1].textContent, tr.cells[2].textContent].map(x=>x.toLowerCase());
    const show = (!pkg||p===pkg)&&(!api||a===api)&&(!type||t===type)&&(p.includes(search)||a.includes(search));
    tr.style.display = show ? '' : 'none';
  });
}

function clearFilters() {
  ['packageFilter','apiFilter','typeFilter','globalSearch'].forEach(id => document.getElementById(id).value = '');
  filterTable();
}

function getFormattedUrl(baseUrl, type) {
  if (type.toLowerCase().includes('swagger')) return baseUrl + '?swagger.json';
  if (type.toLowerCase().includes('openapi')) return baseUrl + '?openapi.json';
  if (type.toLowerCase().includes('wsdl')) return baseUrl + '?wsdl';
  return baseUrl;
}

function getFileExtension(type) {
  if (type.toLowerCase().includes('swagger') || type.toLowerCase().includes('openapi')) return '.json';
  if (type.toLowerCase().includes('wsdl')) return '.wsdl';
  return '.txt';
}

async function handleDownload(tr, api, type) {
  let url = tr.dataset.url;
  let fileName = api;

  const lowerType = type.toLowerCase();

  // Adjust based on type
      if (type.toLowerCase().includes('swagger')) {
        url = url.includes('swagger.json') ? url : url + '?swagger.json';
        fileName += '_swagger.json';
      } else if (type.toLowerCase().includes('openapi')) {
        url = url.includes('openapi.json') ? url : url + '?openapi.json';
        fileName += '_openapi.json';
      } else if (type.toLowerCase().includes('wsdl')) {
        if (!url.toLowerCase().endsWith('.wsdl')) url = url + '?wsdl';
        fileName += '.wsdl';
      } else {
        fileName += '.json';
      }

  try {
    const res = await fetch(url);
    if (!res.ok) throw new Error('Download failed');
    const blob = await res.blob();
    const a = document.createElement('a');
    a.href = URL.createObjectURL(blob);
    a.download = fileName;
    a.click();
    URL.revokeObjectURL(a.href);
  } catch (err) {
    alert(err.message);
  }
}

async function handleView(tr, api, type) {
  const modal = document.getElementById('specModal');
  const content = document.getElementById('specContent');
  content.textContent = 'Loading...';
  modal.style.display = 'flex';

  // Prepare values for modal download
  modalApiName = api;
  modalType = type;
  modalUrl = tr.dataset.url;

  const lowerType = type.toLowerCase();

  if (lowerType.includes('swagger')) {
    if (!modalUrl.toLowerCase().includes('swagger.json')) modalUrl += '?swagger.json';
  } else if (lowerType.includes('openapi')) {
    if (!modalUrl.toLowerCase().includes('openapi.json')) modalUrl += '?openapi.json';
  } else if (lowerType.includes('wsdl')) {
    if (!modalUrl.toLowerCase().includes('?wsdl')) modalUrl += '?wsdl';
  }

  try {
    const res = await fetch(modalUrl);
    const text = await res.text();
    try {
      content.textContent = JSON.stringify(JSON.parse(text), null, 2);
    } catch {
      content.textContent = text;
    }
  } catch (err) {
    content.textContent = 'Failed to load: ' + err.message;
  }
}

document.getElementById('closeModal').onclick = () => document.getElementById('specModal').style.display = 'none';

document.getElementById('copySpec').onclick = async () => {
  const text = document.getElementById('specContent').textContent;
  try {
    await navigator.clipboard.writeText(text);
    alert('Specification copied to clipboard!');
  } catch (e) { alert('Failed to copy.'); }
};

document.getElementById('downloadSpec').onclick = async () => {
  if (!modalUrl) { alert('No specification to download'); return; }
  const ext = getFileExtension(modalType);
  try {
    const res = await fetch(modalUrl);
    if (!res.ok) throw new Error('Download failed');
    const blob = await res.blob();
    const a = document.createElement('a');
    a.href = URL.createObjectURL(blob);
    a.download = modalApiName + ext;
    a.click();
    URL.revokeObjectURL(a.href);
  } catch (err) { alert(err.message); }
};

window.onclick = e => {
  const modal = document.getElementById('specModal');
  if (e.target === modal) modal.style.display = 'none';
};


</script>
</body>
</html>
