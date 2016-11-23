def _impl(ctx):
  # args
  # args = [ctx.outputs.js.path] + [f.path for f in ctx.files.srcs]

  sum = ctx.new_file(ctx.configuration.bin_dir, ctx.outputs.js.basename+".sum")
  #sum = ctx.outputs.summary
  #  -p pippo -v 1.0

  args = ['-o','/tmp/out','bazel'];
  for f in ctx.files.dart_sources :
    args += ['-s',f.path]

  #for f in ctx.files.html_templates :
  #  args += ['-t',f.path]

  all_outputs = [ctx.outputs.js,sum]
  output_html = [];
  tmpl_gen = "";

  for h in ctx.attr.html_templates:
    hf = ctx.new_file(h.label.name[ctx.attr.asset_prefix_length:]);
    output_html += [hf]
    all_outputs += [hf]
    for f in h.files :
      tmpl_gen += "%s\n%s\n" % (f.path,hf.path)
      #args += ['-t',"\"%s@=>@%s\"" % (f.path,hf.path)]

  tmpl_rule = ctx.new_file(ctx.label.name+"_template.map");
  ctx.file_action(tmpl_rule,content =tmpl_gen);
  args += ['-T',tmpl_rule.path]

  all_inputs = ctx.files.dart_sources +  ctx.files.html_templates + [tmpl_rule]

  if (ctx.attr.deps) :
    for f in ctx.attr.deps :
      #print("USING SUM : %s" % (f.summary))
      args += ['-m',f.summary.path]
      all_inputs += [f.summary]
      if (f.external) :
        args += ['-M',"%s=%s/%s" % (f.package_name ,f.label.workspace_root,f.label.name)]
        #print("DEP : %s =>  %s/library" % (f.package_name ,f.label.workspace_root))

  args += ['-x',sum.path]
  args += ['-o',ctx.outputs.js.path]
  args += ['-p',ctx.attr.package_name]
  args += ['-v',ctx.attr.version]
  args += ['-b',ctx.files.base_path[0].path]

  if (ctx.attr.export_sdk) :
    sdk_out = ctx.new_file('dart_sdk.js');
    requirejs_out = ctx.new_file('require.js');
    args += ['--export-sdk',sdk_out.path,'--export-requirejs',requirejs_out.path]
    all_outputs += [sdk_out,requirejs_out]

  runfiles = ctx.runfiles(
    files = ctx.files.html_templates
    )

  ctx.action(
    inputs=all_inputs,
    outputs= all_outputs,
    arguments= args, # ['-o']+[ctx.outputs.js.path]+['-os']+[sum.path]+['-i']+ [f.path for f in ctx.files.dart_sources]+['-h']+ [f.path for f in ctx.files.html_templates]+['-s']+[f.summary.path for f in ctx.attr.deps],
    progress_message="Polymerizing %s" % ctx.outputs.js.short_path,
    executable= ctx.executable._exe)

  return struct(
    runfiles= runfiles,
    summary= sum, #ctx.outputs.summary
    generated_html = output_html,
    package_name = ctx.attr.package_name,
    version = ctx.attr.version,
    external = ctx.attr.external
    )

polymer_library = rule(
  implementation=_impl,
  attrs={
      'dart_sources': attr.label_list(allow_files=True),
      'base_path' : attr.label(mandatory=True,allow_files=True),
      'package_name' : attr.string(),
      'version' : attr.string(),
      'export_sdk' : attr.int(default=0),
      'external' : attr.int(default=0),
      'asset_prefix_length' : attr.int(default=4),  # remove 'lib/' from assets
      'html_templates': attr.label_list(allow_files=True),
      'deps': attr.label_list(allow_files=False,providers=["summary"]),
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

   if (repository_ctx.attr.download) :
     repository_ctx.execute([
       'dart',
       '/home/vittorio/Develop/dart/devc_builder/bin/polymerize.dart',
       'pub',
       '-p',repository_ctx.attr.package_name,
       '-v',repository_ctx.attr.version,
       '-d',repository_ctx.path("")])
   #pkg_src = "%s/.pub-cache/hosted/http%%58%%47%%47pub.drafintech.it%%585001/%s-%s/lib" % (repository_ctx.configuration.default_shell_env['HOME'],repository_ctx.attr.package_name , repository_ctx.attr.version)
   else :
    #print("SRC: %s" % pkg_src)
    repository_ctx.symlink(repository_ctx.attr.src_path,"")

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
      'src_path' : attr.string(),
      'download' : attr.int(default=0),
      '_templ' : attr.label(default=Label("//:pub.template.BUILD")),
      #'_pub_download' : attr.label(cfg='host',default = Label('//:pub_download'),executable=True)
    }
  )
