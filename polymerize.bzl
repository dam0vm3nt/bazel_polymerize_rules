def modulePath(label):
 seq=[];

 if (label.workspace_root) :
  seq += [label.workspace_root]

 if (label.package) :
  seq += [label.package]

 seq += [label.name]

 return "/".join(seq) # + ".mod.html"



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

  html_out= ctx.outputs.html;
  all_outputs = [ctx.outputs.js,sum,html_out]
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
      #if (f.external) :
      args += ['-M',"%s=%s" % (f.package_name ,modulePath(f.label))]
        #print("DEP : %s =>  %s/library" % (f.package_name ,f.label.workspace_root))

  # TODO : Provare a ricavare il perc. relativo della label al posto del path
  #print("CTX: %s / %s" % (ctx.outputs.html.root,ctx.outputs.html.short_path));


  args += ['-M',"%s=%s" % (ctx.attr.package_name , modulePath(ctx.label))]

  args += ['--bower-needs', ctx.outputs.bower_needs.path]
  all_outputs += [ctx.outputs.bower_needs]

  args += ['-x',sum.path]
  args += ['--output_html',html_out.path]
  args += ['-o',ctx.outputs.js.path]
  args += ['-p',ctx.attr.package_name]
  args += ['-v',ctx.attr.version]
  args += ['-b',ctx.files.base_path[0].path]

  if (ctx.attr.export_sdk) :
    sdk_out = ctx.new_file('dart_sdk.js');
    sdk_out_html = ctx.new_file('dart_sdk.html');
    requirejs_out = ctx.new_file('imd.js');
    requirehtml_out = ctx.new_file('imd.html');
    args += ['--export-sdk',sdk_out.path]
    args += ['--export-sdk-html',sdk_out_html.path]
    args += ['--export-requirejs',requirejs_out.path]
    args += ['--export-require_html',requirehtml_out.path]
    all_outputs += [sdk_out,sdk_out_html,requirejs_out,requirehtml_out]

  runfiles = ctx.runfiles(
    files = ctx.files.html_templates
    )

  ctx.action(
    inputs=all_inputs,
    outputs= all_outputs,
    arguments= args, # ['-o']+[ctx.outputs.js.path]+['-os']+[sum.path]+['-i']+ [f.path for f in ctx.files.dart_sources]+['-h']+ [f.path for f in ctx.files.html_templates]+['-s']+[f.summary.path for f in ctx.attr.deps],
    progress_message="Polymerizing %s" % ctx.outputs.js.short_path,
    executable= ctx.executable._exe_py)

  return struct(
    runfiles= runfiles,
    summary= sum, #ctx.outputs.summary
    bower_needs = ctx.outputs.bower_needs,
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
      '_exe_py' : attr.label(cfg='host',default = Label('@polymerize_tool//:polymerize'),executable=True)
  },
  outputs = {
    "js" : "%{name}.js",
    "html" : "%{name}.mod.html",
    "bower_needs" : "%{name}.bower"
  #  "summary" : "%{name}.sum"
  })


def generateBowerImpl(ctx):
  # collect all deps
  args = ["bower"]
  all_inputs = []
  for f in ctx.attr.deps :
    args += ['-u',f.bower_needs.path]
    all_inputs += [f.bower_needs]

  args += ['-o',ctx.outputs.dest.path]

  OUT = ctx.new_file("bower_components/")

  ctx.action(
      inputs=all_inputs,
      outputs= [ctx.outputs.dest,OUT],
      arguments= args, # ['-o']+[ctx.outputs.js.path]+['-os']+[sum.path]+['-i']+ [f.path for f in ctx.files.dart_sources]+['-h']+ [f.path for f in ctx.files.html_templates]+['-s']+[f.summary.path for f in ctx.attr.deps],
      progress_message="Download JS dependencies with %s" % ctx.outputs.dest.short_path,
      executable= ctx.executable._exe)

  return struct(
      bower=ctx.outputs.dest
  )

bower = rule(
    implementation=generateBowerImpl,
    attrs={
        '_exe' : attr.label(cfg='host',default = Label('@polymerize_tool//:polymerize'),executable=True),
        'deps': attr.label_list(allow_files=False,providers=["bower_needs"])
    },
    outputs = {
        "dest" : "bower.json"
    }
)