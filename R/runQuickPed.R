# The application stays in its own Shiny environment, including its R/ helpers.
# No UI, data loading or server startup is performed when loading the package.
quickpedApp <- function() {
  app_dir <- system.file("app", package = "quickped", mustWork = TRUE)
  shiny::shinyAppDir(app_dir)
}

runQuickPed <- function(...) {
  shiny::runApp(quickpedApp(), ...)
}
