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
    arguments= args,
    execution_requirements= {'local':'true'}, # This is need to make bower runs in decent time, will it work for compile too?
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

def _dartFileImpl(ctx):
  all_inputs=[ctx.outputs.gen];
  all_inputs+=ctx.files.dart_sources;

  all_inputs_html = [ctx.outputs.js];

  args=['dart_file'];

  args_html=['dart_file','html'];

  for f in ctx.attr.other_deps:
      args_html+=['-d',f.html.path]
      all_inputs_html+=[f.html]

  for f in ctx.attr.deps:
    args+=['-s',f.summary.path]
    args_html+=['-d',f.html.path]
    all_inputs+=[f.summary]
    all_inputs_html+=[f.html]


  args+=['-o',ctx.outputs.js.path]
  args+=['-g',ctx.outputs.gen.path]

  args_html+=['-o',ctx.outputs.js.path]
  args_html+=['-h',ctx.outputs.html.path]

  #for f in ctx.files.dart_sources:
  args+=['-i',ctx.attr.dart_source_uri]
  args_html+=['-i',ctx.attr.dart_source_uri]

  html_temp = ctx.new_file('html_temp_%s' % ctx.label.name.replace('/','__'));
  all_inputs_html+= [html_temp]
  args_html+=['-t',html_temp.path]

  # GERATE DART FILE
  ctx.action(
    inputs=ctx.files.dart_sources,
    outputs= [ ctx.outputs.gen, html_temp ],
    arguments= ['dart_file','generate','-g',ctx.outputs.gen.path,'-i',ctx.attr.dart_source_uri,'-t',html_temp.path],
    execution_requirements= {'local':'true'}, # This is need to make bower runs in decent time, will it work for compile too?
    progress_message="Generating %s" % ctx.outputs.js.short_path,
    executable= ctx.executable._exe_py)

  # BUILD WITH DDC
  ctx.action(
    inputs=all_inputs,
    outputs= [ ctx.outputs.js, ctx.outputs.sum,ctx.outputs.js_map],
    arguments= args,
    execution_requirements= {'local':'true'}, # This is need to make bower runs in decent time, will it work for compile too?
    progress_message="Building %s" % ctx.outputs.js.short_path,
    executable= ctx.executable._exe_py)

  # GENERATE HTML STUB
  ctx.action(
      inputs=all_inputs_html,
      outputs= [ ctx.outputs.html ],
      arguments= args_html,
      execution_requirements= {'local':'true'}, # This is need to make bower runs in decent time, will it work for compile too?
      progress_message="Generate HTML %s" % ctx.outputs.js.short_path,
      executable= ctx.executable._exe_py)

  return struct(
      js = ctx.outputs.js,
      gen = ctx.outputs.gen,
      summary = ctx.outputs.sum,
      html = ctx.outputs.html
  );

dart_file = rule(
    implementation = _dartFileImpl,
    attrs={
      'dart_sources': attr.label_list(allow_files=True),
      'other_deps':attr.label_list(allow_files=True,providers=['html']),
      'dart_source_uri' : attr.string(),
      'deps': attr.label_list(allow_files=False,providers=["summary",'html']),
      '_exe_py' : attr.label(cfg='host',default = Label('@polymerize_tool//:polymerize'),executable=True)
    },
    outputs = {
        "js" : "%{name}.js",
        "sum" : "%{name}.sum",
        "gen" : "%{name}.g.dart",
        "js_map": "%{name}.js.map",
        "html" : "%{name}.mod.html"
        # "summary" : "%{name}.sum"
    }
)


def exportDartSDK(ctx):
  ctx.action(
      outputs=[ctx.outputs.js,ctx.outputs.html],
      execution_requirements= {'local':'true'}, # This is need to make bower runs in decent time
      arguments= ['export_sdk','-o',ctx.outputs.js.path,'-h',ctx.outputs.html.path],
      progress_message="Export Dart SDK ",
      executable= ctx.executable._exe)
  return struct(
        html = ctx.outputs.html
    );

export_dart_sdk = rule (
   implementation = exportDartSDK,
   attrs={
           '_exe' : attr.label(cfg='host',default = Label('@polymerize_tool//:polymerize'),executable=True),
       },
       outputs = {
           "js" : "%{name}.js",
           'html' : '%{name}.mod.html'
       }
   )

def copyToBinDir(ctx):
  copied=[]
  content=""
  for src in ctx.attr.resources:
    dst = ctx.new_file(src.label.name[4:])
    copied+=[dst]
    content+="%s\n" % dst.path
    ctx.action(
        outputs=[dst],
        inputs=src.files.to_list(),
        arguments=[ p.path for p in src.files] + [dst.path],
        progress_message='copy file %s' % src.label,
        command='cp $1 $2')

  ctx.action(outputs=[ctx.outputs.fileList],inputs=copied,command='touch $1',arguments=[ctx.outputs.fileList.path])

  return struct(
      copied = copied
  )

copy_to_bin_dir = rule(
    implementation = copyToBinDir,
    attrs ={
        "resources" : attr.label_list(allow_files=True),
        '_exe' : attr.label(cfg='host',default = Label('@polymerize_tool//:polymerize'),executable=True)
    },
    outputs = {
        'fileList' : '%{name}.list'
    }
)

def simple_asset_impl(ctx):


  args = [ctx.files.path[0].path,ctx.outputs.asset.path]



  ctx.action(
      outputs=[ctx.outputs.asset],
      inputs= ctx.files.path,
      arguments=args,
      progress_message='copy assets',
      execution_requirements= {'local':'true'}, # This is need to make bower runs in decent time, will it work for compile too?
      command='cp $1 $2')
  return struct(
      html = ctx.outputs.asset
  )

simple_asset = rule(
    implementation = simple_asset_impl,
    attrs ={
        "path" : attr.label_list(allow_files=True),
        '_exe' : attr.label(cfg='host',default = Label('@polymerize_tool//:polymerize'),executable=True)
    },
    outputs={
        'asset' : 'file_%{name}'
    }
)


def generateBowerImpl(ctx):
  # collect all deps
  args = ["bower"]
  all_inputs = []
  for f in ctx.attr.deps :
    args += ['-u',f.bower_needs.path]
    all_inputs += [f.bower_needs]

  for k in ctx.attr.resolutions.keys():
    args += ['-r',k,'-R',ctx.attr.resolutions[k]]

  args += ['-o',ctx.outputs.dest.path]

  OUT = ctx.new_file("bower_components/")

  ctx.action(
      inputs=all_inputs,
      outputs= [ctx.outputs.dest,OUT],
      execution_requirements= {'local':'true'}, # This is need to make bower runs in decent time
      arguments= args,
      progress_message="Download JS dependencies with %s" % ctx.outputs.dest.short_path,
      executable= ctx.executable._exe)

  return struct(
      bower=ctx.outputs.dest
  )

bower = rule(
    implementation=generateBowerImpl,
    attrs={
        '_exe' : attr.label(cfg='host',default = Label('@polymerize_tool//:polymerize'),executable=True),
        'resolutions' : attr.string_dict(),
        'deps': attr.label_list(allow_files=False,providers=["bower_needs"])
    },
    outputs = {
        "dest" : "bower.json"
    }
)
