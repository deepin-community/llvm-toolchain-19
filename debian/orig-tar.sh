#!/bin/sh
# This script will create the following tarball:
# llvm-toolchain-XX_XX\~+20200120101212+de4b2a7fad6.orig.tar.xz

set -e

# commands:
#  sh 9/debian/orig-tar.sh release/9.x
#  sh 9/debian/orig-tar.sh 9.0.0 rc3
#  sh 9/debian/orig-tar.sh 9.0.1 rc3
# Stable release
#  sh 9/debian/orig-tar.sh 9.0.0 9.0.0


# To create an rc1 release:
# sh 9/debian/orig-tar.sh release/9.x
CURRENT_PATH=$(pwd)
EXPORT_PATH=$(pwd)

if test -n "${JENKINS_HOME}"; then
    # For apt.llvm.org, reuse the same repo
    echo "Built from Jenkins. Will export the repo in $HOME/"
    EXPORT_PATH="$HOME/"
fi

GIT_BASE_URL=https://github.com/llvm/llvm-project
GIT_TOOLCHAIN_CHECK=https://github.com/opencollab/llvm-toolchain-integration-test-suite.git

reset_repo ()
{
    cd $1
    git clean -qfd
    git checkout .
    git remote update > /dev/null
    git reset --hard origin/main > /dev/null
    git clean -qfd
    git checkout main > /dev/null
    git pull
    cd -
}

PATH_DEBIAN="$(pwd)/$(dirname $0)/../"
cd "$PATH_DEBIAN"

git stash && git pull && git stash apply || true

MAJOR_VERSION=$(dpkg-parsechangelog | sed -rne "s,^Version: 1:([0-9]+).*,\1,p")
if test -z "$MAJOR_VERSION"; then
    echo "Could not detect the major version"
    exit 1
fi

CURRENT_VERSION=$(dpkg-parsechangelog | sed -rne "s,^Version: 1:([0-9.]+)(~|-)(.*),\1,p")
if test -z "$CURRENT_VERSION"; then
    echo "Could not detect the full version"
    exit 1
fi

cd - &> /dev/null
echo "MAJOR_VERSION=$MAJOR_VERSION / CURRENT_VERSION=$CURRENT_VERSION"
if test -n "$1"; then
# https://github.com/llvm/llvm-project/tree/release/9.x
# For example: sh 4.0/debian/orig-tar.sh release/9.x
    BRANCH=$1
    if ! echo "$1"|grep -q release/; then
        # The first argument is NOT a branch, means that it is a stable release
        FINAL_RELEASE=true
        EXACT_VERSION=$1
    fi
else
    # No argument, we need trunk
    cd "$PATH_DEBIAN"
    SOURCE=$(dpkg-parsechangelog |grep ^Source|awk '{print $2}')
    cd - &> /dev/null
    if test "$SOURCE" != "llvm-toolchain-snapshot"; then
       echo "Checkout of the main is only available for llvm-toolchain-snapshot"
       exit 1
    fi
    BRANCH="main"
fi

if test -n "$1" -a -n "$2"; then
# https://github.com/llvm/llvm-project/releases/tag/llvmorg-9.0.0
# For example: sh 4.0/debian/orig-tar.sh 4.0.1 rc3
# or  sh 9/debian/orig-tar.sh 9.0.0
    TAG=$2
    RCRELEASE="true"
    EXACT_VERSION=$1
fi

# Update or retrieve the repo
mkdir -p git-archive
cd git-archive
if test -d $EXPORT_PATH/llvm-project; then
    echo "Updating repo in $EXPORT_PATH/llvm-project"
    # Update it
    reset_repo $EXPORT_PATH/llvm-project
else
    # Download it
    echo "Cloning the repo in $EXPORT_PATH/llvm-project"
    git clone $GIT_BASE_URL $EXPORT_PATH/llvm-project
fi

