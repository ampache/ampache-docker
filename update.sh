#!/usr/bin/env bash
set -eo pipefail

min_version='6.4'

declare ampache_versions=( $(
	git ls-remote --tags https://github.com/ampache/ampache.git \
		| cut -d/ -f3 \
		| grep -viE '[a-z]' \
		| tr -d '^{}' \
		| sort -V 
))

variants=(
	aio
    apache
)

declare -A php_version=(
	[default]='8.3'
    [6.0.0]='8.2'
    [6.0.1]='8.2'
    [6.0.2]='8.2'
    [6.0.3]='8.2'
    [6.1.0]='8.2'
)

declare -A debian_version=(
	[default]='bookworm'
)

declare -A crontab_int=(
	[default]='5'
)

declare -A cmd=(
	[apache]='apache2-foreground'
	[aio]='run.sh'
)

declare -A base=(
	[apache]='debian'
	[aio]='debian-aio'
)

# version_greater_or_equal A B returns whether A >= B
function version_greater_or_equal() {
	[[ "$(printf '%s\n' "$@" | sort -V | head -n 1)" != "$1" || "$1" == "$2" ]];
}

function create_variant() {
    version=$1
    variant=$2

	dir="$version/$variant"
	debianVersion=${debian_version[$version]-${debian_version[default]}}
	phpVersion=${php_version[$version]-${php_version[default]}}
	crontabInt=${crontab_int[$version]-${crontab_int[default]}}
       url="https://github.com/ampache/ampache/releases/download/${version}/ampache-${version}_all_php${phpVersion}.zip"
    ascUrl="https://github.com/ampache/ampache/releases/download/${version}/ampache-${version}_all_php${phpVersion}.zip.asc"

	echo "[0] Create/Update $dir directory with a Dockerfile."
	mkdir -p "$dir"

	template="Dockerfile-${base[$variant]}.template"
	echo "# DO NOT EDIT: created by update.sh from $template" > "$dir/Dockerfile"
	cat "$template" >> "$dir/Dockerfile"

	echo "[1] Updating Docker file for $version $variant"

	# Replace the variables.
	sed -ri -e '
		s/%%DEBIAN_VERSION%%/'"$debianVersion"'/g;
		s/%%PHP_VERSION%%/'"$phpVersion"'/g;
		s/%%VARIANT%%/'"$variant"'/g;
		s/%%VERSION%%/'"$fullversion"'/g;
		s/%%DOWNLOAD_URL%%/'"$(sed -e 's/[\/&]/\\&/g' <<< "$url")"'/g;
		s/%%DOWNLOAD_URL_ASC%%/'"$(sed -e 's/[\/&]/\\&/g' <<< "$ascUrl")"'/g;
		s/%%CMD%%/'"${cmd[$variant]}"'/g;
		s|%%VARIANT_EXTRAS%%|'"${extras[$variant]}"'|g;
		s/%%APCU_VERSION%%/'"${pecl_versions[APCu]}"'/g;
		s/%%MEMCACHED_VERSION%%/'"${pecl_versions[memcached]}"'/g;
		s/%%REDIS_VERSION%%/'"${pecl_versions[redis]}"'/g;
		s/%%IMAGICK_VERSION%%/'"${pecl_versions[imagick]}"'/g;
		s/%%CRONTAB_INT%%/'"$crontabInt"'/g;
	' "$dir/Dockerfile"

	# Copy the shell scripts
	#for name in entrypoint cron; do
	#	cp "docker-$name.sh" "$dir/$name.sh"
	#done

	# Copy the config directory
	cp -rT data "$dir/data"

}


for version in "${ampache_versions[@]}"; do
    if version_greater_or_equal "$version" "$min_version"; then
		for variant in "${variants[@]}"; do
			create_variant $version $variant
		done
	fi
done

