(function() {
  const loginPage = document.getElementById('loginPage');
  const mainApp   = document.getElementById('mainApp');
  const loginBtn  = document.getElementById('loginBtn');
  const logoutBtn = document.getElementById('logoutBtn');
  const loginError= document.getElementById('loginError');

  function isLoggedIn() { return !!localStorage.getItem('wf_token'); }

  function showApp() {
    loginPage.classList.add('d-none');
    mainApp.classList.remove('d-none');
    document.getElementById('displayName').textContent = localStorage.getItem('wf_display_name') || 'User';
    Router.navigate('dashboard');
  }

  function showLogin() {
    loginPage.classList.remove('d-none');
    mainApp.classList.add('d-none');
  }

  loginBtn.addEventListener('click', async () => {
    const username = document.getElementById('username').value.trim();
    const password = document.getElementById('password').value;
    loginError.classList.add('d-none');
    loginBtn.disabled = true; loginBtn.textContent = 'Signing on...';
    try {
      const resp = await AuthAPI.login(username, password);
      localStorage.setItem('wf_token', resp.token);
      localStorage.setItem('wf_customer_id', resp.customerId);
      localStorage.setItem('wf_username', resp.username);
      localStorage.setItem('wf_display_name', resp.fullName);
      localStorage.setItem('wf_role', resp.role);
      showApp();
    } catch(e) {
      loginError.textContent = 'Invalid username or password. Please try again.';
      loginError.classList.remove('d-none');
    } finally {
      loginBtn.disabled = false; loginBtn.textContent = 'Sign On';
    }
  });

  document.getElementById('password').addEventListener('keypress', e => {
    if (e.key === 'Enter') loginBtn.click();
  });

  logoutBtn.addEventListener('click', () => {
    localStorage.clear();
    showLogin();
  });

  document.querySelectorAll('.wf-nav-link').forEach(link => {
    link.addEventListener('click', () => Router.navigate(link.dataset.route));
  });

  if (isLoggedIn()) showApp(); else showLogin();
})();
