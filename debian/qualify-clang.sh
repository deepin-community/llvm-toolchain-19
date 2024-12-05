#!/bin/bash
# Stop at the first error
set -e
if ! test -d debian/; then
    echo "$0: Could not find the debian/ directory"
    exit 1
fi
VERSION=$(dpkg-parsechangelog | sed -rne "s,^Version: 1:([0-9]+).*,\1,p")
DETAILED_VERSION=$(dpkg-parsechangelog |  sed -rne "s,^Version: 1:([0-9.]+)(~|-)(.*),\1\2\3,p")
DEB_HOST_ARCH=$(dpkg-architecture -qDEB_HOST_ARCH)

LIST="libomp5-${VERSION}_${DETAILED_VERSION}_amd64.deb libomp-${VERSION}-dev_${DETAILED_VERSION}_amd64.deb lldb-${VERSION}_${DETAILED_VERSION}_amd64.deb python3-lldb-${VERSION}_${DETAILED_VERSION}_amd64.deb python3-clang-${VERSION}_${DETAILED_VERSION}_amd64.deb libllvm${VERSION}_${DETAILED_VERSION}_amd64.deb llvm-${VERSION}-dev_${DETAILED_VERSION}_amd64.deb liblldb-${VERSION}-dev_${DETAILED_VERSION}_amd64.deb  libclang1-${VERSION}_${DETAILED_VERSION}_amd64.deb  libclang-common-${VERSION}-dev_${DETAILED_VERSION}_all.deb  llvm-${VERSION}_${DETAILED_VERSION}_amd64.deb  liblldb-${VERSION}_${DETAILED_VERSION}_amd64.deb  llvm-${VERSION}-runtime_${DETAILED_VERSION}_amd64.deb lld-${VERSION}_${DETAILED_VERSION}_amd64.deb libfuzzer-${VERSION}-dev_${DETAILED_VERSION}_amd64.deb libclang-${VERSION}-dev_${DETAILED_VERSION}_amd64.deb libc++-${VERSION}-dev_${DETAILED_VERSION}_amd64.deb libc++abi-${VERSION}-dev_${DETAILED_VERSION}_amd64.deb libc++1-${VERSION}_${DETAILED_VERSION}_amd64.deb libc++abi1-${VERSION}_${DETAILED_VERSION}_amd64.deb clang-${VERSION}_${DETAILED_VERSION}_amd64.deb llvm-${VERSION}-tools_${DETAILED_VERSION}_amd64.deb clang-tools-${VERSION}_${DETAILED_VERSION}_amd64.deb clangd-${VERSION}_${DETAILED_VERSION}_amd64.deb libclang-cpp${VERSION}_${DETAILED_VERSION}_amd64.deb clang-tidy-${VERSION}_${DETAILED_VERSION}_amd64.deb libclang-cpp${VERSION}-dev_${DETAILED_VERSION}_amd64.deb libclc-${VERSION}_${DETAILED_VERSION}_all.deb libclc-${VERSION}-dev_${DETAILED_VERSION}_all.deb llvm-${VERSION}-linker-tools_${DETAILED_VERSION}_amd64.deb libunwind-${VERSION}_${DETAILED_VERSION}_amd64.deb libunwind-${VERSION}-dev_${DETAILED_VERSION}_amd64.deb libmlir-${VERSION}_${DETAILED_VERSION}_amd64.deb libmlir-${VERSION}-dev_${DETAILED_VERSION}_amd64.deb libclang-rt-${VERSION}-dev_${DETAILED_VERSION}_amd64.deb libclang-rt-${VERSION}-dev-wasm32_${DETAILED_VERSION}_all.deb libclang-rt-${VERSION}-dev-wasm64_${DETAILED_VERSION}_all.deb libc++abi-${VERSION}-dev-wasm32_${DETAILED_VERSION}_all.deb libc++-${VERSION}-dev-wasm32_${DETAILED_VERSION}_all.deb libpolly-${VERSION}-dev_${DETAILED_VERSION}_amd64.deb  bolt-${VERSION}_${DETAILED_VERSION}_amd64.deb libbolt-${VERSION}-dev_${DETAILED_VERSION}_amd64.deb flang-${VERSION}_${DETAILED_VERSION}_amd64.deb libflang-${VERSION}-dev_${DETAILED_VERSION}_amd64.deb libllvmlibc-${VERSION}-dev_${DETAILED_VERSION}_amd64.deb "

echo "To install everything:"
echo "sudo apt --purge remove 'libomp5-*' 'libc++*dev' 'libc++*' 'python3-lldb-*' 'libunwind-*' 'libclc-*' 'libclc-*dev' 'libmlir-*'"
echo "sudo dpkg -i $LIST"
L=""
for f in $LIST; do
    L="$L $(echo $f|cut -d_ -f1)"
done
echo "or"
echo "apt-get install $L"

if test ! -f /usr/bin/llvm-config-$VERSION; then
    echo "Install llvm-$VERSION & llvm-$VERSION-dev"
    exit 1
fi
if test ! -f /usr/lib/llvm-$VERSION/lib/libLLVM-$VERSION.so; then
    echo "Install llvm-$VERSION-dev"
    exit 1
fi

echo "Testing llvm-$VERSION and llvm-$VERSION-dev ..."
llvm-config-$VERSION --link-shared --libs &> /dev/null

if llvm-config-$VERSION --cxxflags | grep " \-W"; then
    echo "llvm-config should not export -W warnings"
    exit 1
fi

# Test https://bugs.llvm.org/show_bug.cgi?id=40059
nm /usr/lib/llvm-$VERSION/lib/libLLVMBitWriter.a &> foo.log
if grep "File format not recognized" foo.log; then
    echo "nm libLLVMBitWriter.a contains 'File format not recognized'"
    exit 1
fi

# Test #995684
if test ! -f /usr/share/man/man1/llc-$VERSION.1.gz; then
    echo "llvm manpage are missing (using llc as an example)"
    exit 1
fi

if test ! -f /usr/bin/scan-build-$VERSION; then
    echo "Install clang-tools-$VERSION"
    exit 1
fi
echo "Testing clang-tools-$VERSION ..."

echo '
void test() {
  int x;
  x = 1; // warn
}
'> foo.c

# Ignore if gcc isn't available
scan-build-$VERSION -o scan-build gcc -c foo.c &> /dev/null || true
scan-build-$VERSION -o scan-build clang-$VERSION -c foo.c &> /dev/null
scan-build-$VERSION --exclude non-existing/ --exclude /tmp/ -v clang-$VERSION -c foo.c &> /dev/null
scan-build-$VERSION --exclude $(realpath $(pwd)) -v clang-$VERSION -c foo.c &> foo.log
if ! grep -q -E "scan-build: 0 bugs found." foo.log; then
    echo "scan-build --exclude didn't ignore the defect"
    exit 42
fi
rm -rf scan-build

if test ! -f /usr/bin/clang-tidy-$VERSION; then
    echo "Install clang-tidy-$VERSION"
    exit 1
fi

echo 'namespace mozilla {
namespace dom {
void foo();
}
}
' > foo.cpp
clang-tidy-$VERSION -checks='modernize-concat-nested-namespaces' foo.cpp -extra-arg=-std=c++17 &> foo.log
if ! grep -q "nested namespaces can " foo.log; then
    echo "Clang-tidy didn't detect the issue"
    cat foo.log
    exit 1
fi


rm -rf cmaketest && mkdir cmaketest
cat > cmaketest/CMakeLists.txt <<EOF
cmake_minimum_required(VERSION 3.7)
project(SanityCheck)
add_library(MyLibrary foo.cpp)
EOF
mkdir cmaketest/standard
cp foo.cpp cmaketest/
cd cmaketest/standard
# run with cmake
CXX=clang-$VERSION cmake -DCMAKE_EXPORT_COMPILE_COMMANDS=ON .. > /dev/null

clang-tidy-$VERSION -checks='modernize-concat-nested-namespaces' ../foo.cpp -extra-arg=-std=c++17 -fix &> foo.log
if ! grep -q "namespace mozilla::dom" ../foo.cpp; then
    echo "clang-tidy autofix didn't work"
    cat foo.log
    exit 1
