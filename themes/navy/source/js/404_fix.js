(function() {
  if ($(".page-not-found").length == 1) {
    var oldpaths = {
      "/advanced.html": "/docs",
      "/callbacks.html": "/docs/hooks.html",
      "/crud.html": "/docs",
      "/development.html": "/docs/write_plugins.html",
      "/associations.html": "/docs",
      "/changelog.html": "/docs/changelog.html",
      "/database.html": "/docs/connecting_to_the_database.html",
      "/dialects.html": "/docs/dialects.html",
      "/models.html": "/docs/models.html"
    }

    newpath = oldpaths[location.pathname]
    if (newpath !== undefined) {
      location.pathname = newpath
    }
  }
}());
