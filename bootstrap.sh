#!/bin/bash

# This script will download the LibLo library,
# and patch it so it can be compiled using
# Visual Studio 2003 (MSVC7).

# For Windows, this script is intended to be run using MSYS2.
# Required packages: tar, patch, coreutils

echo This script bootstraps required libraries for selected environments.

MAKE="make -j4"

BUILDDIR="`pwd`"
SRCDIR="$(cd $(dirname $0); pwd)"

LIBDEPSDIR="$BUILDDIR/libdeps"
if [ -n "$1" ]; then
    if [ x"$1" = "x-h" ] || [ x"$1" = "x--help" ]; then
        echo "./bootstrap.sh [libdeps] [tarballs]"
        echo
        echo "[libdeps] optionally specifies location where library dependencies"
        echo "should be unpacked and built. By default it is '<current directory>/libdeps'."
        echo
        echo "[tarballs] optionally specifies a different location to store the"
        echo "downloaded source tar and zip files.  By default it is assumed"
        echo "to be '<libdeps>/tarballs'."
        echo
        echo "Note: If you specify the <libdeps> path here, you should provide the same"
        echo "path as an argument to './configure --with-libdeps=<libdeps>'."
        echo
        echo "You may find it beneficial to explicitly specify these paths"
        echo "when doing out-of-source (VPATH) builds, in order to share"
        echo "pre-compiled dependencies."
        exit 0
    fi
    LIBDEPSDIR="$1"
fi
if ! [ -d "$LIBDEPSDIR" ]; then
    mkdir -p "$LIBDEPSDIR"
fi

TARBALLSDIR="$LIBDEPSDIR/tarballs"
if [ -n "$2" ]; then
    TARBALLSDIR="$2"
fi
if ! [ -d "$TARBALLSDIR" ]; then
    mkdir -p "$TARBALLSDIR"
fi

LIBDEPSDIR="$(cd $LIBDEPSDIR; pwd)"
TARBALLSDIR="$(cd $TARBALLSDIR; pwd)"

PATCHESDIR="$SRCDIR/libdeps/patches"

# Uncomment or set environment variable to cross-compile for Windows on Linux
# MINGW_ON_LINUX=1

if [ x$MINGW_ON_LINUX = x1 ]; then
    CONFIGURE_ARGS="--host=x86_64-w64-mingw32"
    CMAKE_ARGS="-DCMAKE_TOOLCHAIN_FILE=${SRCDIR}/libdeps/Toolchain-cross-mingw32-linux.cmake"
    CHAI_MAKE_ARGS="SYSTEM=fail" # force use of CMake
fi
# Then run "./configure --host=x86_64-w64-mingw32 && make"

