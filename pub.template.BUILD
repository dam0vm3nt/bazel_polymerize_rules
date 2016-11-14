#Build "@{name}"
load('@polymerize//:polymerize.bzl', 'polymer_library')

polymer_library(
  name = 'library',
  @{deps}
  dart_sources = glob(['lib/**/*.dart']),
  html_templates = glob(['lib/**/*.html']),
  visibility = ["//visibility:public"])
