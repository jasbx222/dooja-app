(function () {
    var toggle = document.getElementById("nav-toggle");
    var sidebar = document.getElementById("sidebar");

    function closeDrawer() {
        if (toggle) toggle.checked = false;
    }

    if (sidebar) sidebar.querySelectorAll("a").forEach(function (link) {
        link.addEventListener("click", closeDrawer);
    });
    window.addEventListener("resize", function () {
        if (window.innerWidth >= 960) closeDrawer();
    });
    document.addEventListener("keydown", function (event) {
        if (event.key === "Escape") closeDrawer();
    });

    document.addEventListener("click", function (event) {
        document.querySelectorAll("details.menu[open]").forEach(function (menu) {
            if (!menu.contains(event.target)) menu.removeAttribute("open");
        });
    });

    var dialog = document.getElementById("confirm");
    var dialogText = document.getElementById("confirm-text");
    var dialogOk = document.getElementById("confirm-ok");

    function ask(message, okLabel) {
        if (!dialog || typeof dialog.showModal !== "function") return Promise.resolve(window.confirm(message));
        dialogText.textContent = message;
        dialogOk.textContent = okLabel || "تأكيد";
        dialog.showModal();
        return new Promise(function (resolve) {
            dialog.addEventListener("close", function () { resolve(dialog.returnValue === "ok"); }, { once: true });
        });
    }

    document.addEventListener("submit", function (event) {
        var form = event.target;
        if (!(form instanceof HTMLFormElement) || form.closest("dialog")) return;
        var message = form.getAttribute("data-confirm");
        if (message && form.dataset.confirmed !== "yes") {
            event.preventDefault();
            ask(message, form.getAttribute("data-confirm-ok")).then(function (ok) {
                if (!ok) return;
                form.dataset.confirmed = "yes";
                form.requestSubmit();
            });
            return;
        }
        var button = event.submitter;
        if (button) button.setAttribute("aria-busy", "true");
        document.documentElement.classList.add("is-loading");
    });

    document.addEventListener("click", function (event) {
        var link = event.target.closest("a");
        if (!link || link.target === "_blank" || link.origin !== location.origin || link.hasAttribute("download")) return;
        if (event.metaKey || event.ctrlKey || event.shiftKey || event.altKey) return;
        document.documentElement.classList.add("is-loading");
    });
})();
