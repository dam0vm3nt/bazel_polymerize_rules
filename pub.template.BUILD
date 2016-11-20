#Build "@{name}"
load('@polymerize//:polymerize.bzl', 'polymer_library')

package(default_visibility=['//visibility:public'])

#filegroup(name = "@{package_name}", srcs=glob(["lib/**/*.dart"]))

polymer_library(
  name = '@{package_name}',
  @{deps}
  dart_sources = glob(['lib/**/*.dart']),
  base_path = "//:lib",
  external = 1,
  html_templates = glob(['lib/**'],exclude=['lib/**/*.dart']),
  package_name = '@{package_name}', #Cippa Lippa
  version = '@{version}')