fi
cd - &> /dev/null
rm -rf cmaketest

echo "Testing clangd-$VERSION ..."

echo '{
  "jsonrpc": "2.0",
  "id": 0,
  "method": "initialize",
  "params": {
    "capabilities": {
      "textDocument": {
        "completion": {
          "completionItem": {
            "snippetSupport": true
          }
        }
      }
    },
    "trace": "off"
  }
}
---
{
    "jsonrpc": "2.0",
    "method": "textDocument/didOpen",
    "params": {
        "textDocument": {
            "uri": "test:///main.cpp",
            "languageId": "cpp",
            "version": 1,
            "text": "int func_with_args(int a, int b);\nint main() {\nfunc_with\n}"
        }
    }
}
---
{
    "jsonrpc": "2.0",
    "id": 1,
    "method": "textDocument/completion",
    "params": {
        "textDocument": {
            "uri": "test:///main.cpp"
        },
        "position": {
            "line": 2,
            "character": 7
         }
     }
}
---
{
    "jsonrpc": "2.0",
    "id": 4,
    "method": "shutdown"
}
---
{
    "jsonrpc": "2.0",
    "method": "exit"
}
' > a.json

clangd-$VERSION -lit-test -pch-storage=memory < a.json &> foo.log
if ! grep -q '"insertText": "func_with_args(${1:int a}, ${2:int b})",' foo.log; then
    echo "clangd didn't export what we were expecting"
    cat foo.log
    exit 1
fi

echo 'namespace mozilla {
namespace dom {
void foo();

int fonction_avec_args(int a, float b);
int main() {
fonction_avec_args
}

}
}
' > foo.cpp
content=$(sed ':a;N;$!ba;s/\n/\\n/g' foo.cpp)
echo '{
  "jsonrpc": "2.0",
  "id": 0,
  "method": "initialize",
  "params": {
    "capabilities": {
      "textDocument": {
        "completion": {
          "completionItem": {
            "snippetSupport": true
          }
        }
      }
    },
    "trace": "off"
  }
}
---
{
    "jsonrpc": "2.0",
    "method": "textDocument/didOpen",
    "params": {
        "textDocument": {
            "uri": "file:///'$(pwd)'/cmaketest/foo.cpp",
            "languageId": "cpp",
            "version": 1,
            "text": "'$content'"
        }
    }
}
---
{
    "jsonrpc": "2.0",
    "id": 1,
    "method": "textDocument/completion",
    "params": {
        "textDocument": {
             "uri": "file:///'$(pwd)'/cmaketest/foo.cpp"
        },
        "position": {
             "line": 6,
             "character": 18
         }
    }
}
---
{
    "jsonrpc": "2.0",
    "id": 4,
    "method": "shutdown"
}
---
{
    "jsonrpc": "2.0",
    "method": "exit"
}
' > a.json

rm -rf cmaketest && mkdir cmaketest
cat > cmaketest/CMakeLists.txt <<EOF
cmake_minimum_required(VERSION 3.7)
project(SanityCheck)
add_library(MyLibrary foo.cpp)
EOF
mkdir cmaketest/standard
cp foo.cpp cmaketest/
cp a.json cmaketest/standard
cd cmaketest/standard

# run with cmake

CXX=clang-$VERSION cmake -DCMAKE_EXPORT_COMPILE_COMMANDS=ON .. > /dev/null
# TODO this test is useless as it doesn't leverage foo.cpp or the compiledb
clangd-$VERSION -lit-test -pch-storage=memory < a.json &> foo.log
if ! grep -q '"insertText": "fonction_avec_args(${1:int a}, ${2:float b})",' foo.log; then
    echo "clangd didn't export what we were expecting"
    cat foo.log
    exit 1
fi
cd - &> /dev/null
rm -rf cmaketest


echo "Testing clang-$VERSION ..."

rm -f foo.log
echo 'int main() {return 0;}' > foo.c
clang-$VERSION foo.c

echo '#include <stdio.h>
int main() {
printf("lli foo");
return 0;
}' > foo.c
clang-$VERSION -S -emit-llvm foo.c
llc-$VERSION foo.ll
if ! lli-$VERSION foo.ll|grep -q "lli foo"; then
    echo "Not lli correct output"
    lli-$VERSION foo.ll
    exit 1
fi
opt-$VERSION -S -O3 foo.ll -o opt.ll
if ! lli-$VERSION opt.ll|grep -q "lli foo"; then
    echo "Not lli correct output after opt"
    lli-$VERSION opt.ll
    exit 1
fi

clang-$VERSION -O3 -emit-llvm foo.c -c -o foo.bc
chmod +x foo.bc
# only run if the binfmt is installed correctly
if grep -q "enabled" /proc/sys/fs/binfmt_misc/llvm-${VERSION}-runtime.binfmt; then
    if ! ./foo.bc|grep -q "lli foo"; then
        echo "executing ./foo.bc failed"
        ./foo.bc || true
        #exit 1
    fi

    clang-$VERSION -O3 -emit-llvm foo.c -c -o foo.bc
    chmod +x foo.bc
    if ! ./foo.bc|grep -q "lli foo"; then
        echo "executing ./foo.bc failed"
        ./foo.bc || true
        #exit 1
    fi
fi # binfmt test

if ! llvm-dis-$VERSION < foo.bc|grep -q "lli foo"; then
    echo "llvm assembly code failed"
    llvm-dis-$VERSION < foo.bc
    exit 1
fi

# test if this is built with CURL
llvm-debuginfod-find-$VERSION --executable=1 5d016364c1cb69dd &> foo.log || true
if grep -q "No working HTTP" foo.log; then
    echo "llvm-debuginfod-find isn't built with curl support"
    exit 1
fi

echo '#include <stddef.h>' > foo.c
clang-$VERSION -c foo.c

# https://bugs.launchpad.net/bugs/1810860
clang-$VERSION -dumpversion &> foo.log
if grep -q 4.2.1 foo.log; then
    echo "dumpversion still returns 4.2.1"
    echo "it should return the clang version"
    cat foo.log
    exit 1
fi

# bug 903709
echo '#include <stdatomic.h>
void increment(atomic_size_t *arg) {
    atomic_fetch_add(arg, 1);
} ' > foo.c

clang-$VERSION -v -c foo.c &> /dev/null

echo "#include <fenv.h>" > foo.cc
NBLINES=$(clang++-$VERSION -P -E foo.cc|grep .|wc -l)
if test $NBLINES -lt 60; then
    echo "Error: more than 60 non-empty lines should be returned"
    echo "output:"
    clang++-$VERSION -P -E foo.cc
    exit 42
fi

if [ $DEB_HOST_ARCH == "amd64" -o $DEB_HOST_ARCH == "i386" ]; then
    # Fails on arm64 with
    # /usr/lib/llvm-10/lib/clang/10.0.0/include/mmintrin.h:33:5: error: use of undeclared identifier '__builtin_ia32_emms'; did you mean '__builtin_isless'?
    echo '#include <emmintrin.h>' > foo.cc
    clang++-$VERSION -c foo.cc
fi

# Bug 913213
echo '#include <limits.h>' | clang-$VERSION -E - > /dev/null

# Bug launchpad #1488254
echo '
#include <string>
std::string hello = "Hello, world!\n";
' > foo.cc

echo '
#include <string>
#include <iostream>
extern std::string hello;
int main() {
    std::cout << hello;
    return 0;
} ' > bar.cc

g++ -c foo.cc && g++ foo.o bar.cc && ./a.out  > /dev/null || true
clang++-$VERSION -c foo.cc && clang++-$VERSION foo.o bar.cc && ./a.out  > /dev/null
g++ -c foo.cc && clang++-$VERSION foo.o bar.cc && ./a.out  > /dev/null || true
clang++-$VERSION -c foo.cc -fPIC && g++ foo.o bar.cc && ./a.out > /dev/null || true

