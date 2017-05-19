PUB_CACHE="${cache_dir}"
DART_HOME="${dart_home}"
PATH="/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin:${dart_home}"

export PUB_CACHE DART_HOME PATH

exec ${cache_dir}/bin/${tool_name} $*