liblo() {
liblo_URL=http://downloads.sourceforge.net/liblo/liblo-0.30.tar.gz
liblo_TAR=$TARBALLSDIR/liblo-0.30.tar.gz
liblo_DIR=liblo-0.30
liblo_MD5=fa1a9d45f86fc18fb54019f670ff2262

if [ $($MD5 $liblo_TAR | $MD5CUT)x != ${liblo_MD5}x ]; then
    echo Downloading $liblo_TAR ...
    if [ -e $liblo_TAR ]; then rm -v $liblo_TAR; fi
    $DL $liblo_TAR $liblo_URL
fi

if [ $($MD5 $liblo_TAR | $MD5CUT)x != ${liblo_MD5}x ]; then
	echo "Error in MD5 checksum for $liblo_TAR"
	exit
fi

if ! [ -d $liblo_DIR ]; then

echo Extracting $liblo_TAR ...
if !(tar -xzf $liblo_TAR); then
	echo "Error in archive.";
	exit
fi

if [ "${liblo_PATCH}"x != x ]; then
    echo Patching liblo
    mkdir ${liblo_DIR}/patches
    for P in ${liblo_PATCH}; do
        cp -v ${PATCHESDIR}/$P ${liblo_DIR}/patches/;
        echo $(basename $P) >>${liblo_DIR}/series;
    done
    if !(cd $liblo_DIR; quilt push -a); then
	      echo "Error applying patches for liblo."
	      exit
    fi
# patch requires running autoconf
echo Running autoconf for $liblo_DIR
if !(cd $liblo_DIR && autoconf); then
	echo "Error applying patch" $liblo_PATCH
	exit
fi
fi

case $(uname) in
   CYGWIN*)
   echo Compiling $liblo_DIR Debug
   if !( "$COMPILE" /Build Debug $(cygpath -w $liblo_DIR/LibLo.sln ) /Project LibLo /Out compile.log ); then
	  echo "Error compiling $liblo_DIR" Debug
	  cat compile.log
	  exit
   fi
   rm compile.log >/dev/null 2>&1
   echo Compiling $liblo_DIR Release
   if !( "$COMPILE" /Build Release $(cygpath -w $liblo_DIR/LibLo.sln ) /Project LibLo /Out compile.log ); then
	  echo "Error compiling $liblo_DIR" Release
	  cat compile.log
	  exit
   fi
   rm compile.log >/dev/null 2>&1
   ;;

   *)
   echo Configuring $liblo_DIR
   if !(cd $liblo_DIR && env CFLAGS="$liblo_CFLAGS" LDFLAGS="$liblo_LDFLAGS" LIBS="$liblo_LIBS" CXXFLAGS=fail ./configure ${CONFIGURE_ARGS} --disable-shared $liblo_CONFIGEXTRA); then
	  echo "Error configuring $liblo_DIR"
	  exit
   fi

   echo Compiling $liblo_DIR
   if !(cd $liblo_DIR && $MAKE); then
	  echo "Error compiling $liblo_DIR"
	  exit
   fi
   ;;
esac

fi

echo
echo LibLo Done.
echo
}

ode() {
ode_URL=https://bitbucket.org/odedevs/ode/downloads/ode-0.13.1.tar.gz
ode_TAR=$TARBALLSDIR/ode-0.13.1.tar.gz
ode_DIR=ode-0.13.1
ode_MD5=00f6613b3d8e5249be60e3a513d6aebd

if [ $($MD5 $ode_TAR | $MD5CUT)x != ${ode_MD5}x ]; then
    echo Downloading $ode_TAR ...
    if [ -e $ode_TAR ]; then rm -v $ode_TAR; fi
    $DL $ode_TAR $ode_URL
fi

if [ $($MD5 $ode_TAR | $MD5CUT)x != ${ode_MD5}x ]; then
	echo "Error in MD5 checksum for $ode_TAR"
	exit
fi

if ! [ -d $ode_DIR ]; then

echo Extracting $ode_TAR ...
if !(tar -xzf $ode_TAR); then
	echo "Error in archive.";
	exit
fi

if [ "${ode_PATCH}"x != x ] && [ -f "${ode_PATCH}" ]; then
    echo Patching ODE
    mkdir ${ode_DIR}/patches
    for P in ${ode_PATCH}; do
        cp -v ${PATCHESDIR}/$P ${ode_DIR}/patches/;
        echo $(basename $P) >>${ode_DIR}/series;
    done
    if !(cd $ode_DIR; quilt push -a); then
	      echo "Error applying patches for ODE."
	      exit
    fi
fi

case $(uname) in
	CYGWIN*)
    echo Compiling $ode_DIR DebugLib
    if !( "$COMPILE" /Build DebugLib $(cygpath -w $ode_DIR/$ode_SLN ) /Project ode /Out compile.log ); then
	   echo "Error compiling $ode_DIR" DebugLib
	   cat compile.log
	   exit
    fi
    rm compile.log >/dev/null 2>&1
    echo Compiling $ode_DIR ReleaseLib
    if !( "$COMPILE" /Build ReleaseLib $(cygpath -w $ode_DIR/$ode_SLN ) /Project ode /Out compile.log ); then
	   echo "Error compiling $ode_DIR" ReleaseLib
	   cat compile.log
	   exit
    fi
    rm compile.log >/dev/null 2>&1
	;;

	*)
    echo Configuring $ode_DIR
    if !(cd $ode_DIR && env ./configure ${CONFIGURE_ARGS} --disable-shared --disable-demos); then
    	echo "Error configuring $ode_DIR"
	    exit
    fi

    echo Compiling $ode_DIR
    if !(cd $ode_DIR && $MAKE); then
	    echo "Error compiling $ode_DIR"
    	exit
    fi

    ;;
