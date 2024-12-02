#!/usr/bin/bash -eu

# Initial version:
# https://src.fedoraproject.org/rpms/redhat-rpm-config/blob/rawhide/f/brp-llvm-compile-lto-elf

CLANG_FLAGS=$@

if test -z $P_TO_LLVM; then
    echo "P_TO_LLVM isn't set"
    exit 1
fi

if test -z $NJOBS; then
    echo "NJOBS isn't set"
    exit 1
fi

if test -z $VERSION; then
    echo "VERSION isn't set"
    exit 1
fi

NCPUS=$NJOBS

check_convert_bitcode () {
  local file_name=$(realpath ${1})
  local file_type=$(file ${file_name})
  shift
  CLANG_FLAGS="$@"

  if [[ "${file_type}" == *"LLVM IR bitcode"* ]]; then
    # check for an indication that the bitcode was
    # compiled with -flto
    ${P_TO_LLVM}/debian/tmp/usr/bin/llvm-bcanalyzer-${VERSION} -dump ${file_name} | grep -xP '.*\-flto((?!-fno-lto).)*' 2>&1 > /dev/null
    if [ $? -eq 0 ]; then
      echo "Compiling LLVM bitcode file ${file_name}."
      ${P_TO_LLVM}/debian/tmp/usr/bin/clang-${VERSION} -fno-lto -opaque-pointers -Wno-unused-command-line-argument \
        -x ir ${file_name} -c -o ${file_name}
    fi
  elif [[ "${file_type}" == *"current ar archive"* ]]; then
    echo "Unpacking ar archive ${file_name} to check for LLVM bitcode components."
    # create archive stage for objects
    local archive_stage=$(mktemp -d)
    local archive=${file_name}
    pushd ${archive_stage}
    ar x ${archive}
    for archived_file in $(find -not -type d); do
      check_convert_bitcode ${archived_file} ${CLANG_FLAGS}
      echo "Repacking ${archived_file} into ${archive}."
      ${P_TO_LLVM}/debian/tmp/usr/bin/llvm-ar-${VERSION} r ${archive} ${archived_file}
    done
    popd
  fi
}

echo "Checking for LLVM bitcode artifacts"
export -f check_convert_bitcode
find "$P_TO_LLVM/debian/" -type f -name "*.[ao]" -print0 | \
  xargs -0 -r -n1 -P$NCPUS bash -c "check_convert_bitcode \$@ $CLANG_FLAGS" ARG0
