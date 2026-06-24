const Router = {
  currentRoute: 'dashboard',
  navigate(route) {
    this.currentRoute = route;
    document.querySelectorAll('.wf-nav-link').forEach(l => {
      l.classList.toggle('active', l.dataset.route === route);
    });
    this.render();
  },
  render() {
    const pages = { dashboard: DashboardPage, transactions: TransactionsPage, categorize: CategorizePage, disputes: DisputesPage };
    const page = pages[this.currentRoute];
    if (page) page.render();
  }
};