esac

fi

echo
echo ODE Done.
echo
}

chai3d() {
chai_URL=http://chai3d.org/download/chai3d-3.2.0-multiplatform.zip
chai_TAR=$TARBALLSDIR/chai3d-3.2.0-multiplatform.zip
chai_MD5=ad51b811c1c1cf39f4c1bb097d3f69ff
if [ -z $chai_DIR ]; then
   chai_DIR=chai3d-3.2.0
fi

if [ -n "${DIMPLE_DEBUG}" ]; then
    CHAI_CFG=debug
else
    CHAI_CFG=release
fi
CHAI_MAKE_ARGS="$CHAI_MAKE_ARGS CFG=$CHAI_CFG"

if ! [ -d $chai_DIR ]; then

if [ $($MD5 "$chai_TAR" | $MD5CUT)x != ${chai_MD5}x ]; then
    echo Downloading $chai_TAR ...
    if [ -e $chai_TAR ]; then rm -v $chai_TAR; fi
    $DL "$chai_TAR" $chai_URL
fi

if [ $($MD5 "$chai_TAR" | $MD5CUT)x != ${chai_MD5}x ]; then
    echo "Error in MD5 checksum for $chai_TAR"
    exit
fi
fi

if ! [ -d $chai_DIR ]; then
echo Extracting "$chai_TAR" ...
if !(unzip -q -o "$chai_TAR"); then
    echo "Error in archive.";
    exit
fi

if [ "${chai_PATCH}"x != x ]; then
    echo Patching chai3d
    mkdir ${chai_DIR}/patches
    for P in ${chai_PATCH}; do
        cp -v ${PATCHESDIR}/$P ${chai_DIR}/patches/;
        echo $(basename $P) >>${chai_DIR}/series;
    done
    if !(cd $chai_DIR; quilt push -a); then
	      echo "Error applying patches for CHAI."
	      exit
    fi
fi

case $(uname) in
	CYGWIN*)
    echo Compiling $chai_DIR Debug
    if !( "$COMPILE" /Build Debug $(cygpath -w $chai_DIR/chai3d_complete.sln ) /Project chai3d_complete /Out compile.log ); then
       echo "Error compiling $chai_DIR" Debug
       cat compile.log
  	   exit
    fi
    rm compile.log >/dev/null 2>&1
    echo Compiling $chai_DIR Release
    if !( "$COMPILE" /Build Release $(cygpath -w $chai_DIR/chai3d_complete.sln ) /Project chai3d_complete /Out compile.log ); then
       echo "Error compiling $chai_DIR" Release
       cat compile.log
  	   exit
    fi
    rm compile.log >/dev/null 2>&1
	;;

	*)
      echo Compiling $chai_DIR
    if !(cd $chai_DIR && $MAKE $CHAI_MAKE_ARGS || (cmake . $CMAKE_ARGS $CMAKE_EXTRA "$CMAKE_GEN" && $MAKE)); then
        echo "Error compiling $chai_DIR"
        exit
    fi
    if [ -e $chai_DIR/libchai3d.a ]; then
	chai_LIBDIR=$chai_DIR
    else
	chai_LIBDIR=$chai_DIR/lib/$CHAI_CFG/$(ls $chai_DIR/lib/$CHAI_CFG | head)
    fi
    if ! [ -e $chai_LIBDIR/libchai3d.a ]; then
        echo "Build CHAI but can't find libchai3d.a in $chai_LIBDIR"
        exit
    fi
    chai_INCDIR=$chai_DIR/src
    if ! [ -e $chai_INCDIR/chai3d.h ]; then
        echo "Can't find chai3d.h in $chai_INCDIR"
        exit
    fi
   ;;
