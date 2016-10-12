#!/bin/bash

[ -z "$sed_cmd" ] && sed_cmd=sed
[ -z "$python_cmd" ] && python_cmd=python

#set -x 

#$1: message
log() {
  local func=${FUNCNAME[1]}
  local hdr="[openstack-config.log]"
  [ -n "$func" ] && hdr="$hdr $func() -"
  >&2 echo -e "$hdr $1"
}

#add newtext after the matching line.
#  - do nothing if already exist
#  - insert at the end of line if empty line is given
#Note: do not use '|' in the line or newText since it is used 
#      as a sed deliminator.
#$1: ip $2: cfg_file $3: line $4: newText
add_after_line() {
  local ip=$1
  local cfg_file=$2
  local line=$3
  local newText=$4
  local found=$(ssh ${ip} "$sed_cmd -n '\|$newText\$|p;' $cfg_file")

  [ -n "$found" ] && log "already exist:$found" && return; # do thing if already there

  log "add:\n\t$newText"
  if [ -n "$line" ]; then
    ssh ${ip} "$sed_cmd -i '\|$line| s|.*|&\n$newText|' $cfg_file"
    log "after:\n\t $line"
  else
    ssh ${ip} "$sed_cmd -i '$ a\\$newText' $cfg_file"
    log "after: the last line"
  fi
}

#add newtext before the matching line.
#  - do nothing if already exist
#  - insert at the 1st line if empty line is given
#Note: do not use '|' in the line or newText since it is used 
#      as a sed deliminator.
#$1: ip $2: cfg_file $3: line $4: newText
add_before_line() {
  local ip=$1
  local cfg_file=$2
  local line=$3
  local newText=$4
  local found=$(ssh ${ip} "$sed_cmd -n '\|$newText\$|p;' $cfg_file")

  [ -n "$found" ] && log "already exist:$found" && return; # do thing if already there

  log "add:\n\t$newText"
  if [ -n "$line" ]; then
    ssh ${ip} "$sed_cmd -i '\|$line| i\\$newText' $cfg_file"
    log "before:\n\t $line"
  else
    ssh ${ip} "$sed_cmd -i '1 i\\$newText' $cfg_file"
    log "before: the 1st line"
  fi
}

#delete the matching line
#Note: do not use '|' in the line or newText since it is used 
#      as a sed deliminator.
#$1: ip $2: cfg_file $3: line
delete_line() {
  local ip=$1
  local cfg_file=$2
  local line=$3

  ssh ${ip} "$sed_cmd -i '\|$line|d' $cfg_file"
  log "delete:\n\t $line"
}

#get the matching line
#Note: do not use '|' in the line or newText since it is used 
#      as a sed deliminator.
#$1: ip $2: cfg_file $3: line
get_line() {
  local ip=$1
  local cfg_file=$2
  local line=$3
  local value=$(ssh ${ip} "$sed_cmd -n '\|$line|p' $cfg_file")

  echo "$value"
  log "get:\n\t $value"
}

#add or update existing one.
#$1:ip $2: cfg_file $3: section, $4: key, $5: value
add_config() {
  local ip=$1
  local cfg_file=$2
  local section=$3
  local key=$4
  local value=$5
  local found=$(ssh ${ip} "$sed_cmd -n '0,\|^\[$section\]|d;\|^\[|,\$d;\|^$key[ \t]*=|p;' $cfg_file")
  local regexp="$key[ \t]*=[ \t]*$value"

  [[ "$found" =~ $regexp ]] && log "already exist:\n\t[$section]\n\t$found" && return; # do thing if already there

  if [ -n "$found" ]; then  #replace existing one
    ssh ${ip} "$sed_cmd -i '\|^\[$section\]|,\|^\[| s|^$key[ \t]*=.*|$key=$value|' $cfg_file"
    log "replace:\n\t[$section]\n\t$key=$value"
  else #add new one at the 1st line of section
    #FIXME: create new section if missing
    ssh ${ip} "$sed_cmd -i '\|^\[$section\]|a $key=$value' $cfg_file"
    log "add:\n\t[$section]\n\t$key=$value"
  fi
}

delete_config() {
  local ip=$1
  local cfg_file=$2
  local section=$3
  local key=$4
  local value=$5
  ssh ${ip} "$sed_cmd -i '\|^\[$section\]|,\|^\[| {\|^$key[ \t]*=[ \t]*$value|d}' $cfg_file"

  log "del:\n\t[$section]\n\t$key=$value"
}

#get the existing value for the given key.
#$1:ip $2: cfg_file $3: section, $4: key
get_config() {
  local ip=$1
  local cfg_file=$2
  local section=$3
  local key=$4
  local value=

  value=$(ssh ${ip} "$python_cmd -c 'from oslo_config import cfg;\
    cfg.CONF.register_opt(cfg.StrOpt(\"$key\"), group=\"$section\");\
    cfg.CONF([\"--config-file\", \"$cfg_file\"]);\
    v = cfg.CONF[\"$section\"][\"$key\"]; \
    print (v if v else \"\");'")

  log "get:\n\t[$section]\n\t$key=$value"
  echo "$value"
}

#add by keeping existing one.
#$1:ip $2: cfg_file $3: section, $4: key, $5: value
add_multi_opt_config() {
  local ip=$1
  local cfg_file=$2
  local section=$3
  local key=$4
  local value=$5
  local found=$(ssh ${ip} "$sed_cmd -n '0,\|^\[$section\]|d;\|^\[|,\$d;\|^$key[ \t]*=|p;' $cfg_file")
  local regexp=".*$key[ \t]*=[ \t]*$value"

#FIXME: compare w/ leading newline 
  [[ "$found" =~ $regexp ]] && log "already exist:\n\t[$section]\n\t$found" && return; # do thing if already there

  if [ -n "$found" ]; then  #adding keeping existing one
    log "already existing multi opts:\n\t[$section]\n\t$found"
    #find last match
#FIXME: define range as target section: /^\[$section\]/,/^\[/
    found=$(ssh ${ip} "$sed_cmd '\|^$key[ \t]*=|h;g;\$!d;' $cfg_file")
    ssh ${ip} "$sed_cmd -i '\|^\[$section\]|,\|^\[| s|^\($found\)$|\1\n$key=$value|' $cfg_file"
    log "append:\n\t$key=$value"
  else #if not exist, add new one at the 1st line of section
    ssh ${ip} "$sed_cmd -i '\|^\[$section\]|a $key=$value' $cfg_file"
    log "add:\n\t[$section]\n\t$key=$value"
  fi
}

#get the existing value(comma seperated list) for the given key.
#$1:ip $2: cfg_file $3: section, $4: key
get_multi_opt_config() {
  local ip=$1
  local cfg_file=$2
  local section=$3
  local key=$4
  local value=

  value=$(ssh ${ip} "$python_cmd -c 'from oslo_config import cfg;\
    cfg.CONF.register_opt(cfg.MultiStrOpt(\"$key\"), group=\"$section\");\
    cfg.CONF([\"--config-file\", \"$cfg_file\"]);\
    v = cfg.CONF[\"$section\"][\"$key\"]; \
    v = \",\".join(v if v else [\"\"]); \
    print v;'")

  log "get:\n\t[$section]\n\t$key=$value"
  echo "$value"
}
