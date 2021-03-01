Pod::Spec.new do |spec|
  spec.name = "GMP-Universal"
  spec.summary = "The GNU Multiple Precision Arithmetic Library"
  spec.homepage = 'https://gmplib.org'
  spec.authors = "Jorge Duarte Rodriguez <info@malagadev.com> & GMP Authors"
  spec.license = { :type => 'LGPL', :file => 'COPYINGv3' }

  spec.version = "6.2.1"
  spec.source = { :http => 'https://gmplib.org/download/gmp/gmp-6.2.1.tar.bz2' }

  spec.platform = :ios
  spec.ios.deployment_target = '11.0'

  spec.prepare_command = <<-CMD
    MIN_IOS="11.0"

    build_for_ios() {
      build_for_architecture iphoneos arm64 arm64-apple-darwin
      build_for_architecture iphonesimulator x86_64 x86_64-apple-darwin
      create_universal_library
    }
    build_for_architecture() {
      PLATFORM=$1
      ARCH=$2
      HOST=$3
      SDKPATH=`xcrun -sdk $PLATFORM --show-sdk-path`
      CLANG=`xcrun -sdk $PLATFORM -find cc`
      MAKE=`xcrun -sdk $PLATFORM -f make`

      PREFIX=$(pwd)/build/${PLATFORM}_${ARCH}

      if [ "${PLATFORM}" = "iphoneos" ]; then
	EXTRAS="-miphoneos-version-min=${MIN_IOS} -no-integrated-as -arch ${ARCH} -target ${ARCH}-apple-darwin";
      fi

      if [ "${PLATFORM}" = "iphonesimulator" ]; then
        EXTRAS="-no-integrated-as -arch ${ARCH} -target ${ARCH}-apple-darwin";
      fi

      CFLAGS="-isysroot ${SDKPATH} -Wno-error -Wno-implicit-function-declaration ${EXTRAS}"

      ./configure \
        CC="${CLANG} ${CFLAGS}" \
        CXX=`xcrun -sdk $PLATFORM -find c++` \
        CPP="${CLANG} -E" \
        LD=`xcrun -sdk $PLATFORM -find ld` \
        AR=`xcrun -sdk $PLATFORM -find ar` \
        NM=`xcrun -sdk $PLATFORM -find nm` \
        NMEDIT=`xcrun -sdk $PLATFORM -find nmedit` \
        LIBTOOL=`xcrun -sdk $PLATFORM -find libtool` \
        LIPO=`xcrun -sdk $PLATFORM -find lipo` \
        OTOOL=`xcrun -sdk $PLATFORM -find otool` \
        RANLIB=`xcrun -sdk $PLATFORM -find ranlib` \
        STRIP=`xcrun -sdk $PLATFORM -find strip` \
        CPPFLAGS="${CFLAGS} -stdlib=libc++" \
	CXXFLAGS="${CFLAGS} -stdlib=libc++" \
        LDFLAGS="-arch $ARCH -headerpad_max_install_names" \
        --host=${HOST} \
        --disable-assembly \
        --enable-cxx \
        --prefix=$PREFIX \
        --quiet --enable-silent-rules

      $MAKE -j `sysctl -n hw.logicalcpu_max`
      $MAKE install
      $MAKE mostlyclean
    }
    create_universal_library() {
      echo "Creating universal library..."

      lipo -create -output libgmp.dylib \
        build/{iphoneos_arm64,iphonesimulator_x86_64}/lib/libgmp.dylib

      lipo -create -output libgmpxx.dylib \
        build/{iphoneos_arm64,iphonesimulator_x86_64}/lib/libgmpxx.dylib 

      update_dylib_names
      update_dylib_references
    }
    update_dylib_names() {
      echo "update dylib names..."
      install_name_tool -id "@rpath/libgmp.dylib" libgmp.dylib
      install_name_tool -id "@rpath/libgmpxx.dylib" libgmpxx.dylib
    }
    update_dylib_references() {
      echo "update dylib references..."
      update_dylib_reference_for_architecture iphoneos_arm64
      update_dylib_reference_for_architecture iphonesimulator_x86_64
    }
    update_dylib_reference_for_architecture() {
      ARCH=$1
      install_name_tool -change \
        "$(pwd)/build/$ARCH/lib/libgmp.10.dylib" \
        "@rpath/libgmp.dylib" \
        libgmpxx.dylib
    }
    clean() {
      make distclean
    }
    build_for_ios
CMD

  spec.source_files = "gmp.h", "gmpxx.h"
  spec.ios.vendored_libraries = "libgmp.dylib", "libgmpxx.dylib"
  spec.pod_target_xcconfig = { 'ONLY_ACTIVE_ARCH' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64' }
  spec.user_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64' }
end