esac

fi

echo
echo Chai3d Done.
echo
}

freeglut() {
freeglut_URL=https://downloads.sourceforge.net/freeglut/3.0.0/freeglut-3.0.0.tar.gz
freeglut_TAR=$TARBALLSDIR/freeglut-3.0.0.tar.gz
freeglut_DIR=freeglut-3.0.0
freeglut_MD5=90c3ca4dd9d51cf32276bc5344ec9754

if ! [ -d $freeglut_DIR ]; then

if [ $($MD5 "$freeglut_TAR" | $MD5CUT)x != ${freeglut_MD5}x ]; then
    echo Downloading $freeglut_TAR ...
    if [ -e $freeglut_TAR ]; then rm -v $freeglut_TAR; fi
    $DL "$freeglut_TAR" $freeglut_URL
fi

if [ $($MD5 "$freeglut_TAR" | $MD5CUT)x != ${freeglut_MD5}x ]; then
    echo "Error in MD5 checksum for $freeglut_TAR"
    exit
fi
fi

if ! [ -d $freeglut_DIR ]; then
echo Extracting "$freeglut_TAR" ...
if !(tar -xzf "$freeglut_TAR"); then
    echo "Error in archive.";
    exit
fi

if [ "${freeglut_PATCH}"x != x ]; then
    echo Patching freeglut
    mkdir ${freeglut_DIR}/patches
    for P in ${freeglut_PATCH}; do
        cp -v ${PATCHESDIR}/$P ${freeglut_DIR}/patches/;
        echo $(basename $P) >>${freeglut_DIR}/series;
    done
    if !(cd $freeglut_DIR; quilt push -a); then
	      echo "Error applying patches for freeglut."
	      exit
    fi
fi

case $(uname) in
	CYGWIN*)
	if [ ${vs_VER}x == 2003x ]; then
		echo Setting back version for solution \& project
		sed 's/Version [0-9,.]*/Version 8.00/' $freeglut_DIR/freeglut.sln --in-place
		sed 's/Version="[0-9,.]*"/Version="7.10"/' $freeglut_DIR/freeglut.vcproj --in-place
		sed 's/Version="[0-9,.]*"/Version="7.10"/' $freeglut_DIR/freeglut_static.vcproj --in-place
	fi
    echo Compiling $freeglut_DIR Debug
    if !( "$COMPILE" /Build Debug $(cygpath -w $freeglut_DIR/freeglut.sln ) /Project freeglut_static /Out compile.log ); then
       echo "Error compiling $freeglut_DIR" Debug
       cat compile.log
  	   exit
    fi
    rm compile.log >/dev/null 2>&1
    echo Compiling $freeglut_DIR Release
    if !( "$COMPILE" /Build Release $(cygpath -w $freeglut_DIR/freeglut.sln ) /Project freeglut_static /Out compile.log ); then
       echo "Error compiling $freeglut_DIR" Release
       cat compile.log
  	   exit
    fi
    rm compile.log >/dev/null 2>&1
	;;

    *)
    echo Configuring $freeglut_DIR
    if !(cd $freeglut_DIR && cmake . $CMAKE_ARGS $CMAKE_EXTRA "$CMAKE_GEN" -DFREEGLUT_BUILD_STATIC_LIBS=ON  -DFREEGLUT_BUILD_SHARED_LIBS=OFF); then
        echo "Error configuring $freeglut_DIR"
        exit
    fi

    echo Compiling $freeglut_DIR
    if !(cd $freeglut_DIR && $MAKE); then
	    echo "Error compiling $freeglut_DIR"
    	exit
    fi    
    ;;
