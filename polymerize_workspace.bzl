POLYMERIZE_VERSION='0.6.1'

def _buildLibTemplate(repository_ctx,dep_string):
  repository_ctx.template(
   "BUILD",repository_ctx.attr._templ,
   substitutions = {
     "@{name}" : repository_ctx.name,
     "@{deps}" : dep_string,
     "@{package_name}" : repository_ctx.attr.package_name,
     "@{version}" : repository_ctx.attr.version })
##
## Repository rule to crete
## an external repository for a dart library
##

def _dartLibImp(repository_ctx):
   #print ("Creating repo for %s" % repository_ctx.name)


   if (repository_ctx.attr.deps) :
     dep_string = ",".join([ ("'%s'" % x) for x in repository_ctx.attr.deps ])
     dep_string = "deps = [%s]," % dep_string
     # print ("DEPS : %s" % dep_string)
   else :
     dep_string = ""



   if (repository_ctx.attr.src_path) :
    repository_ctx.symlink(repository_ctx.attr.src_path,"")
    _buildLibTemplate(repository_ctx,dep_string)
   else :
     repository_ctx.symlink(Label("@polymerize_tool//:polymerize.py"),"polymerize.py")
     _buildLibTemplate(repository_ctx,dep_string)
     res = repository_ctx.execute([
       'python',
       '%s' % repository_ctx.path('polymerize.py'),
       'pub',
       '-p',repository_ctx.attr.package_name,
       '-v',repository_ctx.attr.version,
       '-H',repository_ctx.attr.pub_host,
       '-d',repository_ctx.path("")])
     if (res.return_code!=0) :
       fail('Error while downloading dependency %s - %s using %s: \nSTDERR:\n%s\nSTDOUT:\n%s' % (repository_ctx.attr.package_name,repository_ctx.attr.version,repository_ctx.attr.pub_host,res.stderr,res.stdout))


dart_library = repository_rule(
    implementation = _dartLibImp,
    attrs = {
      'deps' : attr.string_list(),
      'package_name' : attr.string(),
      'pub_host' : attr.string(default='https://pub.dartlang.org/api'),
      'version' : attr.string(),
      'src_path' : attr.string(),
      '_templ' : attr.label(default=Label("//:pub.template.BUILD")),
      #'_pub_download' : attr.label(cfg='host',default = Label('//:pub_download'),executable=True)
    }
  )

##
## Repository rule to create a tool from a dart
## package.
##

def _dartPubImp(repository_ctx) :
 #print("CREATING POLYMERIZE TOOL REPOSITORY")
 #print("PUBBING : %s " % repository_ctx.path(''))

 repository_ctx.template('pub.py',repository_ctx.attr._pub_pkg_py,substitutions={
     '${base_dir}' : "%s"  % repository_ctx.path('tool'),
     '${cache_dir}' : "%s" % repository_ctx.path('cache'),
     '${dart_home}' : repository_ctx.attr.dart_home,
     '${pub_host}' : repository_ctx.attr.pub_host,
     '${overrides}' : repository_ctx.attr.local_dir
     },executable=True)

 if (repository_ctx.attr.local_dir) :
   print("USING LOCAL REPOSITORY : %s" % repository_ctx.attr.local_dir);


 #print("REPPING")

 repository_ctx.template('%s.py' % repository_ctx.attr.tool_name,repository_ctx.attr._polymerize_py,substitutions={
      '${base_dir}' : "%s"  % repository_ctx.path('tool'),
      '${cache_dir}' : "%s" % repository_ctx.path('cache'),
      '${dart_home}' : repository_ctx.attr.dart_home,
      '${tool_name}' : repository_ctx.attr.tool_name
      },executable=True)

 #print("CIPPING")
 repository_ctx.template('BUILD',repository_ctx.attr._dartpub_build,substitutions={
     '${tool_name}' : repository_ctx.attr.tool_name
 });

 # print('Fetching %s (%s) with pub ...' % (repository_ctx.attr.package_name,repository_ctx.attr.package_version))
 res = repository_ctx.execute([
   'python',
   repository_ctx.path('pub.py'),
   repository_ctx.attr.package_name,
   repository_ctx.attr.package_version])

 if (res.return_code!=0) :
   fail("Error while installing polymerize tool.\nSTDERR:\n%s\nSTDOUT:\n%s" % (res.stderr , res.stdout))

 # print("Success")

dart_tool = repository_rule(
  implementation = _dartPubImp,
  attrs = {
    'pub_host' : attr.string(default='https://pub.dartlang.org'),
    'package_name' : attr.string(default='polymerize'),
    'package_version' : attr.string(default='0.2.10'),
    'tool_name' : attr.string(default='polymerize'),
    'local_dir': attr.string(),
    'dart_home' : attr.string(),
    '_pub_pkg_py' : attr.label(default=Label('//:template.pub.py')),
    '_polymerize_py' : attr.label(default=Label('//:template.dart_tool.py')),
    '_dartpub_build' : attr.label(default=Label('//:dart_tool.BUILD'))
  })


##
## Convenience macros to create the polymerize_tool
##

def init_polymerize(dart_home):
  dart_tool(
    name='polymerize_tool',
    dart_home=dart_home,
    package_name='polymerize',
    tool_name='polymerize',
    package_version=POLYMERIZE_VERSION,
    pub_host = 'https://pub.dart-polymer.com')


def init_local_polymerize(dart_home,path):
  dart_tool(
    name='polymerize_tool',
    package_name='polymerize',
    tool_name='polymerize',
    dart_home=dart_home,
    package_version=POLYMERIZE_VERSION,
    local_dir = path,
    pub_host = 'http://pub.dart-polymer.com')
