(function () {
  var root = document.documentElement;
  var storedTheme = localStorage.getItem('s2-theme');
  if (storedTheme === 'dark' || storedTheme === 'light') {
    root.setAttribute('data-theme', storedTheme);
  }

  function updateToggleLabel() {
    var theme = root.getAttribute('data-theme') === 'dark' ? 'dark' : 'light';
    var next = theme === 'dark' ? 'light' : 'dark';
    var toggles = document.querySelectorAll('[data-theme-toggle]');
    toggles.forEach(function (btn) {
      btn.setAttribute('aria-label', 'Switch to ' + next + ' mode');
      btn.setAttribute('title', 'Switch to ' + next + ' mode');
      btn.textContent = theme === 'dark' ? 'Light' : 'Dark';
    });
  }

  function bindThemeToggle() {
    var toggles = document.querySelectorAll('[data-theme-toggle]');
    toggles.forEach(function (btn) {
      btn.addEventListener('click', function () {
        var current = root.getAttribute('data-theme') === 'dark' ? 'dark' : 'light';
        var next = current === 'dark' ? 'light' : 'dark';
        root.setAttribute('data-theme', next);
        localStorage.setItem('s2-theme', next);
        updateToggleLabel();
      });
    });
    updateToggleLabel();
  }

  function bindReveal() {
    var targets = document.querySelectorAll('.section, .card, .hero, .section-head');
    targets.forEach(function (el) {
      el.classList.add('reveal');
    });

    if (!('IntersectionObserver' in window)) {
      targets.forEach(function (el) { el.classList.add('is-visible'); });
      return;
    }

    var obs = new IntersectionObserver(function (entries, observer) {
      entries.forEach(function (entry) {
        if (entry.isIntersecting) {
          entry.target.classList.add('is-visible');
          observer.unobserve(entry.target);
        }
      });
    }, { threshold: 0.14 });

    targets.forEach(function (el) { obs.observe(el); });
  }

  function bindGalleryModal() {
    var grid = document.querySelector('[data-gallery-grid]');
    var modal = document.querySelector('[data-gallery-modal]');
    var image = document.querySelector('[data-gallery-modal-image]');
    var caption = document.querySelector('[data-gallery-modal-caption]');
    if (!grid || !modal || !image || !caption) return;

    var tiles = Array.prototype.slice.call(grid.querySelectorAll('.gallery-tile'));
    var prev = modal.querySelector('.gallery-modal-nav.prev');
    var next = modal.querySelector('.gallery-modal-nav.next');
    var close = modal.querySelector('.gallery-modal-close');
    var activeIndex = 0;

    function render(index) {
      var tile = tiles[index];
      if (!tile) return;
      image.src = tile.getAttribute('data-src') || '';
      image.alt = tile.querySelector('img') ? tile.querySelector('img').alt : '';
      caption.textContent = tile.getAttribute('data-caption') || image.alt || 'Project image';
      activeIndex = index;
    }

    function open(index) {
      render(index);
      modal.classList.add('is-open');
      modal.setAttribute('aria-hidden', 'false');
      document.body.classList.add('modal-open');
    }

    function closeModal() {
      modal.classList.remove('is-open');
      modal.setAttribute('aria-hidden', 'true');
      document.body.classList.remove('modal-open');
    }

    function step(direction) {
      var nextIndex = (activeIndex + direction + tiles.length) % tiles.length;
      render(nextIndex);
    }

    tiles.forEach(function (tile, index) {
      tile.addEventListener('click', function () { open(index); });
    });

    if (prev) prev.addEventListener('click', function () { step(-1); });
    if (next) next.addEventListener('click', function () { step(1); });
    if (close) close.addEventListener('click', closeModal);

    modal.addEventListener('click', function (event) {
      if (event.target === modal) closeModal();
    });

    document.addEventListener('keydown', function (event) {
      if (!modal.classList.contains('is-open')) return;
      if (event.key === 'Escape') closeModal();
      if (event.key === 'ArrowLeft') step(-1);
      if (event.key === 'ArrowRight') step(1);
    });
  }

  function bindHeroSlideshow() {
    var slider = document.querySelector('[data-hero-slider]');
    if (!slider) return;

    var slidesContainer = slider.querySelector('.hero-slides');
    var dotsContainer = slider.querySelector('.hero-dots');
    if (!slidesContainer || !dotsContainer) return;

    var slides = Array.prototype.slice.call(slidesContainer.querySelectorAll('.hero-slide'));
    if (!slides.length || slides.length < 2) return;

    function shuffle(items) {
      for (var i = items.length - 1; i > 0; i -= 1) {
        var j = Math.floor(Math.random() * (i + 1));
        var tmp = items[i];
        items[i] = items[j];
        items[j] = tmp;
      }
      return items;
    }

    shuffle(slides);
    slides.forEach(function (slide, i) {
      slide.classList.toggle('is-active', i === 0);
      slidesContainer.appendChild(slide);
    });

    dotsContainer.innerHTML = '';
    var dots = slides.map(function (_, i) {
      var dot = document.createElement('button');
      dot.className = 'hero-dot' + (i === 0 ? ' is-active' : '');
      dot.type = 'button';
      dot.setAttribute('aria-label', 'Show slide ' + (i + 1));
      dot.setAttribute('data-hero-dot', String(i));
      dot.setAttribute('aria-pressed', i === 0 ? 'true' : 'false');
      dotsContainer.appendChild(dot);
      return dot;
    });

    var activeIndex = 0;
    var timer = null;
    var intervalMs = 2000;
    var prefersReducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;

    function render(index) {
      slides.forEach(function (slide, i) {
        slide.classList.toggle('is-active', i === index);
      });
      dots.forEach(function (dot, i) {
        dot.classList.toggle('is-active', i === index);
        dot.setAttribute('aria-pressed', i === index ? 'true' : 'false');
      });
      activeIndex = index;
    }

    function step(direction) {
      var next = (activeIndex + direction + slides.length) % slides.length;
      render(next);
    }

    function stop() {
      if (!timer) return;
      window.clearInterval(timer);
      timer = null;
    }

    function start() {
      if (prefersReducedMotion) return;
      stop();
      timer = window.setInterval(function () { step(1); }, intervalMs);
    }

    dots.forEach(function (dot, i) {
      dot.addEventListener('click', function () {
        render(i);
        start();
      });
    });

    slider.addEventListener('mouseenter', stop);
    slider.addEventListener('mouseleave', start);
    slider.addEventListener('focusin', stop);
    slider.addEventListener('focusout', start);
    document.addEventListener('visibilitychange', function () {
      if (document.hidden) {
        stop();
        return;
      }
      start();
    });

    render(0);
    start();
  }

  document.addEventListener('DOMContentLoaded', function () {
    bindThemeToggle();
    bindReveal();
    bindGalleryModal();
    bindHeroSlideshow();
  });
})();