esac

fi

echo
echo FreeGLUT Done.
echo
}

atomicops() {
atomicops_URL=http://www.hpl.hp.com/research/linux/atomic_ops/download/libatomic_ops-1.2.tar.gz
atomicops_TAR=$TARBALLSDIR/libatomic_ops-1.2.tar.gz
atomicops_DIR=libatomic_ops-1.2
atomicops_MD5=1b65e48271c81e3fa2d7a9a69bab7504

if ! [ -d $atomicops_DIR ]; then

if [ $($MD5 "$atomicops_TAR" | $MD5CUT)x != ${atomicops_MD5}x ]; then
    echo Downloading $atomicops_TAR ...
    if [ -e $atomicops_TAR ]; then rm -v $atomicops_TAR; fi
    $DL "$atomicops_TAR" $atomicops_URL
fi

if [ $($MD5 "$atomicops_TAR" | $MD5CUT)x != ${atomicops_MD5}x ]; then
    echo "Error in MD5 checksum for $atomicops_TAR"
    exit
fi
fi

if ! [ -d $atomicops_DIR ]; then
echo Extracting "$atomicops_TAR" ...
if !(tar -xzf "$atomicops_TAR"); then
    echo "Error in archive.";
    exit
fi

if [ "${atomicops_PATCH}"x != x ]; then
    echo Patching atomicops
    mkdir ${atomicops_DIR}/patches
    for P in ${atomicops_PATCH}; do
        cp -v ${PATCHESDIR}/$P ${atomicops_DIR}/patches/;
        echo $(basename $P) >>${atomicops_DIR}/series;
    done
    if !(cd $atomicops_DIR; quilt push -a); then
	      echo "Error applying patches for atomicops."
	      exit
    fi
fi

fi

echo
echo atomic_ops Done.
echo
}


pthreads() {
pthreads_URL=ftp://sourceware.org/pub/pthreads-win32/pthreads-w32-2-8-0-release.tar.gz
pthreads_TAR=$TARBALLSDIR/pthreads-w32-2-8-0-release.tar.gz
pthreads_DIR=pthreads-w32-2-8-0-release
pthreads_MD5=6d30c693233b1464ef8983fedd8ccb22

if ! [ -d $pthreads_DIR ]; then

if [ $($MD5 "$pthreads_TAR" | $MD5CUT)x != ${pthreads_MD5}x ]; then
    echo Downloading $pthreads_TAR ...
    if [ -e $pthreads_TAR ]; then rm -v $pthreads_TAR; fi
    $DL "$pthreads_TAR" $pthreads_URL
fi

if [ $($MD5 "$pthreads_TAR" | $MD5CUT)x != ${pthreads_MD5}x ]; then
    echo "Error in MD5 checksum for $pthreads_TAR"
    exit
fi
fi

if ! [ -d $pthreads_DIR ]; then
echo Extracting "$pthreads_TAR" ...
if !(tar -xzf "$pthreads_TAR"); then
    echo "Error in archive.";
    exit
fi

if [ "${pthreads_PATCH}"x != x ]; then
    echo Patching pthreads
    mkdir ${pthreads_DIR}/patches
    for P in ${pthreads_PATCH}; do
        cp -v $P ${PATCHESDIR}/${pthreads_DIR}/patches/;
        echo $(basename $P) >>${pthreads_DIR}/series;
    done
    if !(cd $pthreads_DIR; quilt push -a); then
	      echo "Error applying patches for pthreads."
	      exit
    fi
fi

case $(uname) in
	CYGWIN*)
	if [ ${vs_VER}x == 2003x ]; then
		echo Setting back version for solution \& project
		sed 's/Version [0-9,.]*/Version 8.00/' $pthreads_DIR/pthreads.sln --in-place
		sed 's/Version="[0-9,.]*"/Version="7.10"/' $pthreads_DIR/pthreads.vcproj --in-place
	fi

    echo Compiling $pthreads_DIR Debug
    if !( "$COMPILE" /Build Debug $(cygpath -w $pthreads_DIR/pthreads.sln ) /Project pthreads /Out compile.log ); then
       echo "Error compiling $pthreads_DIR" Debug
       cat compile.log
  	   exit
    fi
    rm compile.log >/dev/null 2>&1
    echo Compiling $pthreads_DIR Release
    if !( "$COMPILE" /Build Release $(cygpath -w $pthreads_DIR/pthreads.sln ) /Project pthreads /Out compile.log ); then
       echo "Error compiling $pthreads_DIR" Release
       cat compile.log
  	   exit
    fi
    rm compile.log >/dev/null 2>&1
	;;

    *)
    echo Compiling $pthreads_DIR
    if !(cd $pthreads_DIR && $MAKE clean GC-static); then
	    echo "Error compiling $pthreads_DIR"
    	exit
    fi

    # needed for liblo build to find it
    cp -v $pthreads_DIR/libpthreadGC2.a $pthreads_DIR/libpthread.a
    ;;
