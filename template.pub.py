import sys, subprocess, os

BASE_DIR = "${base_dir}"
OVERRIDES = "${overrides}"
PUB_HOSTED_URL = "${pub_host}"
CACHE_DIR = "${cache_dir}"


def pub(pkg_name, pkg_version):
    if (not os.path.exists(BASE_DIR)):
        os.makedirs(BASE_DIR)
    pubspec = open(os.path.join(BASE_DIR, "pubspec.yaml"),mode='w')
    pubspec.write("""
# MADE BY Polymerizy - PY
name: %s_pub
dependencies:
 %s: "%s"
""" % (pkg_name, pkg_name, pkg_version))

    pubspec.close()

    log = open(os.path.join(BASE_DIR, "log"),mode='w')

    if OVERRIDES:
        SOURCE_ARGS = ['--source', 'path', OVERRIDES]
    else:
        SOURCE_ARGS = [pkg_name, pkg_version]

    proc = subprocess.Popen(['/usr/lib/dart/bin/pub', 'global', 'activate'] + SOURCE_ARGS, env={
        'PUB_HOSTED_URL': PUB_HOSTED_URL,
        'PUB_CACHE': CACHE_DIR,
        'HOME':BASE_DIR
    }, stdout=log, stderr=log)

    proc.wait()
    log.close()
    return proc.returncode


if __name__ == '__main__':
    exit(pub(sys.argv[1], sys.argv[2]))
