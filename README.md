Shell utility functions for manipulating openstack config files on the remote host. The remote host can be accessed through ssh.

## Why?
 - [crduini](https://github.com/pixelb/crudini/blob/master/TODO) doesn't support MultiStrOpt.
 - [oslo.config](https://github.com/openstack/oslo.config) doesn't support editing config files.

## How to use:
 - refer to test.sh
 - how to execute:
  ```
./test.sh
  ```
 - If you are testing with mac OSX, you need to install gnu sed and execute as follows to run with newly installed sed or python.
  ```
python_cmd=`which python` sed_cmd=`which sed` ./test.sh
  ```

## Functions: add/delete/get the matching line.
### add_after_line
 ```
add newtext after the matching line.
  - do nothing if already exist
  - insert at the end of line if empty line is given
Note: do not use '|' in the line or newText since it is used
      as a sed deliminator.
$1: ip $2: cfg_file $3: line $4: newText
 ```

### add_before
 ```
add newtext before the matching line.
  - do nothing if already exist
  - insert at the 1st line if empty line is given
Note: do not use '|' in the line or newText since it is used
      as a sed deliminator.
$1: ip $2: cfg_file $3: line $4: newText
 ```

### delete_line()
 ```
delete the matching line
Note: do not use '|' in the line or newText since it is used
      as a sed deliminator.
$1: ip $2: cfg_file $3: line
 ```

### get_line
```
get the matching line
Note: do not use '|' in the line or newText since it is used
      as a sed deliminator.
$1: ip $2: cfg_file $3: line
```

## Functions: add/delete/update/get Openstack config

### add_config
```
add or update existing one.
$1:ip $2: cfg_file $3: section, $4: key, $5: value
```

### delete_config
```
delete a config
$1:ip $2: cfg_file $3: section, $4: key, $5: value
```

### get_config
```
get the existing value for the given key.
$1:ip $2: cfg_file $3: section, $4: key
```

### add_multi_opt_config
```
add by keeping existing one.
$1:ip $2: cfg_file $3: section, $4: key, $5: value
```

### get_multi_opt_config
```
get the existing value(comma seperated list) for the given key.
$1:ip $2: cfg_file $3: section, $4: key
```