esac

fi

echo
echo pthreads Done.
echo
}

samplerate() {
samplerate_URL="http://www.mega-nerd.com/SRC/libsamplerate-0.1.9.tar.gz"
samplerate_TAR=$TARBALLSDIR/libsamplerate-0.1.9.tar.gz
samplerate_DIR=libsamplerate-0.1.9
samplerate_MD5=2b78ae9fe63b36b9fbb6267fad93f259

if ! [ -d $samplerate_DIR ]; then

if [ $($MD5 "$samplerate_TAR" | $MD5CUT)x != ${samplerate_MD5}x ]; then
    echo Downloading $samplerate_TAR ...
    if [ -e $samplerate_TAR ]; then rm -v $samplerate_TAR; fi
    $DL "$samplerate_TAR" $samplerate_URL
fi

if [ $($MD5 "$samplerate_TAR" | $MD5CUT)x != ${samplerate_MD5}x ]; then
    echo "Error in MD5 checksum for $samplerate_TAR"
    exit
fi
fi

if ! [ -d $samplerate_DIR ]; then
echo Extracting "$samplerate_TAR" ...
if !(tar -xzf "$samplerate_TAR"); then
    echo "Error in archive.";
    exit
fi

if [ "${samplerate_PATCH}"x != x ]; then
    echo Patching samplerate
    mkdir ${samplerate_DIR}/patches
    for P in ${samplerate_PATCH}; do
        cp -v $P ${PATCHESDIR}/${samplerate_DIR}/patches/;
        echo $(basename $P) >>${samplerate_DIR}/series;
    done
    if !(cd $samplerate_DIR; quilt push -a); then
	      echo "Error applying patches for samplerate."
	      exit
    fi
fi

case $(uname) in
	CYGWIN*)
    echo Compiling $samplerate_DIR Debug
    if !( "$COMPILE" $(cygpath -w $samplerate_DIR/$samplerate_SLN ) /Build Debug /Project libsamplerate /Out compile.log ); then
       echo "Error compiling $samplerate_DIR" Debug
       cat compile.log
  	   exit
    fi
    rm compile.log >/dev/null 2>&1
    echo Compiling $samplerate_DIR Release
    if !( "$COMPILE" /Build Release $(cygpath -w $samplerate_DIR/$samplerate_SLN ) /Project libsamplerate /Out compile.log ); then
       echo "Error compiling $samplerate_DIR" Release
       cat compile.log
  	   exit
    fi
    rm compile.log >/dev/null 2>&1
	;;

   *)
   echo Configuring $samplerate_DIR
   if !(cd $samplerate_DIR && ./configure ${CONFIGURE_ARGS} --disable-shared --disable-sndfile); then
	  echo "Error configuring $samplerate_DIR"
	  exit
   fi

   echo Compiling $samplerate_DIR
   if !(cd $samplerate_DIR && $MAKE); then
	  echo "Error compiling $samplerate_DIR"
	  exit
   fi
   
   # Note refuses to compile static version, so...
   echo Creating static lib for $samplerate_DIR
   cd $samplerate_DIR
   rm -vf libsamplerate.{dll,lib,so,dylib}
   mkdir src/.libs
   ar -ruv src/.libs/libsamplerate.a src/src_linear.o src/src_sinc.o \
       src/src_zoh.o src/samplerate.o
   cd ..
   ;;
