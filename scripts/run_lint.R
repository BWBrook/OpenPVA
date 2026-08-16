#!/usr/bin/env Rscript

lints <- lintr::lint_package()
print(lints)
if (length(lints) > 0L) {
  quit(status = 1L)
}
