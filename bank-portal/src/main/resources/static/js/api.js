const API_BASE = 'http://localhost:9081';

function getToken() { return localStorage.getItem('wf_token'); }
function getCustomerId() { return localStorage.getItem('wf_customer_id'); }

async function apiFetch(path, options = {}) {
  const token = getToken();
  const headers = { 'Content-Type': 'application/json', ...(options.headers || {}) };
  if (token) headers['Authorization'] = `Bearer ${token}`;
  const res = await fetch(API_BASE + path, { ...options, headers });
  if (!res.ok) {
    const err = await res.text().catch(() => 'Error');
    throw new Error(`${res.status}: ${err}`);
  }
  return res.json().catch(() => ({}));
}

const AuthAPI = {
  login: (username, password) => apiFetch('/api/auth/login', {
    method: 'POST', body: JSON.stringify({ username, password })
  })
};

const AccountAPI = {
  getMyAccounts: () => apiFetch('/api/accounts/my'),
  getByCustomer: (id) => apiFetch(`/api/accounts/customer/${id}`)
};

const TransactionAPI = {
  post: (data) => apiFetch('/api/transactions', { method: 'POST', body: JSON.stringify(data) }),
  getMyTransactions: () => apiFetch('/api/transactions/my'),
  getByAccount: (id) => apiFetch(`/api/transactions/account/${id}`),
  getByCustomer: (id) => apiFetch(`/api/transactions/customer/${id}`),
  getDebits: (accountId, start, end) => apiFetch(`/api/transactions/debits/${accountId}?start=${encodeURIComponent(start)}&end=${encodeURIComponent(end)}`),
  updateCategory: (transactionId, category) => apiFetch('/api/transactions/category', {
    method: 'PUT', body: JSON.stringify({ transactionId, category })
  }),
  raiseDispute: (data) => apiFetch('/api/transactions/dispute', { method: 'POST', body: JSON.stringify(data) }),
  getMyDisputes: () => apiFetch('/api/transactions/disputes/my'),
  getDisputesByCustomer: (id) => apiFetch(`/api/transactions/disputes/customer/${id}`)
};

const CategorizationAPI = {
  categorize: (description, amount) => apiFetch('/api/categorize', {
    method: 'POST', body: JSON.stringify({ description, amount })
  })
};
