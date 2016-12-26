# BAZEL RULES FOR POLYMERIZE

This package contains bazel rules for a [polymerize](https://pub.dartlang.org/packages/polymerize) dart project.

# Usage

##  WORKSPACE

In your `WORKSPACE` file add the following:

    # DECLARE THIS GIT REPO
    git_repository(
     name='polymerize',
     tag='v_0_0_5',
     remote='https://github.com/dam0vm3nt/bazel_polymerize_rules')

    # LOAD the macro and the rules for the workspace
    load('@polymerize//:polymerize.bzl','dart_library','init_polymerize')

    # Download and init the polymerize tool
    init_polymerize()

Then for any library you want to import from pub add a `dart_library` repository, for example if you want to use  package `js` version `0.6.1` :

    dart_library(
     name='js',
     package_name='js',
     version='0.6.1')

This will define the target `@js//:js` (and more generally `@<name>//:<package_name>`) that can be used as dependency in your `BUILD` file.

## BUILD

In your `BUILD` file you can use `polymer_library` to compile a dart polymer module, for example :

    load('@polymerize//:polymerize.bzl','polymer_library')

    package(default_visibility=['//visibility:public'])

    polymer_library(
      name='todo_ddc',
      deps=[
        '@polymer_element//:polymer_element',
        '@js//:js',
        '//todo_common',
        '//todo_main',
        '//todo_renderer',
      ],
      package_name = 'todo_ddc',
      version = '1.0',
      export_sdk = 1,
      base_path = '//:lib',
      dart_sources= glob(['lib/**/*.dart']),
      html_templates= glob(['lib/**','web/**'],exclude=['**/*.dart']))

All the attributes should be straightforward, except :

 - base_path : should point to the base source folder (library path are relatives to that folder)
 - dart_sources : every source you want to compile in this module (normally every '*.dart' file)
 - html_templates: html templates and everything you want to be copied in the output (ex. css files images etc.)
 - export_sdk : 1= if you want to also generate the `dart_sdk.js` and `imd.js` files. Ususally only needed in the main module (the one with the `index.html`)


