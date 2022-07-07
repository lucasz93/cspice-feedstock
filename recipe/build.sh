#!/bin/bash

if [ "$(uname)" == "Darwin" ];
then
    LIBNAME=libcspice.66.dylib
    EXTRA_FLAGS="-dynamiclib -install_name @rpath/${LIBNAME}"
else
    LIBNAME=libcspice.so.66
    EXTRA_FLAGS="-shared -Wl,-soname,${LIBNAME}"
fi
# static library files names
CSPICENM=cspice.66.a
CSUPPTNM=csupport.66.a

#CFLAGS="$CFLAGS -O0 -ggdb3"
CFLAGS="$CFLAGS -O2"
#CFLAGS="$CFLAGS -O2 -pg"

#########################################
# Build Shared library
#########################################
#  cd to lib dir
cd ${SRC_DIR}/lib
#  rm static libraries, needed for next static build steps
rm -f cspice.a
rm -f csupport.a
#  compile c code
ls ./../src/cspice/*.c | parallel --max-args=1 "${CC} ${CFLAGS} -Iinclude -c -fPIC -ansi -pedantic -Wno-overlength-strings {1}"
#  make the shared library
${CC} ${EXTRA_FLAGS} -fPIC -O2 -pedantic -o ${LIBNAME} *.o ${LDFLAGS} -lm
#  cd up to src directory
cd ${SRC_DIR}

#########################################
# Build Static library using NAIF scripts
#########################################
#  rebuild static library using NAIF scripts
export TKCOMPILER=${CC}
cd ${SRC_DIR}/src/cspice
${BUILD_PREFIX}/bin/tcsh ./mkprodct.csh
cd ${SRC_DIR}/src/csupport
${BUILD_PREFIX}/bin/tcsh ./mkprodct.csh
#  rename static libraries to include version number
cd ${SRC_DIR}/lib
cp cspice.a ${CSPICENM}
cp csupport.a ${CSUPPTNM}
#  cd up to src directory
cd ${SRC_DIR}

#########################################
# Build executables using NAIF scripts
#########################################
# rm all prebuilt executables to ensure we are building and testing new files
rm ${SRC_DIR}/exe/*
# cd into src directory
cd ${SRC_DIR}/src
# build each tool using NAIF scripts
for i in *_c; do cd $i && ${BUILD_PREFIX}/bin/tcsh ./mkprodct.csh && cd -; done
#  cd up to src directory
cd ${SRC_DIR}
#  remove cspice.a and csupport.a as we want those to be symlinked, don't do this earlier for tool building
rm ${SRC_DIR}/lib/cspice.a
rm ${SRC_DIR}/lib/csupport.a

#########################################
# deploy built products
#########################################
# Deploy the built shared libraries and executables
#  make the target directories
mkdir -p ${PREFIX}/include/cspice
mkdir -p ${PREFIX}/lib
mkdir -p ${PREFIX}/bin
#  copy the files to where they are needed
cp $(find $(find ${SRC_DIR} -name "exe" -type d) -type f) ${PREFIX}/bin
cp lib/${LIBNAME} ${PREFIX}/lib/
cp lib/${CSPICENM} ${PREFIX}/lib/
cp lib/${CSUPPTNM} ${PREFIX}/lib/
cp src/cspice/cspice_state.h include/
cp include/*.h ${PREFIX}/include/cspice/
#  finally make symbolic links for sans version file names
if [ "$(uname)" == "Darwin" ];
then
    ln -f -s ${PREFIX}/lib/${LIBNAME} ${PREFIX}/lib/libcspice.dylib
else
    ln -f -s ${PREFIX}/lib/${LIBNAME} ${PREFIX}/lib/libcspice.so
fi
ln -f -s ${PREFIX}/lib/${CSPICENM} ${PREFIX}/lib/cspice.a
ln -f -s ${PREFIX}/lib/${CSUPPTNM} ${PREFIX}/lib/csupport.a
