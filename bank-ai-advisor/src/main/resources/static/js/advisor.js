const API_BASE = 'http://localhost:8095';
let sessionId = 'session-' + Date.now();
let currentRole = 'customer';
let isWaiting = false;

const QUICK_QUESTIONS = {
  customer: [
    'What is my total balance across all accounts?',
    'Show my spending breakdown by category for 2025',
    'How much did I spend on groceries this year?',
    'What are my recent transactions?',
    'Compare my income vs expenses for 2024',
    'Analyze my spending trends over the last 6 months'
  ],
  helpdesk: [
    'Show all transactions for customer John Smith (ID 1)',
    'What is Sarah Johnson\'s account balance? (ID 2)',
    'Analyze spending patterns for customer ID 1 vs customer ID 2',
    'Show all open disputes',
    'Find suspicious transactions for customer 1',
    'Compare income vs expenses for both customers in 2024'
  ]
};

function init() {
  updateSessionDisplay();
  updateRoleDisplay();
  renderQuickQuestions();
  checkHealth();

  document.getElementById('roleSelect').addEventListener('change', function() {
    currentRole = this.value;
    updateRoleDisplay();
    renderQuickQuestions();
  });
}

function updateSessionDisplay() {
  document.getElementById('sessionId').textContent = sessionId.split('-').slice(-1)[0];
}

function updateRoleDisplay() {
  const el = document.getElementById('modeDisplay');
  if (currentRole === 'helpdesk') {
    el.textContent = 'Helpdesk Staff';
    el.className = 'mode-badge helpdesk-mode';
  } else {
    el.textContent = 'Customer';
    el.className = 'mode-badge customer-mode';
  }
}

function renderQuickQuestions() {
  const questions = QUICK_QUESTIONS[currentRole] || [];
  const container = document.getElementById('quickQuestions');
  container.innerHTML = questions.map(q => `
    <div class="quick-q" onclick="insertAndSend('${q.replace(/'/g, "\\'")}')">
      ${q}
    </div>
  `).join('');
}

function insertText(text) {
  document.getElementById('messageInput').value = text;
  document.getElementById('messageInput').focus();
}

function insertAndSend(text) {
  document.getElementById('messageInput').value = text;
  sendMessage();
}

function clearConversation() {
  sessionId = 'session-' + Date.now();
  updateSessionDisplay();
  const messages = document.getElementById('chatMessages');
  messages.innerHTML = `
    <div class="message assistant-message">
      <div class="message-avatar"><i class="fas fa-robot"></i></div>
      <div class="message-bubble">
        <div class="message-content">
          <p>New conversation started. How can I assist you?</p>
        </div>
        <div class="message-time">Wells Fargo AI Advisor</div>
      </div>
    </div>`;
}

async function checkHealth() {
  const indicator = document.getElementById('statusIndicator');
  const statusText = document.getElementById('statusText');
  try {
    const res = await fetch(API_BASE + '/api/advisor/health');
    if (res.ok) {
      const data = await res.json();
      indicator.className = 'status-indicator status-up';
      statusText.textContent = `Online (${data.toolCount} tools)`;
    } else {
      throw new Error('Not OK');
    }
  } catch(e) {
    indicator.className = 'status-indicator status-down';
    statusText.textContent = 'Offline';
  }
}

function handleKeyDown(event) {
  if (event.key === 'Enter' && !event.shiftKey) {
    event.preventDefault();
    sendMessage();
  }
}

function autoResize(textarea) {
  textarea.style.height = 'auto';
  textarea.style.height = Math.min(textarea.scrollHeight, 120) + 'px';
}

function addMessage(role, content) {
  const messages = document.getElementById('chatMessages');
  const time = new Date().toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit' });
  const isUser = role === 'user';
  const div = document.createElement('div');
  div.className = `message ${isUser ? 'user-message' : 'assistant-message'}`;
  div.innerHTML = `
    <div class="message-avatar">
      ${isUser ? '<i class="fas fa-user"></i>' : '<i class="fas fa-robot"></i>'}
    </div>
    <div class="message-bubble">
      <div class="message-content">${formatMessage(content)}</div>
      <div class="message-time">${isUser ? (currentRole === 'helpdesk' ? 'Helpdesk' : 'You') : 'Wells Fargo AI'} · ${time}</div>
    </div>`;
  messages.appendChild(div);
  messages.scrollTop = messages.scrollHeight;
  return div;
}

function formatMessage(text) {
  if (!text) return '';
  return text
    .replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;')
    .replace(/\*\*(.*?)\*\*/g, '<strong>$1</strong>')
    .replace(/\*(.*?)\*/g, '<em>$1</em>')
    .replace(/`(.*?)`/g, '<code>$1</code>')
    .replace(/\n/g, '<br/>');
}

function showTyping() {
  const messages = document.getElementById('chatMessages');
  const div = document.createElement('div');
  div.className = 'message assistant-message typing-indicator';
  div.id = 'typingIndicator';
  div.innerHTML = `
    <div class="message-avatar"><i class="fas fa-robot"></i></div>
    <div class="message-bubble">
      <div class="message-content">
        <div class="typing-dots"><span></span><span></span><span></span></div>
      </div>
    </div>`;
  messages.appendChild(div);
  messages.scrollTop = messages.scrollHeight;
}

function hideTyping() {
  const el = document.getElementById('typingIndicator');
  if (el) el.remove();
}

async function sendMessage() {
  if (isWaiting) return;
  const input = document.getElementById('messageInput');
  const message = input.value.trim();
  if (!message) return;

  input.value = '';
  input.style.height = 'auto';
  isWaiting = true;
  document.getElementById('sendBtn').disabled = true;

  addMessage('user', message);
  showTyping();

  const contextMessage = currentRole === 'helpdesk'
    ? `[HELPDESK MODE] ${message}`
    : message;

  try {
    const res = await fetch(API_BASE + '/api/advisor/chat', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ sessionId, message: contextMessage })
    });
    if (!res.ok) throw new Error('Server error: ' + res.status);
    const data = await res.json();
    hideTyping();
    addMessage('assistant', data.response || 'Sorry, I could not process your request.');
  } catch(e) {
    hideTyping();
    addMessage('assistant', 'Unable to connect to the AI Advisor. Please ensure the bank-ai-advisor service is running on port 8095.');
  } finally {
    isWaiting = false;
    document.getElementById('sendBtn').disabled = false;
    input.focus();
  }
}

window.addEventListener('DOMContentLoaded', init);
