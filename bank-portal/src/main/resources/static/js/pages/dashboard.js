const DashboardPage = {
  async render() {
    const pc = document.getElementById('pageContent');
    pc.innerHTML = `<div class="loading-indicator"><div class="spinner-border text-danger"></div></div>`;
    try {
      const [accounts, transactions] = await Promise.all([
        AccountAPI.getMyAccounts(),
        TransactionAPI.getMyTransactions()
      ]);
      const totalBalance = accounts.reduce((s, a) => s + parseFloat(a.balance), 0);
      const credits = transactions.filter(t => t.transactionType === 'CREDIT').reduce((s, t) => s + parseFloat(t.amount), 0);
      const debits  = transactions.filter(t => t.transactionType === 'DEBIT').reduce((s, t) => s + parseFloat(t.amount), 0);
      const recent  = transactions.slice(0, 10);

      pc.innerHTML = `
        <div class="page-title"><i class="fas fa-th-large me-2"></i>Account Summary</div>
        <div class="account-grid">${accounts.map(a => `
          <div class="account-card">
            <div class="account-badge">${a.accountStatus}</div>
            <div class="account-card-type">${a.accountType} Account</div>
            <div class="account-card-number">&#9679;&#9679;&#9679;&#9679; &#9679;&#9679;&#9679;&#9679; &#9679;&#9679;&#9679;&#9679; ${a.accountNumber.slice(-4)}</div>
            <div class="account-card-balance">${fmtMoney(a.balance)}</div>
            <div class="account-card-available">Available Balance: ${fmtMoney(a.availableBalance)}</div>
          </div>`).join('')}
        </div>

        <div class="stats-grid">
          <div class="stat-card">
            <div class="stat-label">Total Balance</div>
            <div class="stat-value positive">${fmtMoney(totalBalance)}</div>
          </div>
          <div class="stat-card">
            <div class="stat-label">Total Credits</div>
            <div class="stat-value positive">${fmtMoney(credits)}</div>
          </div>
          <div class="stat-card">
            <div class="stat-label">Total Debits</div>
            <div class="stat-value negative">${fmtMoney(debits)}</div>
          </div>
          <div class="stat-card">
            <div class="stat-label">Total Transactions</div>
            <div class="stat-value">${transactions.length}</div>
          </div>
        </div>

        <div class="wf-card">
          <div class="wf-card-header"><span><i class="fas fa-clock me-2"></i>Recent Transactions</span></div>
          <div class="wf-card-body p-0">
            <table class="wf-table">
              <thead><tr>
                <th>Date</th><th>Description</th><th>Type</th><th>Category</th><th>Amount</th><th>Status</th>
              </tr></thead>
              <tbody>${recent.map(t => `<tr>
                <td>${fmtDate(t.transactionDate)}</td>
                <td><strong>${t.description || ''}</strong><br><small class="text-muted">${t.merchantName || ''}</small></td>
                <td><span class="badge-${t.transactionType.toLowerCase()}">${t.transactionType}</span></td>
                <td>${t.category || '<span class="text-muted">—</span>'}</td>
                <td class="amount-${t.transactionType.toLowerCase()}">${t.transactionType==='CREDIT'?'+':'−'}${fmtMoney(t.amount)}</td>
                <td>${statusBadge(t.status)}</td>
              </tr>`).join('')}
              </tbody>
            </table>
          </div>
        </div>`;
    } catch(e) {
      pc.innerHTML = `<div class="wf-alert-error"><i class="fas fa-exclamation-circle me-2"></i>Failed to load dashboard: ${e.message}</div>`;
    }
  }
};

function fmtMoney(v) {
  return new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' }).format(v || 0);
}
function fmtDate(d) {
  if (!d) return '';
  return new Date(d).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' });
}
function statusBadge(s) {
  const map = { COMPLETED: 'badge-credit', PENDING: 'badge-disputed', DISPUTED: 'badge-debit' };
  return `<span class="${map[s]||'badge-disputed'}">${s}</span>`;
}
