document.addEventListener("DOMContentLoaded", () => {
  const quickSearchForm = document.getElementById("quickSearchForm");
  if (!quickSearchForm) return;

  quickSearchForm.addEventListener("submit", (e) => {
    // Later we can add front-end validation here.
    // For now we let it submit normally to the servlet.
    console.log("Quick search submitted");
  });
});