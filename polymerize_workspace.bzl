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


   if (repository_ctx.attr.src_path) :
    repository_ctx.symlink(repository_ctx.attr.src_path,"")
   else :
     repository_ctx.symlink(Label("@dartpub//:polymerize.sh"),"polymerize.sh")
     repository_ctx.execute([
       'bash',
       '%s' % repository_ctx.path('polymerize.sh'),
       'pub',
       '-p',repository_ctx.attr.package_name,
       '-v',repository_ctx.attr.version,
       '-H',repository_ctx.attr.pub_host,
       '-d',repository_ctx.path("")])

   repository_ctx.template(
    "BUILD",repository_ctx.attr._templ,
    substitutions = {
      "@{name}" : repository_ctx.name,
      "@{deps}" : dep_string,
      "@{package_name}" : repository_ctx.attr.package_name,
      "@{version}" : repository_ctx.attr.version })

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

def _dartPubImp(repository_ctx) :
 #print("CREATING POLYMERIZE TOOL REPOSITORY")
 #print("PUBBING : %s " % repository_ctx.path(''))

 repository_ctx.template('pub_pkg.sh',repository_ctx.attr._pub_pkg,substitutions={
   '${base_dir}' : "%s"  % repository_ctx.path('tool'),
   '${cache_dir}' : "%s" % repository_ctx.path('cache'),
   '${pub_host}' : repository_ctx.attr.pub_host,
   '${overrides}' : repository_ctx.attr.local_dir
   },executable=True)

 if (repository_ctx.attr.local_dir) :
   print("USING LOCAL REPOSITORY : %s" % repository_ctx.attr.local_dir);

 repository_ctx.execute([
   'bash',
   repository_ctx.path('pub_pkg.sh'),
   repository_ctx.attr.package_name,
   repository_ctx.attr.package_version])

 #print("REPPING")

 repository_ctx.template('polymerize.sh',repository_ctx.attr._polymerize,substitutions={
   '${base_dir}' : "%s"  % repository_ctx.path('tool'),
   '${cache_dir}' : "%s" % repository_ctx.path('cache'),
   },executable=True)
 #print("CIPPING")
 repository_ctx.template('BUILD',repository_ctx.attr._dartpub_build,substitutions={});

dart_pub = repository_rule(
  implementation = _dartPubImp,
  attrs = {
    'pub_host' : attr.string(default='https://pub.dartlang.org/api'),
    'package_name' : attr.string(default='polymerize'),
    'package_version' : attr.string(default='0.2.10'),
    'local_dir': attr.string(),
    '_pub_pkg' : attr.label(default=Label('//:template.pub_pkg.sh')),
    '_polymerize' : attr.label(default=Label('//:template.polymerize.sh')),
    '_dartpub_build' : attr.label(default=Label('//:dartpub.BUILD'))
  })


def init_polymerize():
  dart_pub(
    name='dartpub',
    package_name='polymerize',
    package_version='0.2.10',
    pub_host = 'http://pub.drafintech.it:5001')


def init_local_polymerize(path):
  dart_pub(
    name='dartpub',
    package_name='polymerize',
    package_version='0.2.10',
    local_dir = path,
    pub_host = 'http://pub.drafintech.it:5001')
