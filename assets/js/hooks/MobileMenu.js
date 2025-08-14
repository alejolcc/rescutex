
let MobileMenu = {
  mounted() {
    let menuButton = this.el.querySelector('[data-menu-button]');
    let menu = this.el.querySelector('[data-menu]');

    if (menuButton && menu) {
      menuButton.addEventListener('click', () => {
        menu.classList.toggle('hidden');
      });
    }
  }
};

export default MobileMenu;
