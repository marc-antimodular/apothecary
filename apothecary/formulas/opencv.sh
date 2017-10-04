#! /bin/bash
#
# OpenCV
# library of programming functions mainly aimed at real-time computer vision
# http://opencv.org
#
# uses a CMake build system

FORMULA_TYPES=( "osx" "ios" "tvos" "vs" "android" "emscripten" )

# define the version ; can be HEAD or a tag, like 3.3.0
VER=3.3.0

# tools for git use
GIT_BASE_URL=https://github.com/opencv
GIT_URL=$GIT_BASE_URL/opencv.git
GIT_TAG=$VER

# these paths don't really matter - they are set correctly further down
local LIB_FOLDER="$BUILD_ROOT_DIR/opencv"
local LIB_FOLDER32="$LIB_FOLDER-32"
local LIB_FOLDER64="$LIB_FOLDER-64"
local LIB_FOLDER_IOS="$LIB_FOLDER-IOS"
local LIB_FOLDER_IOS_SIM="$LIB_FOLDER-IOSIM"

# download the source code and unpack it into LIB_NAME
function download() {
    if [ "$TYPE" != "android" ]; then
        # get opencv
        rm -rf opencv-${VER} opencv
        rm -f ${VER}.zip
        curl -L -O ${GIT_BASE_URL}/opencv/archive/${VER}.zip
        unzip -aq ${VER}.zip
        mv opencv-${VER} opencv
        # get opencv_contrib
        rm -rf opencv_contrib-${VER} opencv_contrib
        rm -f ${VER}.zip
        curl -L -O ${GIT_BASE_URL}/opencv_contrib/archive/${VER}.zip
        unzip -aq ${VER}.zip
        mv opencv_contrib-${VER} opencv_contrib
        # patch CMakeLists.txt to use C++14
        cd opencv
        sed s/XX11/XX14/g CMakeLists.txt > CMakeLists.txt.tmp
        sed s/\+\+11/\+\+14/g CMakeLists.txt.tmp > CMakeLists.txt.tmp2
        rm CMakeLists.txt.tmp
        mv -f CMakeLists.txt.tmp2 CMakeLists.txt
    else
        wget http://sourceforge.net/projects/opencvlibrary/files/opencv-android/${VER}/OpenCV-${VER}-android-sdk.zip/download -O OpenCV-${VER}-android-sdk.zip
        unzip -qo OpenCV-${VER}-android-sdk.zip
        mv OpenCV-android-sdk $1
    fi
}

# prepare the build environment, executed inside the lib src dir
function prepare() {
    : #noop
}