esac

fi

echo
echo samplerate Done.
echo
}


mingw_std_threads() {
mingw_std_threads_URL="https://github.com/meganz/mingw-std-threads/archive/4e22f33ff3a32a81436582cd0c427893e353516c.tar.gz"
mingw_std_threads_TAR=$TARBALLSDIR/mingw-std-threads-4e22f33ff3.tar.gz
mingw_std_threads_DIR=mingw-std-threads-4e22f33ff3a32a81436582cd0c427893e353516c
mingw_std_threads_MD5=7abcc5c42444f972f721e066a0cff759

if ! [ -d $mingw_std_threads_DIR ]; then

echo $MD5 "$mingw_std_threads_TAR"
echo $($MD5 "$mingw_std_threads_TAR" | $MD5CUT)x
$MD5 "$mingw_std_threads_TAR" | $MD5CUT
$MD5 "$mingw_std_threads_TAR"
if [ $($MD5 "$mingw_std_threads_TAR" | $MD5CUT)x != ${mingw_std_threads_MD5}x ]; then
    echo Downloading $mingw_std_threads_TAR ...
    if [ -e $mingw_std_threads_TAR ]; then rm -v $mingw_std_threads_TAR; fi
    $DL "$mingw_std_threads_TAR" $mingw_std_threads_URL
fi

if [ $($MD5 "$mingw_std_threads_TAR" | $MD5CUT)x != ${mingw_std_threads_MD5}x ]; then
    echo "Error in MD5 checksum for $mingw_std_threads_TAR"
    exit
fi
fi

if ! [ -d $mingw_std_threads_DIR ]; then
echo Extracting "$mingw_std_threads_TAR" ...
if !(tar -xzf "$mingw_std_threads_TAR"); then
    echo "Error in archive.";
    exit
fi

if [ "${mingw_std_threads_PATCH}"x != x ]; then
    echo Patching mingw_std_threads
    mkdir ${mingw_std_threads_DIR}/patches
    for P in ${mingw_std_threads_PATCH}; do
        cp -v $P ${PATCHESDIR}/${mingw_std_threads_DIR}/patches/;
        echo $(basename $P) >>${mingw_std_threads_DIR}/series;
    done
    if !(cd $mingw_std_threads_DIR; quilt push -a); then
	      echo "Error applying patches for mingw_std_threads."
	      exit
    fi
fi

fi

echo
echo mingw_std_threads Done.
echo
}

# -O mingw-std-threads-4e22f33ff3.tar.gz https://github.com/meganz/mingw-std-threads/archive/4e22f33ff3a32a81436582cd0c427893e353516c.tar.gz
# 7abcc5c42444f972f721e066a0cff759  4e22f33ff3a32a81436582cd0c427893e353516c.tar.gz

if ! [ -d $LIBDEPSDIR  ]; then mkdir $LIBDEPSDIR  || exit 1; fi
if ! [ -d $TARBALLSDIR ]; then mkdir $TARBALLSDIR || exit 1; fi
cd $LIBDEPSDIR || exit 1

echo "Looking for programs.."
which quilt >/dev/null || ( echo "error: quilt not found."; false ) || exit 1
which unzip >/dev/null || (echo "error: unzip not found."; false ) || exit 1

