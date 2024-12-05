#!/bin/sh
ORIG_VERSION=18
TARGET_VERSION=19
ORIG_VERSION_2=18_0
TARGET_VERSION_2=19_0
ORIG_VERSION_3=180
TARGET_VERSION_3=190

LIST=`ls debian/control debian/orig-tar.sh debian/rules debian/patches/clang-analyzer-force-version.diff debian/patches/clang-format-version.diff debian/patches/python-clangpath.diff debian/patches/scan-build-clang-path.diff debian/patches/lldb-libname.diff debian/patches/fix-scan-view-path.diff debian/patches/lldb/lldb-addversion-suffix-to-llvm-server-exec.patch debian/patches/clang-tidy-run-bin.diff debian/patches/fix-scan-view-path.diff debian/README debian/patches/clang-analyzer-force-version.diff debian/patches/clang-tidy-run-bin.diff debian/tests/control debian/tests/integration-test-suite-test debian/unpack.sh debian/tests/cmake-test debian/patches/scan-build-py-fix-default-bin.diff`
for F in $LIST; do
    sed -i -e "s|$ORIG_VERSION_3|$TARGET_VERSION_3|g" $F
    sed -i -e "s|$ORIG_VERSION_2|$TARGET_VERSION_2|g" $F
    sed -i -e "s|$ORIG_VERSION|$TARGET_VERSION|g" $F
done

echo "once you copy the old version into a new branch"
echo "edit debian/rules"
echo "edit debian/control, update the VCS links"
echo "edit debian/control, update the source pkg name"
echo "edit debian/changelog, update the source pkg name"
echo "edit debian/unpack.sh, replace snapshot by the version"
echo "NOTE: the first version of the $ORIG_VERSION should be $ORIG_VERSION, not $ORIG_VERSION.0.0"
echo "edit https://github.com/opencollab/llvm-jenkins.debian.net/blob/master/pbuilder-hookdir/B22scan-build"
