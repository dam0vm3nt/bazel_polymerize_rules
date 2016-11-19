#Build "@{name}"
load('@polymerize//:polymerize.bzl', 'polymer_library')

package(default_visibility=['//visibility:public'])

filegroup(name = "@{package_name}", srcs=glob(["lib/**/*.dart"]))

polymer_library(
  name = 'library',
  @{deps}
  dart_sources = glob(['lib/**/*.dart']),
  html_templates = glob(['lib/**/*.html']),
  package_name = '@{package_name}', #Cippa Lippa
  version = '@{version}')