# Configs for any system
chai_PATCH="chai3d-clearFromContact.patch chai3d-force-scale.patch"

# System-dependant bootstrapping
case $(uname) in
    MINGW32* | MINGW64* | MSYS*)
    DL="curl -L -o"
    MD5=md5sum
    MD5CUT="awk {print\$1}"
    liblo_LIBS="-lws2_32 -liphlpapi"
    liblo_CONFIGEXTRA="--disable-ipv6 --with-win32-threads --enable-static --disable-shared"
    chai_DIR=chai3d-3.2.0
    chai_PATCH="chai3d-clearFromContact.patch chai3d-force-scale.patch chai3d-tdleap-mingw64.patch"
    CMAKE_GEN='MSYS Makefiles'
    CMAKE_EXTRA=-G

    export QUILTRC=1 # otherwise line ending errors
    export QUILT_PATCH_OPTS=--binary

    echo "Looking for programs.."
    which cmake >/dev/null || (echo "cmake not found."; false ) || exit 1

    freeglut
    samplerate
    ode
    liblo
    chai3d
    ;;

    CYGWIN*)
	DL="wget -O"
    MD5=md5sum
	MD5CUT="awk {print\$1}"
	freeglut_PATCH=freeglut-2.4.0-vs2005exp.patch
	pthreads_PATCH=pthreads-w32-2-8-0-release-vs2005exp-static.patch

	COMPILE="$(echo $(cygpath -u $PROGRAMFILES)/Microsoft Visual Studio .NET 2003/Common7/IDE/devenv.exe)"
	if !( [ -f "$COMPILE" ]); then
		COMPILE="$(echo $(cygpath -u $PROGRAMFILES)/Microsoft Visual Studio 8/Common7/IDE/VCExpress.exe)"
		if !( [ -f "$COMPILE" ]); then
			echo "Couldn't find Visual Studio 2003 or 2005 Express.  Please edit the line COMPILE= in this file (bootstrap.sh)"
			exit
		else
			vs_VER=2005
			ode_SLN=build/vs2005/ode.sln
			ode_PATCH=ode-0.7-vs2005exp.patch
			liblo_PATCH=liblo-0.23-vs2005exp.patch
			samplerate_PATCH=libsamplerate-0.1.2-vs2005exp.patch
			samplerate_SLN=Win32/libsamplerate-vs2005exp.sln
			chai_DIR=chai3d/msvc8exp
		fi
	else
		vs_VER=2003
		ode_SLN=build/vs2003/ode.sln
		ode_PATCH=ode-0.7-msvc7.patch
		liblo_PATCH=liblo-0.23-msvc7.patch
        samplerate_PATCH=libsamplerate-0.1.2-vs2003.patch
		samplerate_SLN=Win32/libsamplerate-vs2003.sln
		chai_DIR=chai3d/msvc7
	fi

	pthreads
	freeglut
    samplerate
    ode
    liblo
	chai3d
	atomicops

	cd ..
    SLN=dimple.vs2005exp.sln
	if [ ${vs_VER}x == 2003x ]; then
        SLN=dimple.vs2003.sln
	fi

	echo Now open $SLN in Visual Studio and build.
    ;;

    Linux*)
	DL="wget -O"
    MD5=md5sum
	MD5CUT="awk {print\$1}"

	ode
    chai3d
	liblo
#    echo For Linux, please get package \"liblo\" from your distribution.
#    echo Ubuntu and Debian: sudo apt-get install liblo0-dev
    if [ x$MINGW_ON_LINUX = x1 ]; then
      freeglut
      samplerate
      mingw_std_threads
    fi
    exit
	;;

	Darwin*)
	DL="curl -Lo"
    MD5=md5
	MD5CUT="cut -f2 -d="
    samplerate
    ode
	liblo
	chai3d
    ;;
    *)
    echo Your system is not supported by this script.
    echo Please acquire the \"liblo\" and \"ode\" packages manually.
    exit
    ;;
esac

