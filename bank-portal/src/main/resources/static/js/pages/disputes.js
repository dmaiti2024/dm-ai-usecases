const DisputesPage = {
  async render() {
    const pc = document.getElementById('pageContent');
    pc.innerHTML = `<div class="loading-indicator"><div class="spinner-border text-danger"></div></div>`;
    try {
      const disputes = await TransactionAPI.getMyDisputes();
      pc.innerHTML = `
        <div class="page-title"><i class="fas fa-flag me-2"></i>My Disputes</div>
        ${!disputes.length ? `<div class="wf-alert-success">You have no disputes filed.</div>` : `
        <div class="wf-card">
          <div class="wf-card-header"><span><i class="fas fa-flag me-2"></i>${disputes.length} Dispute${disputes.length!==1?'s':''}</span></div>
          <div class="wf-card-body p-0">
            <table class="wf-table">
              <thead><tr>
                <th>Dispute #</th><th>Transaction ID</th><th>Raised By</th>
                <th>Reason</th><th>Status</th><th>Raised Date</th><th>Resolution</th>
              </tr></thead>
              <tbody>${disputes.map(d => `<tr>
                <td><strong>#${d.disputeId}</strong></td>
                <td>TXN-${d.transactionId}</td>
                <td>${d.raisedBy}</td>
                <td style="max-width:200px">${d.disputeReason}</td>
                <td><span class="dispute-badge dispute-${d.disputeStatus.toLowerCase()}">${d.disputeStatus}</span></td>
                <td nowrap>${fmtDate(d.raisedDate)}</td>
                <td style="max-width:200px">${d.resolution||'<span class="text-muted">Pending</span>'}</td>
              </tr>`).join('')}
              </tbody>
            </table>
          </div>
        </div>`}`;
    } catch(e) {
      pc.innerHTML = `<div class="wf-alert-error">Failed to load disputes: ${e.message}</div>`;
    }
  }
};