# executed inside the lib src dir
function build() {
  rm -f CMakeCache.txt

  LIB_FOLDER="$BUILD_DIR/opencv/build/$TYPE/"
  mkdir -p $LIB_FOLDER

  if [ "$TYPE" == "osx" ] ; then
    LOG="$LIB_FOLDER/opencv2-${VER}.log"
    echo "Logging to $LOG"
    cd build
    rm -f CMakeCache.txt
    echo "Log:" >> "${LOG}" 2>&1
    set +e
      cmake .. -DCMAKE_INSTALL_PREFIX=$LIB_FOLDER \
      -DCMAKE_OSX_DEPLOYMENT_TARGET=10.9 \
      -DCMAKE_CXX_FLAGS="-fvisibility-inlines-hidden -stdlib=libc++ -std=c++14 -O3 -fPIC" \
      -DCMAKE_C_FLAGS="-fvisibility-inlines-hidden -stdlib=libc++ -O3 -fPIC" \
      -DCMAKE_BUILD_TYPE="Release" \
      -DBUILD_SHARED_LIBS=OFF \
      -DBUILD_DOCS=OFF \
      -DBUILD_EXAMPLES=OFF \
      -DBUILD_FAT_JAVA_LIB=OFF \
      -DBUILD_JASPER=OFF \
      -DBUILD_PACKAGE=OFF \
      -DBUILD_opencv_java=OFF \
      -DBUILD_opencv_python=OFF \
      -DBUILD_opencv_apps=OFF \
      -DBUILD_JPEG=OFF \
      -DBUILD_PNG=OFF \
      -DWITH_1394=OFF \
      -DWITH_CARBON=OFF \
      -DWITH_JPEG=OFF \
      -DWITH_PNG=OFF \
      -DWITH_FFMPEG=OFF \
      -DWITH_OPENCL=OFF \
      -DWITH_OPENCLAMDBLAS=OFF \
      -DWITH_OPENCLAMDFFT=OFF \
      -DWITH_VA_INTEL=OFF \
      -DWITH_GIGEAPI=OFF \
      -DWITH_CUDA=OFF \
      -DWITH_CUFFT=OFF \
      -DWITH_JASPER=OFF \
      -DWITH_LIBV4L=OFF \
      -DWITH_IMAGEIO=OFF \
      -DWITH_IPP=OFF \
      -DWITH_OPENNI=OFF \
      -DWITH_QT=OFF \
      -DWITH_QUICKTIME=OFF \
      -DWITH_WEBP=OFF \
      -DWITH_V4L=OFF \
      -DWITH_PVAPI=OFF \
      -DWITH_OPENEXR=OFF \
      -DWITH_EIGEN=OFF \
      -DBUILD_TESTS=OFF \
      -DBUILD_PERF_TESTS=OFF \
      -DOPENCV_EXTRA_MODULES_PATH=../../opencv_contrib/modules \
      -DTINYDNN_USE_SSE=ON \
      -DTINYDNN_USE_AVX=ON \
      2>&1 | tee -a ${LOG}

    echo "CMAKE Successful"
    echo "--------------------"
    echo "Running make clean"

    make clean 2>&1 | tee -a ${LOG}
    echo "Make Clean Successful"

    echo "--------------------"
    echo "Running make"
    make -j${PARALLEL_MAKE} 2>&1 | tee -a ${LOG}
    echo "Make  Successful"

    echo "--------------------"
    echo "Running make install"
    make install 2>&1 | tee -a ${LOG}
    echo "Make install Successful"

    echo "--------------------"
    echo "Joining all libs in one"
    outputlist="lib/lib*.a 3rdparty/lib/libittnotify.a 3rdparty/lib/liblibprotobuf.a"
    # outputlist=$(find lib 3rdparty -name "*.a")
    libtool -static $outputlist -o "$LIB_FOLDER/lib/opencv.a" 2>&1 | tee -a ${LOG}
    echo "Joining all libs in one Successful"

    echo "--------------------"
    echo "Fixing permissions"
    find "$LIB_FOLDER" -type f -perm 755 -exec chmod 644 "{}" \; 2>&1 | tee -a ${LOG}
    echo "Fixing permissions Successful"


  elif [ "$TYPE" == "vs" ] ; then
    unset TMP
    unset TEMP

    rm -f CMakeCache.txt
    #LIB_FOLDER="$BUILD_DIR/opencv/build/$TYPE"
    mkdir -p $LIB_FOLDER
    LOG="$LIB_FOLDER/opencv2-${VER}.log"
    echo "Logging to $LOG"
    echo "Log:" >> "${LOG}" 2>&1
    set +e
    if [ $ARCH == 32 ] ; then
        mkdir -p build_vs_32
        cd build_vs_32
        cmake .. -G "Visual Studio $VS_VER"\
        -DBUILD_PNG=OFF \
        -DWITH_OPENCLAMDBLAS=OFF \
        -DBUILD_TESTS=OFF \
        -DWITH_CUDA=OFF \
        -DWITH_FFMPEG=OFF \
        -DWITH_WIN32UI=OFF \
        -DBUILD_PACKAGE=OFF \
        -DWITH_JASPER=OFF \
        -DWITH_OPENEXR=OFF \
        -DWITH_GIGEAPI=OFF \
        -DWITH_JPEG=OFF \
        -DBUILD_WITH_DEBUG_INFO=OFF \
        -DWITH_CUFFT=OFF \
        -DBUILD_TIFF=OFF \
        -DBUILD_JPEG=OFF \
        -DWITH_OPENCLAMDFFT=OFF \
        -DBUILD_WITH_STATIC_CRT=OFF \
        -DBUILD_opencv_java=OFF \
        -DBUILD_opencv_python=OFF \
        -DBUILD_opencv_apps=OFF \
        -DBUILD_PERF_TESTS=OFF \
        -DBUILD_JASPER=OFF \
        -DBUILD_DOCS=OFF \
        -DWITH_TIFF=OFF \
        -DWITH_1394=OFF \
        -DWITH_EIGEN=OFF \
        -DBUILD_OPENEXR=OFF \
        -DWITH_DSHOW=OFF \
        -DWITH_VFW=OFF \
        -DBUILD_SHARED_LIBS=OFF \
        -DWITH_PNG=OFF \
        -DWITH_OPENCL=OFF \
        -DWITH_PVAPI=OFF  | tee ${LOG}
        vs-build "OpenCV.sln"
        vs-build "OpenCV.sln" Build "Debug"
    elif [ $ARCH == 64 ] ; then
        mkdir -p build_vs_64
        cd build_vs_64
        cmake .. -G "Visual Studio $VS_VER Win64" \
        -DBUILD_PNG=OFF \
        -DWITH_OPENCLAMDBLAS=OFF \
        -DBUILD_TESTS=OFF \
        -DWITH_CUDA=OFF \
        -DWITH_FFMPEG=OFF \
        -DWITH_WIN32UI=OFF \
        -DBUILD_PACKAGE=OFF \
        -DWITH_JASPER=OFF \
        -DWITH_OPENEXR=OFF \
        -DWITH_GIGEAPI=OFF \
        -DWITH_JPEG=OFF \
        -DBUILD_WITH_DEBUG_INFO=OFF \
        -DWITH_CUFFT=OFF \
        -DBUILD_TIFF=OFF \
        -DBUILD_JPEG=OFF \
        -DWITH_OPENCLAMDFFT=OFF \
        -DBUILD_WITH_STATIC_CRT=OFF \
        -DBUILD_opencv_java=OFF \
        -DBUILD_opencv_python=OFF \
        -DBUILD_opencv_apps=OFF \
        -DBUILD_PERF_TESTS=OFF \
        -DBUILD_JASPER=OFF \
        -DBUILD_DOCS=OFF \
        -DWITH_TIFF=OFF \
        -DWITH_1394=OFF \
        -DWITH_EIGEN=OFF \
        -DBUILD_OPENEXR=OFF \
        -DWITH_DSHOW=OFF \
        -DWITH_VFW=OFF \
        -DBUILD_SHARED_LIBS=OFF \
        -DWITH_PNG=OFF \
        -DWITH_OPENCL=OFF \
        -DWITH_PVAPI=OFF  | tee ${LOG}
        vs-build "OpenCV.sln" Build "Release|x64"
        vs-build "OpenCV.sln" Build "Debug|x64"
    fi

  elif [[ "$TYPE" == "ios" || "${TYPE}" == "tvos" ]] ; then
    local IOS_ARCHS
    if [[ "${TYPE}" == "tvos" ]]; then
        IOS_ARCHS="x86_64 arm64"
    elif [[ "$TYPE" == "ios" ]]; then
        IOS_ARCHS="i386 x86_64 armv7 arm64" #armv7s
    fi
    CURRENTPATH=`pwd`

      # loop through architectures! yay for loops!
    for IOS_ARCH in ${IOS_ARCHS}
    do
      source ${APOTHECARY_DIR}/ios_configure.sh $TYPE $IOS_ARCH

      cmake . -DCMAKE_INSTALL_PREFIX="$CURRENTPATH/build/$TYPE/$IOS_ARCH" \
      -DIOS=1 \
      -DAPPLE=1 \
      -DUNIX=1 \
      -DCMAKE_CXX_COMPILER=$CXX \
      -DCMAKE_CC_COMPILER=$CC \
      -DIPHONESIMULATOR=$ISSIM \
      -DCMAKE_CXX_COMPILER_WORKS="TRUE" \
      -DCMAKE_C_COMPILER_WORKS="TRUE" \
      -DSDKVER="${SDKVERSION}" \
      -DCMAKE_IOS_DEVELOPER_ROOT="${CROSS_TOP}" \
      -DDEVROOT="${CROSS_TOP}" \
      -DSDKROOT="${CROSS_SDK}" \
      -DCMAKE_OSX_SYSROOT="${SYSROOT}" \
      -DCMAKE_OSX_ARCHITECTURES="${IOS_ARCH}" \
      -DCMAKE_XCODE_EFFECTIVE_PLATFORMS="-$PLATFORM" \
      -DGLFW_BUILD_UNIVERSAL=ON \
      -DENABLE_FAST_MATH=OFF \
      -DCMAKE_CXX_FLAGS="-stdlib=libc++ -fvisibility=hidden $BITCODE -fPIC -isysroot ${SYSROOT} -DNDEBUG -Os $MIN_TYPE$MIN_IOS_VERSION" \
      -DCMAKE_C_FLAGS="-stdlib=libc++ -fvisibility=hidden $BITCODE -fPIC -isysroot ${SYSROOT} -DNDEBUG -Os $MIN_TYPE$MIN_IOS_VERSION"  \
      -DCMAKE_BUILD_TYPE="Release" \
      -DBUILD_SHARED_LIBS=OFF \
      -DBUILD_DOCS=OFF \
      -DBUILD_EXAMPLES=OFF \
      -DBUILD_FAT_JAVA_LIB=OFF \
      -DBUILD_JASPER=OFF \
      -DBUILD_PACKAGE=OFF \
      -DBUILD_opencv_java=OFF \
      -DBUILD_opencv_python=OFF \
      -DBUILD_opencv_apps=OFF \
      -DBUILD_opencv_videoio=OFF \
      -DBUILD_JPEG=OFF \
      -DBUILD_PNG=OFF \
      -DWITH_1394=OFF \
      -DWITH_JPEG=OFF \
      -DWITH_PNG=OFF \
      -DWITH_CARBON=OFF \
      -DWITH_FFMPEG=OFF \
      -DWITH_OPENCL=OFF \
      -DWITH_OPENCLAMDBLAS=OFF \
      -DWITH_OPENCLAMDFFT=OFF \
      -DWITH_GIGEAPI=OFF \
      -DWITH_CUDA=OFF \
      -DWITH_CUFFT=OFF \
      -DWITH_JASPER=OFF \
      -DWITH_LIBV4L=OFF \
      -DWITH_IMAGEIO=OFF \
      -DWITH_IPP=OFF \
      -DWITH_OPENNI=OFF \
      -DWITH_QT=OFF \
      -DWITH_QUICKTIME=OFF \
      -DWITH_V4L=OFF \
      -DWITH_PVAPI=OFF \
      -DWITH_EIGEN=OFF \
      -DWITH_OPENEXR=OFF \
      -DBUILD_OPENEXR=OFF \
      -DBUILD_TESTS=OFF \
      -DBUILD_PERF_TESTS=OFF \
      -DTINYDNN_USE_SSE=ON \
      -DTINYDNN_USE_AVX=ON \



        echo "--------------------"
        echo "Running make clean for ${IOS_ARCH}"
        make clean

        echo "--------------------"
        echo "Running make for ${IOS_ARCH}"
        make -j${PARALLEL_MAKE}

        echo "--------------------"
        echo "Running make install for ${IOS_ARCH}"
        make install

        rm -f CMakeCache.txt
    done

    mkdir -p lib/$TYPE
    echo "--------------------"
    echo "Creating Fat Libs"
    cd "build/$TYPE"
    # link into universal lib, strip "lib" from filename
    local lib
    rm -rf arm64/lib/pkgconfig

    for lib in $( ls -1 arm64/lib) ; do
      local renamedLib=$(echo $lib | sed 's|lib||')
      if [ ! -e $renamedLib ] ; then
        echo "renamed";
        if [[ "${TYPE}" == "tvos" ]] ; then
          lipo -c arm64/lib/$lib x86_64/lib/$lib -o "$CURRENTPATH/lib/$TYPE/$renamedLib"
        elif [[ "$TYPE" == "ios" ]]; then
          lipo -c armv7/lib/$lib arm64/lib/$lib i386/lib/$lib x86_64/lib/$lib -o "$CURRENTPATH/lib/$TYPE/$renamedLib"
        fi
      fi
    done

    cd ../../
    echo "--------------------"
    echo "Copying includes"
    cp -R "build/$TYPE/x86_64/include/" "lib/include/"

    echo "--------------------"
    echo "Stripping any lingering symbols"

    cd lib/$TYPE
    for TOBESTRIPPED in $( ls -1) ; do
      strip -x $TOBESTRIPPED
    done

    cd ../../

  # end if iOS
  elif [ "$TYPE" == "emscripten" ]; then
    mkdir -p build_${TYPE}
    cd build_${TYPE}
    emcmake cmake .. -DCMAKE_INSTALL_PREFIX="${BUILD_DIR}/${1}/build_$TYPE/install" \
      -DCMAKE_BUILD_TYPE="Release" \
      -DCMAKE_C_FLAGS=-I${EMSCRIPTEN}/system/lib/libcxxabi/include/ \
      -DCMAKE_CXX_FLAGS=-I${EMSCRIPTEN}/system/lib/libcxxabi/include/ \
      -DBUILD_SHARED_LIBS=OFF \
      -DBUILD_DOCS=OFF \
      -DBUILD_EXAMPLES=OFF \
      -DBUILD_FAT_JAVA_LIB=OFF \
      -DBUILD_JASPER=OFF \
      -DBUILD_PACKAGE=OFF \
      -DBUILD_CUDA_STUBS=OFF \
      -DBUILD_opencv_java=OFF \
      -DBUILD_opencv_python=OFF \
      -DBUILD_opencv_apps=OFF \
      -DBUILD_JPEG=OFF \
      -DBUILD_PNG=OFF \
      -DBUILD_opencv_apps=OFF \
      -DBUILD_opencv_videoio=OFF \
      -DBUILD_opencv_highgui=OFF \
      -DBUILD_opencv_imgcodecs=OFF \
      -DBUILD_opencv_python2=OFF \
      -DENABLE_SSE=OFF \
      -DENABLE_SSE2=OFF \
      -DENABLE_SSE3=OFF \
      -DENABLE_SSE41=OFF \
      -DENABLE_SSE42=OFF \
      -DENABLE_SSSE3=OFF \
      -DENABLE_AVX=OFF \
      -DWITH_TIFF=OFF \
      -DWITH_OPENEXR=OFF \
      -DWITH_1394=OFF \
      -DWITH_JPEG=OFF \
      -DWITH_PNG=OFF \
      -DWITH_FFMPEG=OFF \
      -DWITH_OPENCL=OFF \
      -DWITH_GIGEAPI=OFF \
      -DWITH_CUDA=OFF \
      -DWITH_CUFFT=OFF \
      -DWITH_FFMPEG=OFF \
      -DWITH_GIGEAPI=OFF \
      -DWITH_GPHOTO2=OFF \
      -DWITH_GSTREAMER=OFF \
      -DWITH_GSTREAMER_0_10=OFF \
      -DWITH_JASPER=OFF \
      -DWITH_IMAGEIO=OFF \
      -DWITH_IPP=OFF \
      -DWITH_IPP_A=OFF \
      -DWITH_TBB=OFF \
      -DWITH_OPENNI=OFF \
      -DWITH_QT=OFF \
      -DWITH_QUICKTIME=OFF \
      -DWITH_V4L=OFF \
      -DWITH_LIBV4L=OFF \
      -DWITH_MATLAB=OFF \
      -DWITH_OPENCL=OFF \
      -DWITH_OPENCLCLAMDBLAS=OFF \
      -DWITH_OPENCLCLAMDFFT=OFF \
      -DWITH_OPENCL_SVM=OFF \
      -DWITH_WEBP=OFF \
      -DWITH_VTK=OFF \
      -DWITH_PVAPI=OFF \
      -DWITH_EIGEN=OFF \
      -DBUILD_TESTS=OFF \
      -DBUILD_PERF_TESTS=OFF
    make -j${PARALLEL_MAKE}
    make install
  fi

}


