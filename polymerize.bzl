def _impl(ctx):
  # args
  # args = [ctx.outputs.js.path] + [f.path for f in ctx.files.srcs]

  sum = ctx.new_file(ctx.outputs.js.basename+".sum")
  #sum = ctx.outputs.summary
  #  -p pippo -v 1.0

  args = ['-o','/tmp/out','bazel'];
  for f in ctx.files.dart_sources :
    args += ['-s',f.path]

  inputs = ctx.files.dart_sources +  ctx.files.html_templates

  if (ctx.attr.deps) :
    for f in ctx.attr.deps :
      #print("USING SUM : %s" % (f.summary))
      args += ['-m',f.summary.path]
      inputs += [f.summary]

  args += ['-x',sum.path]
  args += ['-o',ctx.outputs.js.path]
  args += ['-p',ctx.attr.package_name]
  args += ['-v',ctx.attr.version]

  ctx.action(
    inputs=inputs,
    outputs= [ctx.outputs.js,sum],
    arguments= args, # ['-o']+[ctx.outputs.js.path]+['-os']+[sum.path]+['-i']+ [f.path for f in ctx.files.dart_sources]+['-h']+ [f.path for f in ctx.files.html_templates]+['-s']+[f.summary.path for f in ctx.attr.deps],
    progress_message="Polymerizing %s" % ctx.outputs.js.short_path,
    executable= ctx.executable._exe)

  return struct(
    summary= sum #ctx.outputs.summary
    )

polymer_library = rule(
  implementation=_impl,
  attrs={
      "dart_sources": attr.label_list(allow_files=True),
      'package_name' : attr.string(),
      'version' : attr.string(),
      "html_templates": attr.label_list(allow_files=True),
      "deps": attr.label_list(allow_files=False,providers=["summary"]),
      '_exe' : attr.label(cfg='host',default = Label('//:polymerize'),executable=True)
  },
  outputs = {
    "js" : "%{name}.js",
  #  "summary" : "%{name}.sum"
  })


##
## Repo for cippos

def _dartLibImp(repository_ctx):
   #print ("Creating repo for %s" % repository_ctx.name)

   if (repository_ctx.attr.deps) :
     dep_string = ",".join([ ("'%s'" % x) for x in repository_ctx.attr.deps ])
     dep_string = "deps = [%s]," % dep_string
     # print ("DEPS : %s" % dep_string)
   else :
     dep_string = ""

   #repository_ctx.execute(['dart','polymerize','download_package')
   pkg_src = "/home/vittorio/.pub-cache/hosted/http%%58%%47%%47pub.drafintech.it%%585001/%s-%s/lib" % (repository_ctx.attr.package_name , repository_ctx.attr.version)

   #print("SRC: %s" % pkg_src)

   repository_ctx.symlink(pkg_src,"lib")

   repository_ctx.template(
    "BUILD",repository_ctx.attr._templ,
    substitutions = {
      "@{name}" : repository_ctx.name,
      "@{deps}" : dep_string,
      "@{package_name}" : repository_ctx.attr.package_name,
      "@{version}" : repository_ctx.attr.version
     }
     )

dart_library = repository_rule(
    implementation = _dartLibImp,
    attrs = {
      'deps' : attr.string_list(),
      'package_name' : attr.string(),
      'version' : attr.string(),
      '_templ' : attr.label(default=Label("//:pub.template.BUILD")),
      '_pub_download' : attr.label(cfg='host',default = Label('//:pub_download'),executable=True)
    }
  )
