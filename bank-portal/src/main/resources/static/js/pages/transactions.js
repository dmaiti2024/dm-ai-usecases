const TransactionsPage = {
  allTransactions: [],
  async render() {
    const pc = document.getElementById('pageContent');
    pc.innerHTML = `<div class="loading-indicator"><div class="spinner-border text-danger"></div></div>`;
    try {
      this.allTransactions = await TransactionAPI.getMyTransactions();
      this._renderTable();
    } catch(e) {
      pc.innerHTML = `<div class="wf-alert-error">Failed to load transactions: ${e.message}</div>`;
    }
  },
  _renderTable(filter = 'ALL') {
    const pc = document.getElementById('pageContent');
    const txns = filter === 'ALL' ? this.allTransactions : this.allTransactions.filter(t => t.transactionType === filter);
    pc.innerHTML = `
      <div class="page-title"><i class="fas fa-exchange-alt me-2"></i>Transaction History</div>
      <div class="d-flex align-items-center gap-3 mb-4 flex-wrap">
        <div>
          <label class="form-label small fw-semibold mb-1">Filter by Type</label>
          <select id="txnFilter" class="wf-select">
            <option value="ALL">All Transactions</option>
            <option value="CREDIT">Credits Only</option>
            <option value="DEBIT">Debits Only</option>
          </select>
        </div>
        <div class="ms-auto">
          <span class="text-muted small">${txns.length} transaction${txns.length !== 1 ? 's' : ''}</span>
        </div>
      </div>
      <div class="wf-card">
        <div class="wf-card-header"><span><i class="fas fa-list me-2"></i>Transactions</span></div>
        <div class="wf-card-body p-0">
          <div class="table-responsive">
          <table class="wf-table">
            <thead><tr>
              <th>Date</th><th>Description</th><th>Account</th><th>Type</th><th>Category</th><th>Amount</th><th>Ref No</th><th>Status</th><th>Action</th>
            </tr></thead>
            <tbody>${txns.map(t => `<tr>
              <td nowrap>${fmtDate(t.transactionDate)}</td>
              <td><strong>${t.description||''}</strong><br><small class="text-muted">${t.merchantName||''}</small></td>
              <td><small>••••${(t.accountNumber||'').slice(-4)}</small></td>
              <td><span class="badge-${t.transactionType.toLowerCase()}">${t.transactionType}</span></td>
              <td>${t.category||'<span class="text-muted">Uncategorized</span>'}</td>
              <td nowrap class="amount-${t.transactionType.toLowerCase()}">${t.transactionType==='CREDIT'?'+':'−'}${fmtMoney(t.amount)}</td>
              <td><small class="text-muted">${t.referenceNo||''}</small></td>
              <td>${statusBadge(t.status)}</td>
              <td>${t.transactionType==='DEBIT' && t.status!=='DISPUTED' ? `<button class="wf-btn-sm" onclick="TransactionsPage.openDispute(${t.transactionId})"><i class="fas fa-flag"></i> Dispute</button>` : ''}</td>
            </tr>`).join('')}
            </tbody>
          </table>
          </div>
        </div>
      </div>`;
    document.getElementById('txnFilter').value = filter;
    document.getElementById('txnFilter').addEventListener('change', e => this._renderTable(e.target.value));
  },
  openDispute(txnId) {
    const reason = prompt('Please describe the reason for your dispute:');
    if (!reason) return;
    const customerId = parseInt(localStorage.getItem('wf_customer_id'));
    const username = localStorage.getItem('wf_username');
    TransactionAPI.raiseDispute({ transactionId: txnId, customerId, raisedBy: username, disputeReason: reason })
      .then(() => { alert('Dispute raised successfully. Our team will review it.'); this.render(); })
      .catch(e => alert('Failed to raise dispute: ' + e.message));
  }
};
