
let MobileMenu = {
  mounted() {
    let menuButton = this.el.querySelector('[data-menu-button]');
    let menu = this.el.querySelector('[data-menu]');

    if (menuButton && menu) {
      menuButton.addEventListener('click', (event) => {
        event.stopPropagation();
        menu.classList.toggle('hidden');
      });

      window.addEventListener('click', (event) => {
        if (!menu.contains(event.target)) {
          menu.classList.add('hidden');
        }
      });
    }
  }
};

export default MobileMenu;
