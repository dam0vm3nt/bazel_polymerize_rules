def _impl(ctx):
  # args
  # args = [ctx.outputs.js.path] + [f.path for f in ctx.files.srcs]

  sum = ctx.new_file(ctx.outputs.js.basename+".sum")

  ctx.action(
    inputs=ctx.files.dart_sources +  ctx.files.html_templates,
    outputs= [ctx.outputs.js,sum],
    arguments= ['-o']+[ctx.outputs.js.path]+['-os']+[sum.path]+['-i']+ [f.path for f in ctx.files.dart_sources]+['-h']+ [f.path for f in ctx.files.html_templates]+['-s']+[f.summary.path for f in ctx.attr.deps],
    progress_message="Polymerizing %s" % ctx.outputs.js.short_path,
    executable= ctx.executable._exe)

  return struct(
    summary= sum #ctx.outputs.summary
    )

polymer_library = rule(
  implementation=_impl,
  attrs={
      "dart_sources": attr.label_list(allow_files=True),
      "html_templates": attr.label_list(allow_files=True),
      "deps": attr.label_list(allow_files=False,providers=["summary"]),
      '_exe' : attr.label(cfg='host',default = Label('//:polymerize'),executable=True)
  },
  outputs = {
    "js" : "%{name}.js",
    #"summary" : "%{name}.sum"
  })


##
## Repo for cippo

def _dartLibImp(repository_ctx):
   print ("Creating repo for %s" % repository_ctx.name)

   dep_string = ",".join([ ("'%s'" % x) for x in repository_ctx.attr.deps ])

   if (dep_string) :
    dep_string = "deps = [%s]," % dep_string

   print ("DEPS : %s" % dep_string)


   repository_ctx.template(
    "BUILD",repository_ctx.attr._templ,
    substitutions = {
      "@{name}" : repository_ctx.name,
      "@{deps}" : dep_string,
     }
     )

dart_library = repository_rule(
    implementation = _dartLibImp,
    attrs = {
      'deps' : attr.label_list(allow_files=False,providers=["summary"]),
      'packageName' : attr.string(),
      '_templ' : attr.label(default=Label("//:pub.template.BUILD"))
    }
  )