if test -d $EXPORT_PATH/llvm-toolchain-integration-test-suite; then
    echo "Updating repo in $EXPORT_PATH/llvm-toolchain-integration-test-suite"
    # Update it
    reset_repo $EXPORT_PATH/llvm-toolchain-integration-test-suite
else
    echo "Clone llvm-toolchain-integration-test-suite into $EXPORT_PATH/llvm-toolchain-integration-test-suite"
    git clone $GIT_TOOLCHAIN_CHECK $EXPORT_PATH/llvm-toolchain-integration-test-suite
fi

cd $EXPORT_PATH/llvm-project
if test -z  "$TAG" -a -z "$FINAL_RELEASE"; then
    # Building a branch
    git checkout $BRANCH
    git reset --hard origin/$BRANCH
    if test $BRANCH != "main"; then
        VERSION=$(echo $BRANCH|cut -d/ -f2|cut -d. -f1)
        if ! echo "$MAJOR_VERSION"|grep -q "$VERSION"; then
            echo "mismatch in version: Dir=$MAJOR_VERSION Provided=$VERSION"
            exit 1
        fi
    else
        # No argument, take main. So, it can only be snapshot
        VERSION=$MAJOR_VERSION
        MAJOR_VERSION=snapshot
    fi
    if test $MAJOR_VERSION != "snapshot"; then
        # When upstream released X, they will update X to have X.0.1
        # In general, in Debian, we will keep X until X.0.1 is released (or rc in experimental)
        # However, on apt.llvm.org, we will update the version to have X.0.1
        # This code is doing that.
        CURRENT_VERSION="$(grep -oP 'set\(\s*LLVM_VERSION_(MAJOR|MINOR|PATCH)\s\K[0-9]+' cmake/Modules/LLVMVersion.cmake | paste -sd '.')"
    fi
    # the + is here to make sure that this version is considered more recent than the svn
    # dpkg --compare-versions 10~svn374977-1~exp1 lt 10~+2019-svn374977-1~exp1
    # to verify that
    VERSION="${CURRENT_VERSION}~++$(date +'%Y%m%d%I%M%S')+$(git log -1 --pretty=format:'%h')"
    echo "CURRENT = ${CURRENT_VERSION}"
else

    if ! echo "$EXACT_VERSION"|grep -q "$MAJOR_VERSION"; then
        echo "Mismatch in version: Dir=$MAJOR_VERSION Provided=$EXACT_VERSION"
        exit 1
    fi
    git_tag="llvmorg-$EXACT_VERSION"
    VERSION=$EXACT_VERSION
    if test -n "$TAG"; then
        git_tag="$git_tag-$TAG"
        VERSION="$VERSION~+$TAG"
    fi

    git checkout "$git_tag" > /dev/null

fi

# cleanup
rm -rf */www/ build/ build-llvm/

cd ../
BASE="llvm-toolchain-${MAJOR_VERSION}_${VERSION}"
FILENAME="${BASE}.orig.tar.xz"
cp -R llvm-toolchain-integration-test-suite llvm-project/integration-test-suite
# Argument to compress faster (for the cost of time)
export XZ_OPT="-4 -T$(nproc)"
echo "Compressing to $FILENAME"
time tar Jcf $CURRENT_PATH/"$FILENAME" --exclude .git --exclude .gitattributes --exclude .git-blame-ignore-revs --exclude .gitignore --exclude .github --exclude build-llvm --transform="s|llvm-project|$BASE|" -C $EXPORT_PATH llvm-project
rm -rf llvm-project/integration-test-suite

export DEBFULLNAME="Sylvestre Ledru"
export DEBEMAIL="sylvestre@debian.org"
cd "$PATH_DEBIAN"

if test -z "$DISTRIBUTION"; then
    DISTRIBUTION="experimental"
fi

if test -n "$RCRELEASE" -o -n "$BRANCH"; then
    EXTRA_DCH_FLAGS="--force-bad-version --allow-lower-version"
fi

dch $EXTRA_DCH_FLAGS --distribution $DISTRIBUTION --newversion 1:"$VERSION"-1~exp1 "New snapshot release"

exit 0
