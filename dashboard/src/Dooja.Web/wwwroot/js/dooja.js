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
        var button = event.submitter;
        var message = (button && button.getAttribute("data-confirm")) || form.getAttribute("data-confirm");
        if (message && form.dataset.confirmed !== "yes") {
            event.preventDefault();
            var okLabel = (button && button.getAttribute("data-confirm-ok")) || form.getAttribute("data-confirm-ok");
            ask(message, okLabel).then(function (ok) {
                if (!ok) return;
                form.dataset.confirmed = "yes";
                form.requestSubmit(button || undefined);
                delete form.dataset.confirmed;
            });
            return;
        }
        if (button) button.setAttribute("aria-busy", "true");
        document.documentElement.classList.add("is-loading");
    });

    // Product editor: show the discount the customer will see.
    var price = document.querySelector("[data-price]");
    var compare = document.querySelector("[data-compare]");
    var discount = document.querySelector("[data-discount]");
    function showDiscount() {
        var p = Number(price.value), c = Number(compare.value);
        var on = compare.value !== "" && price.value !== "" && c > p && p >= 0;
        discount.textContent = on ? "خصم " + Math.round((c - p) * 100 / c) + "% — يوفّر الزبون " + (c - p).toLocaleString("en-US") + " د.ع" : "";
        discount.classList.toggle("show", on);
    }
    if (price && compare && discount) {
        price.addEventListener("input", showDiscount);
        compare.addEventListener("input", showDiscount);
        showDiscount();
    }

    // Upload boxes: name the picked files.
    document.querySelectorAll(".dropzone input[type=file]").forEach(function (input) {
        var label = input.closest(".dropzone").querySelector("[data-picked]");
        if (!label) return;
        input.addEventListener("change", function () {
            var n = input.files.length;
            if (!n) return;
            var big = Array.prototype.some.call(input.files, function (f) { return f.size > 4 * 1024 * 1024; });
            if (big) {
                label.textContent = "صورة أكبر من 4 ميغابايت. صغّرها واختر مرة ثانية";
                label.classList.remove("picked");
                input.value = "";
                return;
            }
            label.textContent = (n === 1 ? input.files[0].name : "تم اختيار " + n + " صور") + " — جارٍ الرفع…";
            label.classList.add("picked");
            // Upload right away: picking a photo and then pressing the product's
            // Save button used to drop the photo silently.
            var form = input.form;
            if (form && form.classList.contains("upload-row")) form.requestSubmit();
        });
    });

    document.addEventListener("click", function (event) {
        if (event.target.closest("[data-print]")) { window.print(); return; }
        var link = event.target.closest("a");
        if (!link || link.target === "_blank" || link.origin !== location.origin || link.hasAttribute("download")) return;
        if (event.metaKey || event.ctrlKey || event.shiftKey || event.altKey) return;
        document.documentElement.classList.add("is-loading");
    });
})();
