def modulePath(label):
 seq=[];

 if (label.workspace_root) :
  seq += [label.workspace_root]

 if (label.package) :
  seq += [label.package]

 seq += [label.name]

 return "/".join(seq) # + ".mod.html"

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

  genflag=ctx.new_file(ctx.label.name+".genflags")
  ctx.file_action(genflag,content= '\n'.join(['dart_file','generate','-g',ctx.outputs.gen.path,'-i',ctx.attr.dart_source_uri,'-t',html_temp.path]))

  # GERATE DART FILE
  ctx.action(
    inputs=ctx.files.dart_sources+ [genflag],
    outputs= [ ctx.outputs.gen, html_temp ],
    mnemonic= 'Polymerize',
    arguments= ['@%s' % genflag.path],
    execution_requirements= {'supports-workers':'1'}, # This is need to make bower runs in decent time, will it work for compile too?
    progress_message="Generating %s" % ctx.outputs.js.short_path,
    executable= ctx.executable._exe_py)

  genflag3=ctx.new_file(ctx.label.name+".ddcflags");
  ctx.file_action(genflag3,content='\n'.join(args) );

  # BUILD WITH DDC
  ctx.action(
    inputs=all_inputs+[genflag3],
    outputs= [ ctx.outputs.js, ctx.outputs.sum,ctx.outputs.js_map],
    arguments= ['@%s' % genflag3.path],
    mnemonic= 'Polymerize',
    execution_requirements= {'supports-workers':'1'}, # This is need to make bower runs in decent time, will it work for compile too?
    progress_message="Building %s" % ctx.outputs.js.short_path,
    executable= ctx.executable._exe_py)


  genflag2=ctx.new_file(ctx.label.name+".htmflags");
  ctx.file_action(genflag2,content='\n'.join(args_html) );

  # GENERATE HTML STUB
  ctx.action(
      inputs=all_inputs_html + [genflag2],
      outputs= [ ctx.outputs.html ],
      arguments= ['@%s' % genflag2.path],
      mnemonic= 'Polymerize',
      execution_requirements= {'supports-workers':'1'}, # This is need to make bower runs in decent time, will it work for compile too?
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
      outputs=[ctx.outputs.js,ctx.outputs.html,ctx.outputs.imd,ctx.outputs.imd_html],
      execution_requirements= {'local':'true'}, # This is need to make bower runs in decent time
      arguments= ['export_sdk','-o',ctx.outputs.js.path,'-h',ctx.outputs.html.path,'--imd=%s' % ctx.outputs.imd.path,'--imd_html=%s' % ctx.outputs.imd_html.path ],
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
           'html' : '%{name}.mod.html',
           'imd' : 'imd.js',
           'imd_html' : 'imd.html'
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
        'asset' : 'assets/%{name}'
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
