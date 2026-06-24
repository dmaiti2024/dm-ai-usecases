const CategorizePage = {
  CATEGORIES: ['Mortgage','Household','Utility','Restaurant','Dress','Indian Grocery','Misc'],
  transactions: [],

  async render() {
    const pc = document.getElementById('pageContent');
    pc.innerHTML = `<div class="loading-indicator"><div class="spinner-border text-danger"></div></div>`;
    try {
      this.transactions = (await TransactionAPI.getMyTransactions()).filter(t => t.transactionType === 'DEBIT');
      this._renderPage();
    } catch(e) {
      pc.innerHTML = `<div class="wf-alert-error">Failed to load: ${e.message}</div>`;
    }
  },

  _renderPage() {
    const pc = document.getElementById('pageContent');
    const now = new Date();
    const defaultStart = new Date(now.getFullYear(), now.getMonth(), 1).toISOString().split('T')[0];
    const defaultEnd   = now.toISOString().split('T')[0];
    pc.innerHTML = `
      <div class="page-title"><i class="fas fa-tags me-2"></i>Categorize Spending</div>
      <div class="wf-card mb-4">
        <div class="wf-card-header"><i class="fas fa-filter me-2"></i>Filter Debit Transactions</div>
        <div class="wf-card-body">
          <div class="row g-3 align-items-end">
            <div class="col-md-4">
              <label class="form-label small fw-semibold">From Date</label>
              <input type="date" id="catStart" class="form-control" value="${defaultStart}"/>
            </div>
            <div class="col-md-4">
              <label class="form-label small fw-semibold">To Date</label>
              <input type="date" id="catEnd" class="form-control" value="${defaultEnd}"/>
            </div>
            <div class="col-md-4">
              <button class="btn wf-btn-primary w-100" onclick="CategorizePage.filterAndRender()">
                <i class="fas fa-search me-1"></i>Load Transactions
              </button>
            </div>
          </div>
          <div class="ai-checkbox-wrap mt-3">
            <input type="checkbox" id="useAI"/>
            <label for="useAI" class="ai-checkbox-label">
              Use AI-Based Categorization <span class="ai-chip">AI</span>
            </label>
            <small class="text-muted ms-2">
              When checked, AI will auto-suggest a category for every transaction on load
            </small>
          </div>
        </div>
      </div>
      <div id="catResults">
        <div class="text-center text-muted py-4" style="border:2px dashed #e0e0e0;border-radius:8px;background:#fafafa">
          <i class="fas fa-tags fa-2x mb-2" style="color:#ccc"></i>
          <div>Select a date range and click <strong>Load Transactions</strong></div>
          <div class="small mt-1">Check <strong>Use AI-Based Categorization</strong> to let AI suggest categories automatically</div>
        </div>
      </div>`;
    // Do NOT auto-load — user must click "Load Transactions" explicitly
  },

  filterAndRender() {
    const start = document.getElementById('catStart')?.value;
    const end   = document.getElementById('catEnd')?.value;
    if (!start || !end) return;

    const s = new Date(start);
    const e = new Date(end); e.setHours(23, 59, 59);

    const filtered = this.transactions.filter(t => {
      const d = new Date(t.transactionDate);
      return d >= s && d <= e;
    });

    const useAI = document.getElementById('useAI')?.checked;
    this._renderResults(filtered, useAI);
  },

  _renderResults(txns, useAI) {
    const el = document.getElementById('catResults');
    if (!txns.length) {
      el.innerHTML = `<div class="wf-alert-error">No debit transactions found for the selected period.</div>`;
      return;
    }

    const catOptions = this.CATEGORIES.map(c => `<option value="${c}">${c}</option>`).join('');

    el.innerHTML = `
      <div class="wf-card">
        <div class="wf-card-header">
          <span>
            <i class="fas fa-tags me-2"></i>${txns.length} Debit Transactions
            ${useAI ? '<span class="ai-chip ms-2">AI Mode</span>' : '<span style="font-size:11px;opacity:.8;margin-left:8px">Manual Mode</span>'}
          </span>
          <button class="wf-btn-sm" onclick="CategorizePage.saveAll()">
            <i class="fas fa-save me-1"></i>Save All
          </button>
        </div>
        <div id="aiProgressBar" class="d-none" style="background:#fff3cd;padding:10px 16px;font-size:13px;border-bottom:1px solid #ffe69c">
          <i class="fas fa-robot me-2 text-warning"></i>
          <span id="aiProgressText">AI is categorizing transactions...</span>
          <div class="progress mt-2" style="height:6px">
            <div id="aiProgressFill" class="progress-bar bg-danger" style="width:0%"></div>
          </div>
        </div>
        <div class="wf-card-body p-0">
          <div class="table-responsive">
            <table class="wf-table">
              <thead><tr>
                <th>Date</th><th>Description</th><th>Merchant</th>
                <th>Amount</th><th>Category</th><th>Source</th>
                <th>AI</th>
              </tr></thead>
              <tbody id="catTableBody">
                ${txns.map(t => `
                  <tr data-id="${t.transactionId}">
                    <td nowrap>${fmtDate(t.transactionDate)}</td>
                    <td>${t.description || ''}</td>
                    <td><small>${t.merchantName || ''}</small></td>
                    <td class="amount-debit">−${fmtMoney(t.amount)}</td>
                    <td>
                      <select class="wf-select cat-select" data-id="${t.transactionId}" data-original="${t.category || ''}">
                        <option value="">-- Select --</option>
                        ${catOptions}
                      </select>
                    </td>
                    <td id="src-${t.transactionId}">
                      ${t.category
                        ? `<span class="cat-source-saved" title="Saved category from database">Saved</span>`
                        : `<span class="cat-source-none">None</span>`}
                    </td>
                    <td>
                      <button class="wf-btn-secondary ai-row-btn"
                        style="font-size:11px;padding:4px 8px"
                        data-id="${t.transactionId}"
                        data-desc="${(t.description || '').replace(/"/g, '&quot;')}"
                        data-amount="${t.amount}"
                        onclick="CategorizePage.aiCategorizeRow(this)">
                        <i class="fas fa-robot me-1"></i>AI
                      </button>
                    </td>
                  </tr>`).join('')}
              </tbody>
            </table>
          </div>
        </div>
      </div>`;

    // Pre-fill existing DB categories into dropdowns (manual mode — no AI)
    txns.forEach(t => {
      if (t.category) {
        const sel = document.querySelector(`select.cat-select[data-id="${t.transactionId}"]`);
        if (sel) sel.value = t.category;
      }
    });

    // If AI checkbox is checked, auto-categorize all rows
    if (useAI) {
      this._aiCategorizeAll(txns);
    }
  },

  // Auto-categorize every transaction sequentially when AI checkbox is on
  async _aiCategorizeAll(txns) {
    const progressBar  = document.getElementById('aiProgressBar');
    const progressText = document.getElementById('aiProgressText');
    const progressFill = document.getElementById('aiProgressFill');

    progressBar.classList.remove('d-none');
    let done = 0;

    for (const t of txns) {
      progressText.textContent = `AI categorizing: "${t.description}" (${done + 1} of ${txns.length})`;
      progressFill.style.width = `${Math.round((done / txns.length) * 100)}%`;

      try {
        const res = await CategorizationAPI.categorize(t.description, t.amount);
        if (res.suggestedCategory) {
          const sel = document.querySelector(`select.cat-select[data-id="${t.transactionId}"]`);
          const src = document.getElementById(`src-${t.transactionId}`);
          if (sel) sel.value = res.suggestedCategory;
          if (src) src.innerHTML = `<span class="cat-source-ai" title="${res.reasoning || ''}">AI ✦</span>`;
        }
      } catch(e) {
        // skip individual failures silently
      }
      done++;
    }

    progressFill.style.width = '100%';
    progressText.textContent = `✓ AI categorized ${done} transactions. Review and click Save All to confirm.`;
    setTimeout(() => progressBar.classList.add('d-none'), 4000);
  },

  // Per-row AI button (works regardless of checkbox state)
  async aiCategorizeRow(btn) {
    const txnId  = btn.dataset.id;
    const desc   = btn.dataset.desc;
    const amount = parseFloat(btn.dataset.amount);
    const src    = document.getElementById(`src-${txnId}`);

    btn.innerHTML = '<i class="fas fa-spinner fa-spin"></i>';
    btn.disabled  = true;

    try {
      const res = await CategorizationAPI.categorize(desc, amount);
      const sel = document.querySelector(`select.cat-select[data-id="${txnId}"]`);
      if (sel && res.suggestedCategory) sel.value = res.suggestedCategory;
      if (src) src.innerHTML = `<span class="cat-source-ai" title="${res.reasoning || ''}">AI ✦</span>`;
      btn.innerHTML = '<i class="fas fa-check" style="color:#2E7D32"></i>';
      btn.title = res.reasoning || '';
    } catch(e) {
      btn.innerHTML = '<i class="fas fa-times" style="color:#C8102E"></i>';
      btn.title = 'AI categorization failed';
    } finally {
      btn.disabled = false;
    }
  },

  async saveAll() {
    const selects = document.querySelectorAll('select.cat-select');
    let saved = 0, skipped = 0, failed = 0;
    for (const sel of selects) {
      if (!sel.value) { skipped++; continue; }
      try {
        await TransactionAPI.updateCategory(parseInt(sel.dataset.id), sel.value);
        // Update source badge to "Saved" after persisting
        const src = document.getElementById(`src-${sel.dataset.id}`);
        if (src) src.innerHTML = `<span class="cat-source-saved">Saved</span>`;
        saved++;
      } catch { failed++; }
    }
    const msg = `Saved: ${saved}${skipped ? ` | Skipped (no category): ${skipped}` : ''}${failed ? ` | Failed: ${failed}` : ''}`;
    const banner = document.createElement('div');
    banner.className = `wf-alert-${failed ? 'error' : 'success'} mb-3`;
    banner.textContent = msg;
    document.getElementById('catResults').prepend(banner);
    setTimeout(() => banner.remove(), 4000);
  }
};
