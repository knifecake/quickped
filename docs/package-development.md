# Package and dependency setup

This change packages the application from upstream commit
`fc86366e8efdf1b236d5137fe079a77884c91b50` (app version 4.5.0). The application
files are unchanged under `inst/app/`; the root `app.R` is a source launcher.
Package installation bundles its helpers, built-in pedigrees, styles and icons.
Loading the package does not construct the UI or start a server.

## Dependency ownership

- `DESCRIPTION` declares the app's direct runtime dependencies.
- `NAMESPACE` exports the launcher/app constructor and records namespace imports.
- `renv.lock` fixes the resolved runtime dependency graph, including transitive
  dependencies. `renv/settings.json` selects explicit DESCRIPTION-based snapshots.
- `.Rprofile` and `renv/activate.R` activate the project library and bootstrap the
  pinned renv version. Generated libraries and caches are ignored by Git.

The initial lockfile was generated from an installed CRAN environment and
validated with R 4.6.1 on Ubuntu 24.04, using the Rocker image
`rocker/r2u:24.04@sha256:dc2a96c3b368969635c25c177c64514ba8e37cf2259dd3584de7c33520191d92`.
It records 64 packages, including pedtools 2.11.0, ribd 1.7.2, verbalisr 0.7.2
and Shiny 1.14.0. These are a reviewable starting point, not a claim to reproduce
Magnus' existing shinyapps.io environment. This lockfile does not select GitHub
commits for him.

## System prerequisites

When restoring from source on Ubuntu, install the R development toolchain and
`libuv1-dev` (required by the locked fs version). The pinned validation image
already has the R/compiler toolchain; the CI workflow adds `curl` and
`libuv1-dev`. These are system dependencies and do not belong in `renv.lock`.

## Restore, run and check

Use the R version recorded in `renv.lock` for a matching development environment.
From a checkout, start R normally so `.Rprofile` activates renv, then:

```r
renv::restore(prompt = FALSE)
shiny::runApp(".")
```

The root source launcher works without installing QuickPed itself. To exercise
the installed package instead:

```r
install.packages(".", repos = NULL, type = "source")
quickped::runQuickPed(host = "127.0.0.1", port = 3838)
```

For standard package checks, build a tarball and check it with the restored
project library on `R_LIBS_USER`:

```sh
export R_LIBS_USER="$(Rscript -e 'cat(.libPaths()[1])')"
R CMD build . --no-build-vignettes
R CMD check --no-manual quickped_4.5.0.tar.gz
```

`tests/package.R` checks the installed app constructor, bundled assets and data,
and an HTTP UI response from outside the source checkout. Passing these checks
is a packaging check, not a guarantee that the app is ready for CRAN submission.

The GitHub Actions workflow restores the lockfile in a pinned R container,
builds the package and requires `R CMD check` to finish with `Status: OK`.

## Change dependencies deliberately

Add direct runtime dependencies to `Imports` in `DESCRIPTION`, install/test the
new environment, then call `renv::snapshot(prompt = FALSE)`. Commit both files.
The package dependencies' own metadata supplies the transitive requirements.

For an author-selected GitHub commit, install the full commit SHA and record its
source in `Remotes` as well as its package name in `Imports`:

```r
renv::install("magnusdv/pedtools@<approved-full-commit-SHA>")
renv::snapshot(prompt = FALSE)
```

Review the resulting package record's `RemoteSha`. The lockfile's `Hash` is a
package-content/cache hash, not the GitHub commit SHA. Avoid resolving a moving
branch during each image build; restore the committed lockfile instead.

## Deployment and package boundaries

Source deployments retain `shiny::runApp(".")`; the launcher loads the bundled
app under `inst/app`. Package deployments use `quickped::runQuickPed()` after
installing the package. Both paths use the same app code. RStudio's Run App
button remains supported by the root `app.R`.

The runtime app, Google Analytics and scientific calculations have not been
rewritten. Files previously under root `R/`, `data/` and `www/` are now under
`inst/app/`; external links to those source paths need updating when merging.
The README icon link is updated here.

The lockfile, renv activation files and deployment metadata are excluded from
built package tarballs with `.Rbuildignore`. The package's standard `GPL-3`
license declaration remains; the repository retains the upstream full license.
System libraries and the R executable are outside renv's package lock and must
also be supplied by the hosting/build environment.

## Validation performed for this branch

- `R CMD build` and `R CMD check --no-manual --no-build-vignettes`: Status OK.
- Restore of all 64 locked packages into an empty library, including a restore
  from downloaded source packages with an initially empty cache.
- Installed package launched from `/tmp`, outside the source checkout; its HTTP
  page and CSS asset returned 200, and the browser rendered the initial pedigree
  with a connected Shiny session.
- PED, PNG and XLSX export endpoints returned valid files; the R-code dialog
  reproduced the current pedigree.
- The root source launcher also served its UI/assets and rendered a pedigree.
- Every relocated application file is byte-for-byte identical to upstream.
