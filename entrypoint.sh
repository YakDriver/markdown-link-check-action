#!/usr/bin/env bash

set -eu

UV_THREADPOOL_SIZE=128

npm -g list --depth=1
echo "::endgroup::"

declare -a FIND_CALL
declare -a COMMAND_DIRS COMMAND_FILES
declare -a COMMAND_FILES

QUIET=""
VERBOSE=""
CONFIG=""
DIRECTORY=""
DEPTH=""
MODIFIED=""
BRANCH=""
PREFIX=""
FILE=""
EXTENSION=""

# Check if the first argument starts with '--'
if [[ $1 == --* ]]; then
   # Define the options
   OPTIONS=q:v:c:d:t:m:b:p:f:e
   LONGOPTS=quiet:,verbose:,config:,directory:,depth:,modified:,branch:,prefix:,file:,extension:

   # Parse the options
   PARSED=$(getopt --options=$OPTIONS --longoptions=$LONGOPTS --name "$0" -- "$@")
   if [[ $? -ne 0 ]]; then
      exit 2
   fi
   eval set -- "$PARSED"

   # Process the options
   while true; do
      case "$1" in
         -q|--quiet)
            QUIET="$2"
            shift 2
            ;;
         -v|--verbose)
            VERBOSE="$2"
            shift 2
            ;;
         -c|--config)
            CONFIG="$2"
            shift 2
            ;;
         -f|--directory)
            DIRECTORY="$2"
            shift 2
            ;;
         -t|--depth)
            DEPTH="$2"
            shift 2
            ;;
         -m|--modified)
            MODIFIED="$2"
            shift 2
            ;;
         -b|--branch)
            BRANCH="$2"
            shift 2
            ;;
         -p|--prefix)
            PREFIX="$2"
            shift 2
            ;;
         -f|--file)
            FILE="$2"
            shift 2
            ;;
         -e|--extension)
            EXTENSION="$2"
            shift 2
            ;;                        
         --)
            shift
            break
            ;;
         *)
            echo "Unrecognized option: $1"
            exit 3
            ;;
      esac
   done
else
   QUIET="$1"
   VERBOSE="$2"
   CONFIG="$3"
   DIRECTORY="$4"
   DEPTH="$5"
   MODIFIED="$6"
   BRANCH="$7"
   PREFIX="$8"

   if [ -z "$9" ]; then
      EXTENSION=".md"
   else
      EXTENSION="$9"
   fi
   FILE="${10}"
fi

if [ -f "$CONFIG" ]; then
   echo -e "Using markdown-link-check configuration file: $CONFIG"
else
   echo -e "Cannot find $CONFIG"
   echo -e "NOTE: See https://github.com/tcort/markdown-link-check#config-file-format to know more about"
   echo -e "customizing markdown-link-check by using a configuration file."
fi

FOLDERS=""
FILES=""

echo -e "QUIET: ${QUIET}"
echo -e "VERBOSE: ${VERBOSE}"
echo -e "DIRECTORY: ${DIRECTORY}"
echo -e "DEPTH: ${DEPTH}"
echo -e "MODIFIED: ${MODIFIED}"
echo -e "BRANCH: ${BRANCH}"
echo -e "PREFIX: ${PREFIX}"
echo -e "EXTENSION: ${EXTENSION}"
echo -e "FILE: ${FILE}"

handle_dirs () {

   IFS=', ' read -r -a DIRLIST <<< "$DIRECTORY"

   for index in "${!DIRLIST[@]}"
   do
      if [ ! -d "${DIRLIST[index]}" ]; then
         echo -e "ERROR [✖] Can't find the directory: ${DIRLIST[index]}"
         exit 2
      fi
      COMMAND_DIRS+=("${DIRLIST[index]}")
   done
   FOLDERS="${COMMAND_DIRS[*]}"

}