## test z3
echo '
void clang_analyzer_eval(int);
void testBitwiseRules(unsigned int a, int b) {
  clang_analyzer_eval((1 & a) <= 1); // expected-warning{{TRUE}}
  // with -analyzer-constraints=z3, it can tell that it is FALSE
  // without the option, it is unknown
  clang_analyzer_eval((b | -2) >= 0); // expected-warning{{FALSE}}
}
' > foo.c

clang-$VERSION -cc1  -analyze -analyzer-constraints=range -analyzer-checker=core,debug.ExprInspection -analyzer-constraints=z3 foo.c &> foo.log || true
if ! grep -q "error: analyzer constraint manager 'z3' is only available if LLVM was built with -DLLVM_ENABLE_Z3_SOLVER=ON" foo.log; then
    # Should work
    clang-$VERSION -cc1  -analyze -analyzer-constraints=range -analyzer-checker=core,debug.ExprInspection -verify -analyzer-config eagerly-assume=false -analyzer-constraints=z3 foo.c
    clang-$VERSION -cc1  -analyze -analyzer-constraints=range -analyzer-checker=core,debug.ExprInspection -analyzer-constraints=z3 foo.c &> foo.log
    if ! grep -q "2 warnings generated." foo.log; then
        echo "Should find 2 warnings"
        exit 1
    fi
else
    echo "z3 support not available"
fi

# Should fail
clang-$VERSION -cc1  -analyze -analyzer-constraints=range -analyzer-checker=core,debug.ExprInspection -verify -analyzer-config eagerly-assume=false foo.c &> foo.log || true
if grep -q "File a.c Line 7: UNKNOWN" foo.log; then
    echo "Should fail without -analyzer-constraints=z3"
    exit 1
fi

clang-$VERSION -cc1  -analyze -analyzer-constraints=range -analyzer-checker=core,debug.ExprInspection foo.c &> foo.log
if ! grep -q "warnings generated." foo.log; then
    echo "Should find at least 2 warnings"
    exit 1
fi

# bug 827866
echo 'bool testAndSet(void *atomic) {
    return __atomic_test_and_set(atomic, __ATOMIC_SEQ_CST);
}'> foo.cpp
clang++-$VERSION -c -target aarch64-linux-gnu foo.cpp
if ! file foo.o 2>&1 | grep -i -q "aarch64"; then
    echo "Could not find the string 'aarch64' in the output of file. Output:"
    file foo.o
    exit 42
fi

clang-$VERSION --target=arm-linux-gnueabihf -dM -E -xc - < /dev/null &> foo.log
if ! grep -q "#define __ARM_ARCH 7" foo.log; then
    # bug 930008
    echo "The target arch for arm should be v7"
    cat foo.log
    exit 42
fi

echo '
#include <string.h>
int
main ()
{
  (void) strcat;
  return 0;
}' > foo.c
clang-$VERSION -c foo.c

echo '#include <errno.h>
int main() {} ' > foo.c
clang-$VERSION foo.c

echo '#include <chrono>
int main() { }' > foo.cpp
clang++-$VERSION -std=c++11 foo.cpp

echo "Testing linking clang-cpp ..."

clang-$VERSION -lclang-cpp$VERSION -v foo.cpp -o o &> /dev/null || true
if ! ldd o 2>&1|grep -q  libclang-cpp; then
	echo "Didn't link against libclang-cpp$VERSION"
	exit 42
fi
./o > /dev/null

check_symlink() {
    P="/usr/lib/llvm-$VERSION/lib/$1"
    if test ! -e $P; then
        echo "invalid symlink $P"
        ls -al $P
        exit 1
    fi
}

# check_symlink "libclang-cpp.so.$VERSION" why is that one needed?
check_symlink "libclang-$VERSION.so"
check_symlink "libclang.so"

if [ $DEB_HOST_ARCH != "i386" ]; then
    echo "Testing python clang ..."
    python3 -c 'from ctypes import *; import clang.cindex; config = clang.cindex.Config(); verfunc = config.lib.clang_getClangVersion; verfunc.restype = c_char_p ; print(verfunc())'
fi

echo "Testing code coverage ..."

echo '#include <stdio.h>
int main() {
if (1==1) {
	printf("true");
}else{
	printf("false");
	return 42;
}
return 0;}' > foo.c
clang-$VERSION --coverage foo.c -o foo
./foo > /dev/null
if test ! -f foo.gcno; then
    echo "Coverage failed";
fi

echo "#include <iterator>" > foo.cpp
clang++-$VERSION -c foo.cpp

echo "Testing linking ..."
if test ! -f /usr/lib/llvm-$VERSION/bin/../lib/LLVMgold.so; then
    echo "Install llvm-$VERSION-dev"
    exit 1
fi

echo '#include <stdio.h>
int main() {
if (1==1) {
  printf("true");
}else{
  printf("false");
  return 42;
}
return 0;}' > foo.c
rm foo bar.cc

clang-$VERSION -flto foo.c -opaque-pointers -o foo
./foo > /dev/null

clang-$VERSION -fuse-ld=gold foo.c -o foo
./foo > /dev/null

# test thinlto
echo "int foo(void) {	return 0; }"> foo.c
echo "int foo(void); int main() {foo();	return 0;}">main.c
clang-$VERSION -flto=thin -O2 foo.c main.c -o foo
./foo > /dev/null
clang-$VERSION -flto=thin -O2 foo.c main.c -c

# understand LTO files
# see https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=919020
clang-$VERSION foo.c -flto -c
file foo.o|grep -q "LLVM IR bitcode"
if ! llvm-nm-$VERSION foo.o|grep -q "T foo"; then
    echo "gold linker isn't understood"
    exit 1
fi

echo "Testing lld-$VERSION ..."

if test ! -f /usr/bin/lld-$VERSION; then
    echo "Install lld-$VERSION"
    exit 1
fi
clang-$VERSION -fuse-ld=lld -O2 foo.c main.c -o foo
./foo > /dev/null

if ls -al1 /usr/bin/ld.lld|grep -q ld.lld-$VERSION; then
# https://bugs.llvm.org/show_bug.cgi?id=40659
# -fuse-ld=lld will call lld
# Mismatch of version can fail the check
# so, only run it when /usr/bin/lld == $VERSION
    clang-$VERSION -fuse-ld=lld -flto -O2 foo.c main.c -o foo
    ./foo > /dev/null
fi

clang-$VERSION -fuse-ld=lld-$VERSION -O2 foo.c main.c -o foo
./foo > /dev/null

# Bug 916975
file foo &> foo.log
if ! grep -q "BuildID" foo.log; then
    echo "BuildID isn't part of the generated binary (lld generation)"
    exit 1
fi
# Bug 916975
clang-$VERSION -O2 foo.c main.c -o foo2
file foo2 &> foo2.log
if ! grep -q "BuildID" foo2.log; then
    echo "BuildID isn't part of the generated binary (ld generation)"
    exit 1
fi

strip foo2
file foo2 &> foo2.log
if ! grep -q "BuildID" foo2.log; then
    echo "BuildID isn't part of the generated binary (stripped)"
    exit 1
fi
rm foo2 foo2.log

if test ! -f /usr/lib/llvm-$VERSION/bin/llvm-symbolizer; then
    echo "Install llvm-$VERSION"
    exit 1
fi

echo "vzeroupper" | llvm-exegesis-$VERSION -mode=uops -snippets-file=- &> foo.log || true
if grep -q -E "(built without libpfm|cannot initialize libpfm)" foo.log; then
    echo "could not run llvm-exegesis correctly"
    cat foo.log|head
    exit 42
fi

if test ! -f /usr/lib/llvm-$VERSION/lib/libFuzzer.a; then
    echo "Install libfuzzer-$VERSION-dev";
    exit -1;
fi

echo "Testing libfuzzer-$VERSION-dev ..."

cat << EOF > test_fuzzer.cc
#include <stdint.h>
#include <stddef.h>
extern "C" int LLVMFuzzerTestOneInput(const uint8_t *data, size_t size) {
  if (size > 0 && data[0] == 'H')
    if (size > 1 && data[1] == 'I')
       if (size > 2 && data[2] == '!')
       __builtin_trap();
  return 0;
}

EOF

