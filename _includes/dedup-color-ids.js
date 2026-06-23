document.addEventListener("DOMContentLoaded", function () {
  const schemeLinks = document.querySelectorAll('link.quarto-color-scheme');

  schemeLinks.forEach((el) => {
    const mode = el.getAttribute("data-mode"); // "light" or "dark"
    if (mode) {
      el.id = `quarto-color-scheme-${mode}`; // e.g. "quarto-color-scheme-light"
    }
  });
});