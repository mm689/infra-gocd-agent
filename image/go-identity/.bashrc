# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples


declare -r confdir=~/.bashrc.d
declare -r omitfile="$confdir/.omit"
declare -r enablefile="$confdir/.enable"

# create empty omitfile if one does not already exist (first run?)
test -e "$omitfile" || touch "$omitfile"
test -e "$enablefile" || touch "$enablefile"


##
# Map a file into an associative array, line by line
#
# Similar to `mapfile` builtin, but associative.
#
_assocmap()
{
  local -r dest=$1 file="$2"

  # place each line into an associative array
  # warning: this makes no attempt to protect against arbitrary code
  # execution, since we'll be sourcing scripts anyway
  while read line; do
    eval "$dest[$line]=1"
  done < "$file"
}


##
# Determines whether the current module is explicitly enabled
#
# This is only important for modules that care to check this flag; many are
# enabled by default by simply omitting this check, and instead must be
# explicitly omitted.
#
enabled()
{
  test $_cur_enabled -eq 1
}
declare -i _cur_enabled=0


main()
{
  local -A omits enables

  # load omits and enables into associative arrays
  _assocmap omits "$omitfile"
  _assocmap enables "$enablefile"

  readonly omits enables

  # source all non-omitted configuration files
  local conf
  for conf in "$confdir"/*; do
    # grab the name without its leading path or numeric prefix
    local name="${conf#*/*_}"

    # ignore if omitted; otherwise, source the script
    test "${omits[$name]}" != 1 || continue

    # determine if this module has been explicitly enabled (not all need to be;
    # this allows testing using the `enabled` function above)
    _cur_enabled="${enables[$name]:-0}"

    . "$conf"
  done
}

main "$@"