# executed inside the lib src dir, first arg $1 is the dest libs dir root
function copy() {

  # prepare headers directory if needed
  mkdir -p $1/include

  # prepare libs directory if needed
  mkdir -p $1/lib/$TYPE

  if [ "$TYPE" == "osx" ] ; then
    # Standard *nix style copy.
    # copy headers

    LIB_FOLDER="$BUILD_DIR/opencv/build/$TYPE/"

    # copy include folder from opencv
    cp -R $LIB_FOLDER/include/ $1/include/

    # aggregate include/opencv2 folders from opencv_contrib modules
    this_dir=$(pwd)
    modules_dir="$BUILD_DIR/opencv_contrib/modules"
    for d in $(find . -type d -name "opencv2" -maxdepth 1); do
        cd "$modules_dir"
        cd "$d" && tar cf - . | (cd $1/include/opencv2; tar xf -)
    done
    cd "$this_dir"

    # copy lib
    cp -R $LIB_FOLDER/lib/opencv.a $1/lib/$TYPE/

  elif [ "$TYPE" == "vs" ] ; then
        if [ $ARCH == 32 ] ; then
      DEPLOY_PATH="$1/lib/$TYPE/Win32"
        elif [ $ARCH == 64 ] ; then
            DEPLOY_PATH="$1/lib/$TYPE/x64"
        fi
      mkdir -p "$DEPLOY_PATH/Release"
      mkdir -p "$DEPLOY_PATH/Debug"
      # now make sure the target directories are clean.
      rm -Rf "${DEPLOY_PATH}/Release/*"
      rm -Rf "${DEPLOY_PATH}/Debug/*"
      #copy the cv libs
      cp -v build_vs_${ARCH}/lib/Release/*.lib "${DEPLOY_PATH}/Release"
      cp -v build_vs_${ARCH}/lib/Debug/*.lib "${DEPLOY_PATH}/Debug"
      #copy the zlib
      cp -v build_vs_${ARCH}/3rdparty/lib/Release/*.lib "${DEPLOY_PATH}/Release"
      cp -v build_vs_${ARCH}/3rdparty/lib/Debug/*.lib "${DEPLOY_PATH}/Debug"

      cp -R include/opencv $1/include/
      cp -R include/opencv2 $1/include/
      cp -R modules/*/include/opencv2/* $1/include/opencv2/

      #copy the ippicv includes and lib
      IPPICV_SRC=3rdparty/ippicv/unpack/ippicv_win
      IPPICV_DST=$1/../ippicv
      if [ $ARCH == 32 ] ; then
        IPPICV_PLATFORM="ia32"
        IPPICV_DEPLOY="${IPPICV_DST}/lib/$TYPE/Win32"
      elif [ $ARCH == 64 ] ; then
        IPPICV_PLATFORM="intel64"
        IPPICV_DEPLOY="${IPPICV_DST}/lib/$TYPE/x64"
      fi
      mkdir -p ${IPPICV_DST}/include
      cp -R ${IPPICV_SRC}/include/ ${IPPICV_DST}/
      mkdir -p ${IPPICV_DEPLOY}
      cp -v ${IPPICV_SRC}/lib/${IPPICV_PLATFORM}/*.lib "${IPPICV_DEPLOY}"

  elif [[ "$TYPE" == "ios" || "$TYPE" == "tvos" ]] ; then
    # Standard *nix style copy.
    # copy headers

    LIB_FOLDER="$BUILD_ROOT_DIR/$TYPE/FAT/opencv"

    cp -Rv lib/include/ $1/include/
    mkdir -p $1/lib/$TYPE
    cp -v lib/$TYPE/*.a $1/lib/$TYPE
  elif [ "$TYPE" == "android" ]; then
    mkdir -p $1/lib/$TYPE
    cp -r sdk/native/jni/include/opencv $1/include/
    cp -r sdk/native/jni/include/opencv2 $1/include/

    if [ "$TYPE" == "android" ]; then
        if [ "$ARCH" == "armv7" ]; then
            cp sdk/native/libs/armeabi-v7a/*.a $1/lib/$TYPE
        else
            cp sdk/native/libs/armeabi-v7a/*.a $1/lib/$TYPE
        fi
    fi
  elif [ "$TYPE" == "emscripten" ]; then
    cp -r build_emscripten/install/include/* $1/include/
    cp -r build_emscripten/install/lib/*.a $1/lib/$TYPE/
    cp -r build_emscripten/install/share/OpenCV/3rdparty/lib/*.a $1/lib/$TYPE/
  fi

  # copy license file
  rm -rf $1/license # remove any older files if exists
  mkdir -p $1/license
  cp -v LICENSE $1/license/

}

# executed inside the lib src dir
function clean() {
  if [ "$TYPE" == "osx" ] ; then
    make clean;
  elif [[ "$TYPE" == "ios" || "$TYPE" == "tvos" ]] ; then
    make clean;
  fi
}
