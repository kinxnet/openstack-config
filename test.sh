source ./openstack-config.sh


# http://www.codelibary.com/snippet/699/assert
assert ()                 #  If condition false,
{                         #+ exit from script with error message.
  E_PARAM_ERR=98
  E_ASSERT_FAILED=99
 
 
  if [ -z "$3" ]          # Not enough parameters passed.
  then
    return $E_PARAM_ERR   # No damage done.
  fi
 
  lineno=$3
 
  if [ "$1" != "$2" ] 
  then
    log "Assertion failed:  \"$1\" == \"$2\""
    log "File \"$0\", line $lineno"
    exit $E_ASSERT_FAILED
  # else
  #   return
  #   and continue executing script.
  fi 
}

#
#[group_1]
#single_opt=3600
#multi_opt=con_1
#multi_opt=con_2
#multi_opt=
#
##end group_1
#[group_2]

test_openstack_config() {
  local host=localhost
  local cfg_file="$PWD/example.conf"
  local sec1="group_1"
  local sec2="group_2"
  local single_k="single_opt"
  local multi_k="multi_opt"
  local line="#end $sec1"

  echo "... get config"
  assert "1234"  "$(get_config $host $cfg_file $sec1 $single_k)" $LINENO
  assert "con_1,con_2," "$(get_multi_opt_config $host $cfg_file $sec1 $multi_k)" $LINENO
  assert "" "$(get_config $host $cfg_file $sec2 $single_k)" $LINENO
  assert "" "$(get_multi_opt_config $host $cfg_file $sec2 $multi_k)" $LINENO

  echo "... set config"
  add_config $host $cfg_file $sec1 $single_k "4321"
  assert "4321"  "$(get_config $host $cfg_file $sec1 $single_k)" $LINENO
  add_config $host $cfg_file $sec1 $single_k "1234"

  echo "... add config"
  add_config $host $cfg_file $sec2 $single_k "4321"
  assert "4321" "$(get_config $host $cfg_file $sec2 $single_k)" $LINENO

  echo "... del config"
  delete_config $host $cfg_file $sec2 $single_k "4321"
  assert "" "$(get_config $host $cfg_file $sec2 $single_k)" $LINENO

  echo "... add after the last line"
  add_after_line $host $cfg_file "" "#added line" 
  assert "#added line" "$(get_line $host $cfg_file "#added")" $LINENO
  delete_line $host $cfg_file "^#added" 
  assert "" "$(get_line $host $cfg_file "#added line")" $LINENO

  echo "... add at the 1st line"
  add_before_line $host $cfg_file "" "#added line" 
  assert "#added line" "$(get_line $host $cfg_file "#added")" $LINENO
  delete_line $host $cfg_file "^#added" 
  assert "" "$(get_line $host $cfg_file "#added line")" $LINENO

  echo "... add after line"
  add_after_line $host $cfg_file "^$line" "#after $sec1" 
  assert "#after $sec1" "$(get_line $host $cfg_file "^#after")" $LINENO
  delete_line $host $cfg_file "^#after" 
  assert "" "$(get_line $host $cfg_file "^#after")" $LINENO

  echo "... add before line"
  add_before_line $host $cfg_file "^$line" "#before $sec1" 
  assert "#before $sec1" "$(get_line $host $cfg_file "^#before")" $LINENO
  delete_line $host $cfg_file "^#before" 
  assert "" "$(get_line $host $cfg_file "^#before")" $LINENO
}

test_openstack_config