clang++-$VERSION -fsanitize=address -fsanitize-coverage=edge,trace-pc test_fuzzer.cc /usr/lib/llvm-$VERSION/lib/libFuzzer.a
if ! ./a.out 2>&1 | grep -q -E "(Test unit written|PreferSmall)"; then
    echo "fuzzer failed"
    exit 42
fi

clang++-$VERSION -fsanitize=address,fuzzer test_fuzzer.cc
if ! ./a.out 2>&1 | grep -q "libFuzzer: deadly signal"; then
    echo "fuzzer failed"
fi

echo 'int main(int argc, char **argv) {
  int *array = new int[100];
  delete [] array;
  return array[argc];  // BOOM
}' > foo.cpp
clang++-$VERSION -O1 -g -fsanitize=address -fno-omit-frame-pointer foo.cpp
ASAN_OPTIONS=verbosity=1 ./a.out &> foo.log || true
if ! grep -q "Init done" foo.log; then
    echo "asan verbose mode failed"
    cat foo.log
    exit 42
fi

# See also https://bugs.llvm.org/show_bug.cgi?id=39514 why
# /usr/bin/llvm-symbolizer-7 doesn't work
ASAN_OPTIONS=verbosity=2:external_symbolizer_path=/usr/lib/llvm-$VERSION/bin/llvm-symbolizer ./a.out &> foo.log || true
if ! grep -q "Using llvm-symbolizer" foo.log; then
    echo "could not find llvm-symbolizer path"
    cat foo.log
    exit 42
fi
if ! grep -q "new\[\](unsigned" foo.log; then
    echo "could not symbolize correctly"
    cat foo.log
    exit 42
fi

if ! grep -q "foo.cpp:3:3" foo.log; then
    echo "could not symbolize correctly"
    cat foo.log
    exit 42
fi
./a.out &> foo.log || true
if ! grep -q "new\[\](unsigned" foo.log; then
    echo "could not symbolize correctly"
    cat foo.log
    exit 42
fi

if ! grep -q "foo.cpp:3:3" foo.log; then
    echo "could not symbolize correctly"
    cat foo.log
    exit 42
fi

# Example from https://github.com/google/fuzzing/blob/master/tutorial/libFuzzerTutorial.md
# coverage fuzzing
cat << EOF > StandaloneFuzzTargetMain.c
#include <assert.h>
#include <stdio.h>
#include <stdlib.h>

extern int LLVMFuzzerTestOneInput(const unsigned char *data, size_t size);
__attribute__((weak)) extern int LLVMFuzzerInitialize(int *argc, char ***argv);
int main(int argc, char **argv) {
  fprintf(stderr, "StandaloneFuzzTargetMain: running %d inputs\n", argc - 1);
  if (LLVMFuzzerInitialize)
    LLVMFuzzerInitialize(&argc, &argv);
  for (int i = 1; i < argc; i++) {
    fprintf(stderr, "Running: %s\n", argv[i]);
    FILE *f = fopen(argv[i], "r");
    assert(f);
    fseek(f, 0, SEEK_END);
    size_t len = ftell(f);
    fseek(f, 0, SEEK_SET);
    unsigned char *buf = (unsigned char*)malloc(len);
    size_t n_read = fread(buf, 1, len, f);
    fclose(f);
    assert(n_read == len);
    LLVMFuzzerTestOneInput(buf, len);
    free(buf);
    fprintf(stderr, "Done:    %s: (%zd bytes)\n", argv[i], n_read);
  }
}
EOF

cat << EOF > fuzz_me.cc
#include <stdint.h>
#include <stddef.h>

bool FuzzMe(const uint8_t *Data, size_t DataSize) {
  return DataSize >= 3 &&
      Data[0] == 'F' &&
      Data[1] == 'U' &&
      Data[2] == 'Z' &&
      Data[3] == 'Z';
}

extern "C" int LLVMFuzzerTestOneInput(const uint8_t *Data, size_t Size) {
  FuzzMe(Data, Size);
  return 0;
}
EOF
clang-$VERSION -fprofile-instr-generate -fcoverage-mapping fuzz_me.cc StandaloneFuzzTargetMain.c

