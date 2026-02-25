(function () {
  function toSafeText(value) {
    return typeof value === "string" ? value.trim() : "";
  }

  function renderOpenings(jobs) {
    var openingsEl = document.getElementById("careers-openings");
    var emptyEl = document.getElementById("careers-empty");
    if (!openingsEl || !emptyEl) return;

    openingsEl.innerHTML = "";

    if (!Array.isArray(jobs) || jobs.length === 0) {
      emptyEl.hidden = false;
      return;
    }

    emptyEl.hidden = true;

    jobs.forEach(function (job) {
      var card = document.createElement("article");
      card.className = "card career-opening";

      var title = document.createElement("h4");
      title.textContent = toSafeText(job.title) || "Open Position";
      card.appendChild(title);

      var meta = document.createElement("p");
      meta.className = "career-meta";
      var dept = toSafeText(job.department) || "General";
      var location = toSafeText(job.location) || "California";
      var employmentType = toSafeText(job.employment_type) || "Full-Time";
      meta.textContent = dept + " | " + location + " | " + employmentType;
      card.appendChild(meta);

      var summary = document.createElement("p");
      summary.className = "career-summary";
      summary.textContent = toSafeText(job.summary) || "See job details below.";
      card.appendChild(summary);

      var description = document.createElement("p");
      description.className = "career-description";
      description.textContent = toSafeText(job.description);
      card.appendChild(description);

      var actions = document.createElement("div");
      actions.className = "career-actions";

      if (toSafeText(job.pdf_url)) {
        var pdfLink = document.createElement("a");
        pdfLink.className = "btn btn-muted";
        pdfLink.href = job.pdf_url;
        pdfLink.target = "_blank";
        pdfLink.rel = "noopener";
        pdfLink.textContent = "View PDF Description";
        actions.appendChild(pdfLink);
      }

      var applyBtn = document.createElement("button");
      applyBtn.type = "button";
      applyBtn.className = "btn";
      applyBtn.textContent = "Apply for This Role";
      applyBtn.addEventListener("click", function () {
        var jobTitle = document.getElementById("job_title");
        var jobId = document.getElementById("job_id");
        if (jobTitle) jobTitle.value = toSafeText(job.title);
        if (jobId) jobId.value = toSafeText(job.id);
        var form = document.getElementById("careers-apply-form");
        if (form) form.scrollIntoView({ behavior: "smooth", block: "start" });
      });
      actions.appendChild(applyBtn);
      card.appendChild(actions);

      openingsEl.appendChild(card);
    });
  }

  function renderLoadingError() {
    var openingsEl = document.getElementById("careers-openings");
    var emptyEl = document.getElementById("careers-empty");
    if (!openingsEl || !emptyEl) return;
    openingsEl.innerHTML = "";
    emptyEl.hidden = false;
  }

  function loadOpenings() {
    var openingsEl = document.getElementById("careers-openings");
    if (!openingsEl) return;

    fetch("forms/careers-jobs.php", { cache: "no-store" })
      .then(function (response) {
        if (!response.ok) throw new Error("Failed to load openings.");
        return response.json();
      })
      .then(function (payload) {
        renderOpenings(payload.jobs || []);
      })
      .catch(function () {
        renderLoadingError();
      });
  }

  function bindApplyForm() {
    var form = document.getElementById("careers-apply-form");
    var feedback = document.getElementById("careers-apply-feedback");
    if (!form || !feedback) return;

    form.addEventListener("submit", function (event) {
      event.preventDefault();
      feedback.textContent = "Submitting resume...";

      var body = new FormData(form);
      fetch(form.getAttribute("action"), {
        method: "POST",
        body: body
      })
        .then(function (response) {
          return response.json().then(function (payload) {
            if (!response.ok) {
              throw new Error(payload.message || "Unable to submit resume.");
            }
            return payload;
          });
        })
        .then(function (payload) {
          feedback.textContent = payload.message || "Resume submitted successfully.";
          form.reset();
        })
        .catch(function (error) {
          feedback.textContent = error.message || "Unable to submit resume right now.";
        });
    });

    var params = new URLSearchParams(window.location.search);
    var paramTitle = toSafeText(params.get("job"));
    if (paramTitle) {
      var titleInput = document.getElementById("job_title");
      if (titleInput) titleInput.value = paramTitle;
    }
  }

  document.addEventListener("DOMContentLoaded", function () {
    loadOpenings();
    bindApplyForm();
  });
})();
