set -e
ORIG_VERSION=19
MAJOR_VERSION=19 # 8.0.1
REV=`ls -1 *${ORIG_VERSION}_${MAJOR_VERSION}*~+*xz | tail -1|perl -ne 'print "$1\n" if /~\+(.*)\.orig/;'  | sort -ru`

VERSION=$REV

if test -z "$VERSION"; then
	echo "Could not find the version"
	exit 0
fi
LLVM_ARCHIVE=llvm-toolchain-${ORIG_VERSION}_$MAJOR_VERSION~+$VERSION.orig.tar.xz
echo "unpack of $LLVM_ARCHIVE"
tar Jxf $LLVM_ARCHIVE
cd llvm-toolchain-${ORIG_VERSION}_$MAJOR_VERSION~+$VERSION/

VER_FOUND=$(grep "LLVM_VERSION_MAJOR " cmake/Modules/LLVMVersion.cmake|awk '{print $2}'|cut -d\) -f1)
if test "${MAJOR_VERSION}" != "$VER_FOUND" -a "${MAJOR_VERSION}.0.0" != "$VER_FOUND" -a "${MAJOR_VERSION}.0.0git" != "$VER_FOUND" -a "${MAJOR_VERSION}git" != "$VER_FOUND"; then
    echo "Mismatch of version"
    echo "Expected $MAJOR_VERSION / Found $VER_FOUND"
    echo "Update unpack.sh"
    exit 1
fi

cp -R ../$ORIG_VERSION/debian .

export QUILT_PATCHES=debian/patches/

attempt=0
max_attempts=5

while [ $attempt -lt $max_attempts ]; do
    echo $attempt
    attempt=$((attempt+1))
    echo "Attempt $attempt of $max_attempts"

    # Attempt to apply patches without allowing fuzz
    output=$(quilt push -a --fuzz=0 || true 2>&1)

    echo "$output"

    # Check if the quilt push command failed due to a hunk failure
    if echo "$output" | grep -q "hunk FAILED"; then
        echo "Initial quilt push failed, trying without --fuzz=0..."
        output=$(quilt push || true 2>&1)
        echo "$output"
        # Check if the output contains a line indicating fuzz was applied
        if echo "$output" | grep -q "with fuzz"; then
            echo "Fuzz detected, refreshing patch..."
            quilt refresh
            cp -R debian/patches/* ../$ORIG_VERSION/debian/patches/
        fi
    else
        echo "Patches applied successfully."
        break # Exit the loop if patches were applied successfully
    fi
done

if [ $attempt -eq $max_attempts ]; then
    echo "Reached maximum attempt limit without successfully applying all patches."
fi
