import subprocess, os, sys

CACHE_DIR='${cache_dir}'

DART_HOME='/usr/lib/dart/bin'

def polymerize(args):
    exe = subprocess.Popen(['%s/bin/polymerize' % CACHE_DIR] + args, env={
        'PUB_CACHE': '%s' % CACHE_DIR,
        'PATH': '/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin:%s' % (DART_HOME)
    })

    exe.wait()
    return exe.returncode

if __name__ == '__main__':
    #print("Calling polymerize-py with %s" % (",".join(sys.argv[1:])))
    exit(polymerize(sys.argv[1:]))