handle_files () {

   IFS=', ' read -r -a FILELIST <<< "$FILE"

   for index in "${!FILELIST[@]}"
   do
      if [ ! -f "${FILELIST[index]}" ]; then
         echo -e "ERROR [✖] Can't find the file: ${FILELIST[index]}"
         exit 2
      fi
      if [ "$index" == 0 ]; then
         COMMAND_FILES+=("-wholename ${FILELIST[index]}")
      else
         COMMAND_FILES+=("-o -wholename ${FILELIST[index]}")
      fi
   done
   FILES="${COMMAND_FILES[*]}"

}

check_errors () {

   if [ -e error.txt ] ; then
      if grep -q "ERROR:" error.txt; then
         echo -e "=========================> MARKDOWN LINK CHECK <========================="
         cat error.txt
         printf "\n"
         echo -e "========================================================================="
         exit 113
      else
         echo -e "=========================> MARKDOWN LINK CHECK <========================="
         printf "\n"
         echo -e "[✔] All links are good!"
         printf "\n"
         echo -e "========================================================================="
      fi
   else
      echo -e "All good!"
   fi

}

add_options () {

   if [ -f "$CONFIG" ]; then
      FIND_CALL+=('--config' "${CONFIG}")
   fi

   if [ "$QUIET" = "yes" ]; then
      FIND_CALL+=('-q')
   fi

   if [ "$VERBOSE" = "yes" ]; then
      FIND_CALL+=('-v')
   fi

}

check_additional_files () {

   if [ -n "$FILES" ]; then
      if [ "$DEPTH" -ne -1 ]; then
         FIND_CALL=('find' ${FOLDERS} '-type' 'f' '(' ${FILES} ')' '-not' '-path' './node_modules/*' '-maxdepth' "${DEPTH}" '-exec' 'markdown-link-check' '{}')
      else
         FIND_CALL=('find' ${FOLDERS} '-type' 'f' '(' ${FILES} ')' '-not' '-path' './node_modules/*' '-exec' 'markdown-link-check' '{}')
      fi

      add_options

      FIND_CALL+=(';')

      set -x
      "${FIND_CALL[@]}" &>> error.txt
      set +x

   fi

}

git config --global --add safe.directory /github/workspace

if [ -z "$EXTENSION" ]; then
   FOLDERS="."
else
   handle_dirs
fi

if [ -n "$FILE" ]; then
   handle_files
fi

if [ "$MODIFIED" = "yes" ]; then

   echo -e "BRANCH: ${BRANCH}"

   git config --global --add safe.directory '*'

   git fetch origin "${BRANCH}" --depth=1 > /dev/null
   MASTER_HASH=$(git rev-parse origin/"${BRANCH}")

   if [ -z "$FOLDERS" ]; then
      FOLDERS="."
   fi

   FIND_CALL=('markdown-link-check')

   add_options

   FOLDER_ARRAY=(${DIRECTORY//,/ })
   mapfile -t FILE_ARRAY < <( git diff --name-only --diff-filter=AM "$MASTER_HASH" -- "${FOLDER_ARRAY[@]}")

   for i in "${FILE_ARRAY[@]}"
      do
         if [ "${i##*.}" == "${EXTENSION#.}" ]; then
            FIND_CALL+=("${i}")
            COMMAND="${FIND_CALL[*]}"
            $COMMAND &>> error.txt || true
            unset 'FIND_CALL[${#FIND_CALL[@]}-1]'
         fi
      done

   check_additional_files

   check_errors

else

   if [ "${DEPTH}" -ne -1 ]; then
      FIND_CALL=('find' ${FOLDERS} '-name' "${PREFIX}"'*'"${EXTENSION}" '-not' '-path' './node_modules/*' '-maxdepth' "${DEPTH}" '-exec' 'markdown-link-check' '{}')
   else
      FIND_CALL=('find' ${FOLDERS} '-name' "${PREFIX}"'*'"${EXTENSION}" '-not' '-path' './node_modules/*' '-exec' 'markdown-link-check' '{}')
   fi

   add_options

   FIND_CALL+=(';')

   set -x
   "${FIND_CALL[@]}" &>> error.txt
   set +x

   check_additional_files

   check_errors

fi