rm -rf CORPUS
mkdir -p CORPUS
echo -n A > CORPUS/A
./a.out CORPUS/* &> /dev/null
if ! ./a.out CORPUS/* 2>&1 | grep -q "running 1 inputs"; then
    echo "Coverage fuzzing failed"
    exit 1
fi
llvm-profdata-$VERSION merge -sparse *.profraw -o default.profdata
llvm-cov-$VERSION show a.out -instr-profile=default.profdata -name=FuzzMe &> foo.log
if ! grep -q "return DataSize >= 3" foo.log; then
    echo "llvm-cov didn't show the expected output in fuzzing"
    exit 1
fi
echo -n FUZA > CORPUS/FUZA && ./a.out CORPUS/* &> /dev/null
llvm-profdata-$VERSION merge -sparse *.profraw -o default.profdata
llvm-cov-$VERSION show a.out -instr-profile=default.profdata -name=FuzzMe &> foo.log
if ! grep -q "Data\[3\] == 'Z';" foo.log; then
    echo "llvm-cov didn't show the expected output in fuzzing"
    exit 1
fi
rm -rf CORPUS fuzz_me.cc StandaloneFuzzTargetMain.c

echo "Testing sanitizers ..."

echo '#include <stdlib.h>
int main() {
  char *x = (char*)malloc(10 * sizeof(char*));
  free(x);
  return x[5];
}
' > foo.c
clang-$VERSION -o foo -fsanitize=address -O1 -fno-omit-frame-pointer -g  foo.c
if ! ./foo 2>&1 | grep -q heap-use-after-free ; then
    echo "sanitize=address is failing"
    exit 42
fi

# Bug #876973
echo '
#include <stdio.h>
int main(int argc, char **argv)
{
   printf("Hello world!\n");
   return 0;
}' > foo.c

# segfaults on 32bit with "-lc" library (also 6.0 does segfault)
clang-$VERSION -fsanitize=address foo.c -o foo -lc
./foo &> /dev/null || true

echo '
#include <pthread.h>
#include <stdio.h>

int Global;

void *Thread1(void *x) {
  Global++;
  return NULL;
}

void *Thread2(void *x) {
  Global--;
  return NULL;
}

int main() {
  pthread_t t[2];
  pthread_create(&t[0], NULL, Thread1, NULL);
  pthread_create(&t[1], NULL, Thread2, NULL);
  pthread_join(t[0], NULL);
  pthread_join(t[1], NULL);
} ' > foo.c

# fails on i386 with: clang: error: unsupported option '-fsanitize=thread' for target 'i686-pc-linux-gnu'
if [ $DEB_HOST_ARCH != "i386" ]; then
    clang-$VERSION -o foo -fsanitize=thread -g -O1 foo.c
    if ! strings ./foo 2>&1 | grep -q "tsan"; then
        echo "binary doesn't contain tsan code"
        strings foo
        exit 42
    fi
    if ! ./foo 2>&1 | grep -q "data race"; then
        echo "sanitize=address is failing"
        exit 42
    fi
fi

echo '
class a {
public:
  ~a();
};
template <typename, typename> using b = a;
struct f {
  template <typename d> using e = b<a, d>;
};
struct g {
  typedef f::e<int> c;
};
class h {
  struct : g::c { int i; };
};
struct m {
  h i;
};
template <typename> void __attribute__((noreturn)) j();
void k() {
  m l;
  j<int>();
}' > foo.cpp
clang++-$VERSION -std=c++14 -O3 -fsanitize=address -fsanitize=undefined -c foo.cpp -fno-crash-diagnostics


# fails on 32 bit, seems a real BUG in the package, using 64bit static libs?
LANG=C clang-$VERSION -fsanitize=fuzzer test_fuzzer.cc &> foo.log || true
if ! grep "No such file or directory" foo.log; then
    # This isn't failing on 64, so, look at the results
    if ! ./a.out 2>&1 | grep -q -E "(Test unit written|PreferSmall)"; then
        echo "fuzzer. Output:"
        ./a.out || true
        if [ $DEB_HOST_ARCH == "amd64" -o $DEB_HOST_ARCH == "i386" ]; then
            # Don't fail on arm64 and ppc64el
            exit 42
        fi
    fi
fi

echo 'int main() {
	int a=0;
	return a;
}
' > foo.c
clang-$VERSION -g -o bar foo.c

# ABI issue between gcc & clang with clang 7
# https://bugs.llvm.org/show_bug.cgi?id=39427
# https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=913271
if test $VERSION -eq 7; then
echo '
#include <llvm/ADT/ArrayRef.h>
#include <llvm/ADT/Optional.h>
namespace llvm { class Constant{}; class Type; class Value; }
extern llvm::Constant* bar (llvm::Type*, llvm::Constant*, llvm::ArrayRef<llvm::Value*>, bool, llvm::Optional<unsigned> o, llvm::Type*);
#ifdef PART2
llvm::Constant* bar (llvm::Type*, llvm::Constant*, llvm::ArrayRef<llvm::Value*>, bool, llvm::Optional<unsigned> o, llvm::Type*)
{
   return o.hasValue()?static_cast<llvm::Constant*>(nullptr)+1:nullptr;
}
#endif
#ifndef PART2
static llvm::Constant* doConstantRef(llvm::Type* type, llvm::Constant* var, llvm::ArrayRef<llvm::Value*> steps)
{
   llvm::Optional<unsigned> inRangeIndex;
   return bar(type, var, steps, false, inRangeIndex, nullptr);
}
bool foo()
{
   llvm::Constant* var = nullptr;
   llvm::Value* zero = nullptr;
   llvm::Value* indexes[2] = {zero, zero};
   llvm::ArrayRef<llvm::Value*> steps(indexes, 2);
   auto result = doConstantRef(nullptr, var, steps);
   return result;
}
int main()
{
   return foo();
}
#endif
' > foo.cpp
FLAGS="-I/usr/lib/llvm-$VERSION/include -fPIC -fvisibility-inlines-hidden -Werror=date-time -std=c++11 -Wall -Wextra -Wno-unused-parameter -Wwrite-strings -Wcast-qual -Wno-missing-field-initializers -pedantic -Wno-long-long -Wdelete-non-virtual-dtor -Wno-comment -ffunction-sections -fdata-sections -fno-common -Woverloaded-virtual -fno-strict-aliasing -fPIC -fvisibility-inlines-hidden -Werror=date-time -std=c++11 -Wall -Wextra -Wno-unused-parameter -Wwrite-strings -Wcast-qual -Wmissing-field-initializers -pedantic -Wno-long-long -Wnon-virtual-dtor -Wdelete-non-virtual-dtor -ffunction-sections -fdata-sections -O2 -DNDEBUG  -fno-exceptions -D_GNU_SOURCE -D__STDC_CONSTANT_MACROS -D__STDC_FORMAT_MACROS -D__STDC_LIMIT_MACROS"

clang++-$VERSION -c -o part1.o foo.cpp $FLAGS
if test -f /usr/bin/g++; then
    g++ -c -o part2.o -DPART2 foo.cpp $FLAGS
    clang++-$VERSION -o foo part1.o part2.o $FLAGS
    ./foo
fi
rm part1.o part2.o
fi

# OpenMP
if dpkg -l libomp-$VERSION-dev >/dev/null 2>&1; then
cat <<EOF > foo.c
//test.c
#include "omp.h"
#include <stdio.h>

int main(void) {
  #pragma omp parallel
  printf("thread %d\n", omp_get_thread_num());
}
EOF
clang-$VERSION foo.c -fopenmp -o o
./o > /dev/null
else
    echo "OpenMP check skipped, no libomp-$VERSION-dev available."
fi

if test ! -f /usr/lib/llvm-$VERSION/include/c++/v1/vector; then
    echo "Install libc++-$VERSION-dev";
    exit -1;
fi

if test ! -f /usr/lib/llvm-$VERSION/lib/libc++abi.so; then
    echo "Install libc++abi-$VERSION-dev";
    exit -1;
fi


# libc++
echo '
#include <vector>
#include <string>
#include <iostream>
using namespace std;
int main(void) {
    vector<string> tab;
    tab.push_back("the");
    tab.push_back("world");
    tab.insert(tab.begin(), "Hello");

    for(vector<string>::iterator it=tab.begin(); it!=tab.end(); ++it)
    {
        cout << *it << " ";
    }
    return 0;
}' > foo.cpp
clang++-$VERSION -stdlib=libc++ foo.cpp -o o
if ! ldd o 2>&1|grep -q  libc++.so.1; then
    echo "not linked against libc++.so.1"
    exit -1
fi
if ! ldd o 2>&1|grep -q  libc++abi.so.1; then
    echo "not linked against libc++abi.so.1"
    exit -1
fi

./o > /dev/null
clang++-$VERSION -std=c++11 -stdlib=libc++ foo.cpp -o o
./o > /dev/null
clang++-$VERSION -std=c++14 -stdlib=libc++ foo.cpp -lc++experimental -o o
./o > /dev/null

# Bug 46321
cat > test.cpp << EOF
#include <iostream>
int main() {
  std::cout << "Hello World!" << std::endl;
}
EOF
clang++-$VERSION -stdlib=libc++ -unwindlib=libunwind -rtlib=compiler-rt -static-libstdc++ -static-libgcc test.cpp  -lpthread -ldl -o test
./test > /dev/null

clang++-$VERSION -stdlib=libc++ -static-libstdc++ -fuse-ld=lld -l:libc++abi.a test.cpp -o test
./test > /dev/null

clang++-$VERSION -stdlib=libc++ -nostdlib++ test.cpp -l:libc++.a -l:libc++abi.a -pthread -o test
./test > /dev/null

# bug https://bugs.llvm.org/show_bug.cgi?id=43604

cat > test.cpp << EOF
#include <iostream>
__attribute__((visibility("default")))
extern "C" void plugin() {
        std::cout << "Hello World from a plugin!" << std::endl;
}
EOF
clang++-$VERSION -shared -o plugin.so -fvisibility=hidden foo.cpp -static-libstdc++ || true
clang++-$VERSION -shared -o plugin.so -fvisibility=hidden foo.cpp -stdlib=libc++ -static-libstdc++ ||true
rm -f plugin.so

# Bug 889832
echo '#include <iostream>
int main() {}'  | clang++-$VERSION -std=c++1z  -x c++ -stdlib=libc++ -

if test ! -f /usr/lib/llvm-$VERSION/include/cxxabi.h; then
    echo "Install libc++abi-$VERSION-dev";
    exit -1;
fi

# Force the usage of libc++abi
clang++-$VERSION -stdlib=libc++ -lc++abi foo.cpp -o o
./o > /dev/null
if ! ldd o 2>&1|grep -q  libc++abi.so.1; then
    echo "not linked against libc++abi.so.1"
    exit -1
fi

# Use the libc++abi and uses the libstc++ headers
clang++-$VERSION -lc++abi foo.cpp -o o
./o > /dev/null
if ! ldd o 2>&1|grep -q libstdc++.so.; then
    echo "not linked against libstdc++"
    exit -1
fi

# fs from C++17
echo '
#include <filesystem>
#include <type_traits>
using namespace std::filesystem;
int main() {
  static_assert(std::is_same<
          path,
          std::filesystem::path
      >::value, "");
}' > foo.cpp
clang++-$VERSION -std=c++17 -stdlib=libc++ foo.cpp -o o
./o > /dev/null
clang++-$VERSION -std=c++17 -stdlib=libc++ foo.cpp -lc++experimental -o o
./o > /dev/null

# Bug LP#1586215
echo '
#include <string>
#include <iostream>

int main()
{
    try
    {
        std::string x;
        char z = x.at(2);
        std::cout << z << std::endl;
    }
    catch (...)
    {
    }

    return 0;
}' > foo.cpp
clang++-$VERSION -stdlib=libc++ -Wall -Werror foo.cpp -o foo
./foo

# Bug https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=914201
echo '
#include <math.h>
int main(void)
{
    double f = 2.0;
    if (isnan(f))
      return 1;
    return 0;
}' > foo.c
clang-$VERSION -Wconversion -Werror foo.c &> /dev/null || true

if test -f /usr/bin/g++; then
g++ -nostdinc++ -I/usr/lib/llvm-$VERSION/bin/../include/c++/v1/ -L/usr/lib/llvm-$VERSION/lib/ \
    foo.cpp -nodefaultlibs -std=c++17 -lc++ -lc++abi -lm -lc -lgcc_s -lgcc|| true
./o > /dev/null
fi


if dpkg -l|grep -q flang-$VERSION; then
    echo "Testing flang-$VERSION (Fortran) ..."
    echo 'program math
  implicit none
  real :: x, y
  x = 3.14
  y = 2.71
  print *, "x + y = ", x + y
end program math
' > foo.f90
    flang-new-$VERSION foo.f90 -o foo && ./foo &> foo.log
    if ! grep -q "x + y =" foo.log 2>&1; then
        echo "flang: Could not find the expected output"
        exit -1
    fi


    # testing with a shared libraries
    echo '
module hello_world
  contains
    subroutine say_hello()
      print *, "Hello, World!"
    end subroutine say_hello
end module hello_world
' > lib.f90
    flang-new-$VERSION -c lib.f90  -fpie
    flang-new-$VERSION -shared  -fpie -o libflib.so lib.o

    echo '
program main
   use hello_world
   call say_hello()
end program main' > foo.f90
    flang-new-$VERSION foo.f90 -L. -lflib -o foo
    LD_LIBRARY_PATH=. ./foo &> foo.log
    if ! grep -q "Hello, World!" foo.log 2>&1; then
        echo "flang: lib didn't work"
        exit -1
    fi
    rm -f foo.log foo.f90 foo libflib.so
else
    echo "Skipping esting flang-$VERSION (Fortran) ..."
    echo "doesn't exist on this arch"
fi

# libc
if dpkg -l libllvmlibc-$VERSION-dev >/dev/null 2>&1; then
    echo "Testing llvmlibc-$VERSION-dev ..."
    echo '
#include <math.h>
int main(void)
{
    double f = 2.0;
    if (isnan(f))
      return 1;
    return 0;
}' > main.c
    clang-$VERSION -static -nostdlib -nolibc -L/usr/lib/llvm-$VERSION/lib/ -lllvmlibc main.c -o foo
    if ! ldd foo 2>&1|grep -qv libc.; then
	echo "linked against regular libc"
	exit -1
    fi

    # segfault for now
    ./foo || true
else
    echo "libllvmlibc check skipped, no libllvmlibc-$VERSION-dev available."
fi

# libclc
echo "Testing libclc-$VERSION-dev ..."

if test ! -f /usr/lib/clc/amdgcn--amdhsa.bc; then
    echo "Install libclc-$VERSION";
    exit -1;
fi

if test ! -f /usr/lib/clc/polaris10-amdgcn-mesa-mesa3d.bc; then
    # Make sure that #993904 and #995069 don't come back
    echo "/usr/lib/clc/polaris10-amdgcn-mesa-mesa3d.bc doesn't exist"
    exit 1
fi

BINDIR=$(llvm-config-$VERSION --bindir)
/usr/lib/llvm-$VERSION/share/libclc/check_external_calls.sh /usr/lib/clc/amdgcn--amdhsa.bc $BINDIR > /dev/null

# libunwind
echo "Testing libunwind-$VERSION-dev ..."

if test ! -f /usr/include/libunwind/unwind.h; then
    echo "Install libunwind-$VERSION-dev";
    exit -1;
fi
echo '
#include <libunwind.h>
#include <stdlib.h>

void backtrace(int lower_bound) {
  unw_context_t context;
  unw_getcontext(&context);

  unw_cursor_t cursor;
  unw_init_local(&cursor, &context);

  int n = 0;
  do {
    ++n;
    if (n > 100) {
      abort();
    }
  } while (unw_step(&cursor) > 0);

  if (n < lower_bound) {
    abort();
  }
}

void test1(int i) {
  backtrace(i);
}

void test2(int i, int j) {
  backtrace(i);
  test1(j);
}

void test3(int i, int j, int k) {
  backtrace(i);
  test2(j, k);
}

void test_no_info() {
  unw_context_t context;
  unw_getcontext(&context);

  unw_cursor_t cursor;
  unw_init_local(&cursor, &context);

  unw_proc_info_t info;
  int ret = unw_get_proc_info(&cursor, &info);
  if (ret != UNW_ESUCCESS)
    abort();

  // Set the IP to an address clearly outside any function.
  unw_set_reg(&cursor, UNW_REG_IP, (unw_word_t)0);

  ret = unw_get_proc_info(&cursor, &info);
  if (ret != UNW_ENOINFO)
    abort();
}

int main(int, char**) {
  test1(1);
  test2(1, 2);
  test3(1, 2, 3);
  test_no_info();
  return 0;
}'> foo.cpp
clang++-$VERSION foo.cpp -lunwind -ldl -I /usr/include/libunwind
./a.out
clang++-$VERSION foo.cpp -unwindlib=libunwind -rtlib=compiler-rt -I/usr/include/libunwind
./a.out

echo '
#include <assert.h>
#include <dlfcn.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <unistd.h>
#include <unwind.h>

_Unwind_Reason_Code frame_handler(struct _Unwind_Context* ctx, void* arg) {
  (void)arg;
  Dl_info info = { 0, 0, 0, 0 };

  // Unwind util the main is reached, above frames depend on the platform and
  // architecture.
  if (dladdr(reinterpret_cast<void *>(_Unwind_GetIP(ctx)), &info) &&
      info.dli_sname && !strcmp("main", info.dli_sname)) {
    _Exit(0);
  }
  return _URC_NO_REASON;
}

void signal_handler(int signum) {
  (void)signum;
  _Unwind_Backtrace(frame_handler, NULL);
  _Exit(-1);
}

int main(int, char**) {
  signal(SIGUSR1, signal_handler);
  kill(getpid(), SIGUSR1);
  return -2;
}
'> foo.cpp
clang++-$VERSION foo.cpp /usr/lib/llvm-$VERSION/lib/libunwind.a -I/usr/include/libunwind/ -lpthread -ldl
./a.out||true
clang++-$VERSION foo.cpp -unwindlib=libunwind -rtlib=compiler-rt -I/usr/include/libunwind -ldl
./a.out||true

if test ! -f /usr/lib/llvm-$VERSION/include/polly/LinkAllPasses.h; then
    echo "Install libpolly-$VERSION-dev for polly";
    exit -1;
fi

echo "Testing polly (libpolly-$VERSION-dev) ..."

# Polly
echo "
#define N 1536
float A[N][N];
float B[N][N];
float C[N][N];

void init_array()
{
    int i, j;
    for (i = 0; i < N; i++) {
        for (j = 0; j < N; j++) {
            A[i][j] = (1+(i*j)%1024)/2.0;
            B[i][j] = (1+(i*j)%1024)/2.0;
        }
    }
}

int main()
{
    int i, j, k;
    double t_start, t_end;
    init_array();
    for (i = 0; i < N; i++) {
        for (j = 0; j < N; j++) {
            C[i][j] = 0;
            for (k = 0; k < N; k++)
                C[i][j] = C[i][j] + A[i][k] * B[k][j];
        }
    }
    return 0;
}
" > foo.c
clang-$VERSION -O3 -mllvm -polly -mllvm -polly-parallel -lgomp  foo.c
clang-$VERSION -O3 -mllvm -polly -mllvm -polly-vectorizer=stripmine foo.c
clang-$VERSION -S -fsave-optimization-record -emit-llvm foo.c -o matmul.s
# broken https://bugs.llvm.org/show_bug.cgi?id=51642
test -s matmul.opt.yaml||true

clang-$VERSION -S -O2 -fsave-optimization-record -emit-llvm foo.c -o matmul.s
if ! test -s matmul.opt.yaml; then
    echo "-fsave-optimization-record generated an empty file"
    exit 1
fi


opt-$VERSION -S -polly-canonicalize matmul.s > matmul.preopt.ll > /dev/null
opt-$VERSION -basic-aa -polly-ast matmul.preopt.ll -polly-process-unprofitable > /dev/null
if test ! -f /usr/lib/llvm-$VERSION/share/opt-viewer/opt-viewer.py; then
    echo "Install llvm-$VERSION-tools"
    exit 42
fi
/usr/lib/llvm-$VERSION/share/opt-viewer/opt-viewer.py -source-dir .  matmul.opt.yaml -o ./output > /dev/null

if ! grep -q "inlined into" output/foo.c.html 2>&1; then
    echo "Could not find the output from polly"
    exit -1
fi

echo "
int foo(int x, int y) __attribute__((always_inline));
int foo(int x, int y) { return x + y; }
int bar(int j) { return foo(j, j - 2); }
int sum = 0;

int main(int argc, const char *argv[]) {
  for (int i = 0; i < 30; i++)
    bar(argc);
  return sum;
}

" > foo.cc
clang-$VERSION -O2 -Rpass=inline foo.cc -c &> foo.log
if ! grep -q -E "(inlined into|cost=always)" foo.log; then
    echo "-Rpass fails"
    cat foo.log
    exit 1
fi
echo "
int X = 0;

int main() {
  int i;
  for (i = 0; i < 100; i++)
    X += i;
  return 0;
}"> foo.cc
clang++-$VERSION -O2 -fprofile-instr-generate foo.cc -o foo
LLVM_PROFILE_FILE="foo-%p.profraw" ./foo
llvm-profdata-$VERSION merge -output=foo.profdata foo-*.profraw
clang++-$VERSION -O2 -fprofile-instr-use=foo.profdata foo.cc -o foo

# https://bugs.llvm.org/show_bug.cgi?id=44870
cat <<EOF > foo.cpp
#include <clang/CodeGen/BackendUtil.h>
#include <llvm/Support/VirtualFileSystem.h>

using namespace clang;

int main() {
  DiagnosticsEngine* diags;
  HeaderSearchOptions* hsOpts;
  CodeGenOptions* cgOpts;
  TargetOptions* tOpts;
  LangOptions* lOpts;
  llvm::StringRef* tDesc;
  llvm::Module* m;
  BackendAction* action;
  std::unique_ptr<raw_pwrite_stream> AsmOutStream;
  IntrusiveRefCntPtr<llvm::vfs::FileSystem> VFS;

  EmitBackendOutput(*diags, *hsOpts, *cgOpts, *tOpts, *lOpts, *tDesc, m, *action, VFS, std::move(AsmOutStream));
}
EOF
clang++-$VERSION foo.cpp -o test -lclangCodeGen -lclangDriver -lclangFrontend -lclangFrontendTool -lclangCodeGen -lclangRewriteFrontend -lclangARCMigrate -lclangStaticAnalyzerFrontend -lclangStaticAnalyzerCheckers -lclangStaticAnalyzerCore -lclangCrossTU -lclangIndex -lclangFrontend -lclangDriver -lclangParse -lclangSerialization -lclangSema -lclangAnalysis -lclangEdit -lclangFormat -lclangToolingInclusions -lclangToolingCore -lclangRewrite -lclangASTMatchers -lclangAST -lclangLex -lclangAPINotes -lclangSupport -lclangBasic -ldl  /usr/lib/llvm-$VERSION/lib/libLLVM-$VERSION.so -lclangCodeGen -lclangDriver -lclangFrontend -lclangFrontendTool -lclangRewriteFrontend -lclangARCMigrate -lclangStaticAnalyzerFrontend -lclangStaticAnalyzerCheckers -lclangStaticAnalyzerCore -lclangCrossTU -lclangIndex -lclangParse -lclangSerialization -lclangSema -lclangAnalysis -lclangEdit -lclangFormat -lclangToolingInclusions -lclangToolingCore -lclangRewrite -lclangASTMatchers -lclangAST -lclangLex -ldl  -I /usr/lib/llvm-$VERSION/include/ -L/usr/lib/llvm-$VERSION/lib/ -lPolly -lPollyISL

if test ! -f /usr/bin/lldb-$VERSION; then
    echo "Install lldb-$VERSION";
    exit -1;
fi

echo "b main
run
bt
quit" > lldb-cmd.txt

echo "Testing lldb-$VERSION ..."
# bug 913946
lldb-$VERSION -s lldb-cmd.txt bar &> foo.log

if dpkg -l|grep -q clang-$VERSION-dbgsym; then
    # Testing if clang dbg symbol are here
    lldb-$VERSION -s lldb-cmd.txt clang-$VERSION &> foo.log
    if ! grep "main at driver.cpp" foo.log; then
        echo "Could not find the debug info"
        echo "Or the main() of clang isn't in driver.cpp anymore"
        cat foo.log
        exit -1
    fi
else
    echo "clang-$VERSION-dbgsym isn't installed"
fi

echo "Testing wasm support ..."

if dpkg -l|grep -q wasi-libc; then
    cat <<EOF > printf.c
    #include <stdio.h>
    int main(int argc, char *argv[]) {
      printf("%s\n", "Hello World!");
    }
EOF
    # wasi-libc supports only wasm32 right now
    clang-$VERSION -target wasm32-wasi -o printf printf.c
    file printf &> foo.log
    if ! grep -q "WebAssembly" foo.log; then
        echo "the generated file isn't a WebAssembly file?"
        exit 1
    fi
    rm -f printf.c printf

    cat <<EOF > cout.cpp
    #include <iostream>
    int main() {
      std::cout << "Hello World!" << std::endl;
    }
EOF
    # libcxx requires wasi-libc, which only exists for wasm32 right now
    clang++-$VERSION --target=wasm32-wasi -o cout cout.cpp
    file cout &> foo.log
    if ! grep -q "WebAssembly" foo.log; then
        echo "the generated file isn't a WebAssembly file?"
        exit 1
    fi
    rm -f cout.cpp cout
else
    echo "wasi-libc not installed"
fi

echo '
#include <vector>
int main (void)
{  std::vector<int> a;
  a.push_back (0);
}
' > foo.cpp
clang++-$VERSION -g -o foo foo.cpp
echo 'target create "./foo"
b main
r
n
p a
quit' > lldb-cmd.txt
lldb-$VERSION -s lldb-cmd.txt ./foo &> foo.log
if ! grep -q "stop reason = step over" foo.log; then
    echo "Could not find the lldb expected output"
    cat foo.log
    # do not fail on i386, never worked here
    if [ $DEB_HOST_ARCH != "i386" ]; then
        exit 42
    fi
fi

if test ! -f /usr/lib/llvm-$VERSION/lib/libclangToolingInclusions.a; then
    echo "Install libclang-$VERSION-dev";
    exit -1;
fi

# https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=943623
rm *.o
/usr/bin/ar x /usr/lib/llvm-$VERSION/lib/libclangIndex.a &> /dev/null
file *.o a> foo.log
rm *.o
if grep "LLVM IR bitcode" foo.log; then
    echo "found LLVM IR bitcode in the libclangIndex.a file"
    echo "Should be elf"
    exit -2
fi
echo "
from ctypes import *
libclang='/usr/lib/llvm-$VERSION/lib/libclang-$VERSION.so.1'
lib = CDLL(libclang)
fun = lib.clang_getAddressSpace
print(fun)
" > foo.py
python3 foo.py|grep _FuncPtr
rm foo.py

echo "Testing cmake build ..."

if grep -q lit-cpuid /usr/lib/llvm-$VERSION/lib/cmake/llvm/LLVMExports*.cmake; then
    echo "LLVMExports*.cmake should not have lit-cpuid"
    echo "it introduces a dependency between llvm-9 => lldb"
    exit -1
fi

rm -rf cmaketest && mkdir cmaketest
cat > cmaketest/CMakeLists.txt <<EOF
cmake_minimum_required(VERSION 3.7)
project(SanityCheck)
find_package(LLVM $VERSION.1 REQUIRED CONFIG)
message(STATUS "LLVM_CMAKE_DIR: \${LLVM_CMAKE_DIR}")
if(NOT EXISTS "\${LLVM_TOOLS_BINARY_DIR}/clang")
message(FATAL_ERROR "Invalid LLVM_TOOLS_BINARY_DIR: \${LLVM_TOOLS_BINARY_DIR}")
endif()
# TODO add version to ClangConfig.cmake and use $VERSION below
find_package(Clang REQUIRED CONFIG)
find_file(H clang/AST/ASTConsumer.h PATHS \${CLANG_INCLUDE_DIRS} NO_DEFAULT_PATH)
message(STATUS "CLANG_INCLUDE_DIRS: \${CLANG_INCLUDE_DIRS}")
if(NOT H)
message(FATAL_ERROR "Invalid Clang header path: \${CLANG_INCLUDE_DIRS}")
endif()
EOF
mkdir cmaketest/standard cmaketest/explicit
# "Test: CMake find LLVM and Clang in default path"
(cd cmaketest/standard && CC=clang-$VERSION CXX=clang++-$VERSION cmake .. > /dev/null)
# "Test: CMake find LLVM and Clang in explicit prefix path"
(cd cmaketest/explicit && CC=clang-$VERSION CXX=clang++-$VERSION CMAKE_PREFIX_PATH=/usr/lib/llvm-$VERSION cmake .. > /dev/null)
rm -rf cmaketest

# Test case for bug #900440
rm -rf cmaketest && mkdir cmaketest
cat > cmaketest/CMakeLists.txt <<EOF
cmake_minimum_required(VERSION 3.7)
project(testllvm)

find_package(LLVM CONFIG REQUIRED)
find_package(Clang CONFIG REQUIRED)

if(NOT LLVM_VERSION STREQUAL Clang_VERSION)
    #message(FATAL_ERROR "LLVM ${LLVM_VERSION} not matching to Clang ${Clang_VERSION}")
endif()
EOF
mkdir cmaketest/foo/
(cd cmaketest/foo && cmake .. > /dev/null)
rm -rf cmaketest

# Make sure the triple change doesn't break the world
# https://reviews.llvm.org/D107799#3027607
if dpkg -l|grep -q zlib1g-dev; then
    rm -rf cmaketest && mkdir cmaketest
    cat > cmaketest/CMakeLists.txt <<EOF
cmake_minimum_required(VERSION 3.0)
project(test)
find_package(ZLIB)
EOF
    mkdir cmaketest/foo/
    cd cmaketest/foo &&  CC=clang-$VERSION CXX=clang++-$VERSION cmake .. &> foo.log
    if grep "Could NOT find ZLIB" foo.log; then
        echo "clang hasn't been able to find zlib dev even if it is on the system"
        echo "https://reviews.llvm.org/D107799#3027607"
        cat foo.log
        exit 1
    fi
    cd -
    rm -rf cmaketest
fi

# Test case for bug #994827
rm -rf cmaketest && mkdir cmaketest
cat > cmaketest/CMakeLists.txt <<EOF
cmake_minimum_required(VERSION 3.18)
project(testllvm)

find_package(Clang REQUIRED CONFIG HINTS "/usr/lib/llvm-$LLVM_VERSION/lib/cmake/clang/")
EOF
mkdir cmaketest/foo/
(cd cmaketest/foo && cmake .. > /dev/null)
rm -rf cmaketest


CLANG=clang-$VERSION
#command -v "$CLANG" 1>/dev/null 2>/dev/null || { printf "Usage:\n%s CLANGEXE [ARGS]\n" "$0" 1>&2; exit 1; }
#shift

TEMPDIR=$(mktemp -d); trap "rm -rf \"$TEMPDIR\"" 0

echo "Testing all other sanitizers ..."

echo "int main() { return 1; }" > foo.c
# fails to run on i386 with the following error:
#clang: error: unsupported option '-fsanitize=efficiency-working-set' for target 'i686-pc-linux-gnu'
# seems like esan was removed from clang: https://github.com/llvm/llvm-project/commit/885b790f89b6068ec4caad8eaa51aa8098327059
#clang-$VERSION -fsanitize=efficiency-working-set -o foo foo.c || true
#./foo &> /dev/null || true

cat > "$TEMPDIR/test.c" <<EOF
#include <stdlib.h>
#include <stdio.h>
int main ()
{
#if __has_feature(address_sanitizer)
  puts("address_sanitizer");
#endif
#if __has_feature(thread_sanitizer)
  puts("thread_sanitizer");
#endif
#if __has_feature(memory_sanitizer)
  puts("memory_sanitizer");
#endif
#if __has_feature(undefined_sanitizer)
  puts("undefined_sanitizer");
#endif
#if __has_feature(dataflow_sanitizer)
  puts("dataflow_sanitizer");
#endif
#if __has_feature(efficiency_sanitizer)
  puts("efficiency_sanitizer");
#endif
  printf("Ok\n");
  return EXIT_SUCCESS;
}
EOF

F=$(clang-$VERSION --target=x86_64-unknown-linux-gnu --rtlib=compiler-rt --print-libgcc-file-name)
if test ! $F; then
	echo "Cannot find $F"
    echo "TODO check if the exit1 can be put back"
#	exit 1
else
    echo "$F is one of the compiler-rt file"
fi

# only for AMD64 for now
# many sanitizers only work on AMD64
# x32 programs need to be enabled in the kernel bootparams for debian
# (https://wiki.debian.org/X32Port)
#
# SYSTEM should iterate multiple targets (eg. x86_64-unknown-none-gnu for embedded)
# MARCH should iterate the library architectures via flags
# LIB should iterate the different libraries
echo "if it fails, please run"
echo "apt-get install libc6-dev:i386 libgcc-5-dev:i386 libc6-dev-x32 libx32gcc-5-dev libx32gcc-9-dev"
for SYSTEM in ""; do
    # add "-m32 -march=i686" -m32 -mx32 to test multiarch with i386
    for MARCH in -m64; do
        for LIB in --rtlib=compiler-rt -fsanitize=address -fsanitize=thread -fsanitize=memory -fsanitize=undefined -fsanitize=dataflow; do # -fsanitize=efficiency-working-set; do
            if test "$MARCH" == "-m32" -o "$MARCH" == "-mx32"; then
                if test $LIB == "-fsanitize=thread" -o $LIB == "-fsanitize=memory" -o $LIB == "-fsanitize=dataflow" -o $LIB == "-fsanitize=address" -o $LIB == "-fsanitize=undefined"; then
                    echo "Skip $MARCH / $LIB";
                    continue
                fi
            fi
            if test "$MARCH" == "-m32 -march=i686"; then
                if test $LIB == "-fsanitize=memory" -o $LIB == "-fsanitize=thread" -o $LIB == "-fsanitize=dataflow"; then
                     echo "Skip $MARCH / $LIB";
                     continue
                fi
            fi
            XARGS="$SYSTEM $MARCH $LIB"
            printf "\nTest: clang %s\n" "$XARGS"
            rm -f "$TEMPDIR/test"
            "$CLANG" $XARGS -o "$TEMPDIR/test" "$@" "$TEMPDIR/test.c" || true
            [ ! -e "$TEMPDIR/test" ] || { "$TEMPDIR/test" || printf 'Error\n'; }
        done
    done
done

echo "If the following fails, try setting an environment variable such as:"
echo "OBJC_INCLUDE_PATH=/usr/lib/gcc/x86_64-linux-gnu/8/include"
echo "libobjc-9-dev should be also installed"
echo "#include <objc/objc.h>" > foo.m
#clang-$VERSION -c foo.m

if test ! -f /usr/lib/llvm-$VERSION/lib/libclangBasic.a; then
    echo "Install libclang-$VERSION-dev"
    exit 1
fi

# check that the hip language is functioning
echo "Testing HIP language ..."
if dpkg -l|grep -q hipcc; then
  cat > foo.hip <<EOF
#include <hip/hip_runtime_api.h>
int main() { return 0; }
EOF
  clang++-$VERSION --rocm-path=/usr -x hip -lamdhip64 foo.hip
  rm -f foo.hip hip
fi

#clean up
rm -f a.out bar crash-* foo foo.* lldb-cmd.txt main.* test_fuzzer.cc foo.* o
rm -rf output matmul.* *profraw opt.ll a.json default.profdata test test.cpp

echo "Completed"
