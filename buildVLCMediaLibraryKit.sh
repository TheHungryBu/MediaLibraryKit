#!/bin/sh

ARCH="all"
CLEAN=no
SDK_MIN=9.0
VERBOSE=no
ROOT_DIR=default
SIMULATOR=no
NO_NETWORK=no
BUILD_TYPE="Release"
TESTED_HASH="5b4c2180"
VLCKIT_PATH=~
BUILD_VLCKIT=no
SDK_VERSION=`xcrun --sdk iphoneos --show-sdk-version`
CXX_COMPILATOR=clang++
SKIP_MEDIALIBRARY=no
SKIP_DEPENDENCIES=no
OBJCXX_COMPILATOR=clang++
OSVERSIONMINCFLAG=miphoneos-version-min
OSVERSIONMINLDFLAG=ios_version_min

set -e

usage()
{
   cat << EOF
   usage: $0

   OPTIONS
    -v      Be more verbose
    -d      Enable debug mode
    -m      Skip medialibrary compilation
    -n      Skip script steps requiring network interaction
    -c      Clean all target build
    -s      Enable medialibrary build for simulators
    -x      Skip medialibrary dependencies build
    -a      Build for specific architecture(all|i386|x86_64|armv7|armv7s|aarch64)
    -p      VLCKit path(default is ~/)
    -k      Build VLCKit
EOF
}

while getopts "hvdmncsxa:p:k" OPTION
do
    case $OPTION in
        h)
            usage
            exit 1
            ;;
        v)
            VERBOSE=yes
            ;;
        d)
            BUILD_TYPE="Debug"
            ;;
        m)
            SKIP_MEDIALIBRARY=yes
            ;;
        n)
            NO_NETWORK=yes
            ;;
        c)
            CLEAN=yes
            ;;
        s)
            SIMULATOR=yes
            ;;
        x)
            SKIP_DEPENDENCIES=yes
            ;;
        a)
            ARCH=$OPTARG
            ;;
        p)
            VLCKIT_PATH=$OPTARG
            ;;
        k)
            BUILD_VLCKIT=yes
            ;;
        ?)
            usage
            exit 1
            ;;
    esac
done
shift "$((OPTIND-1))"

ROOT_DIR="$(pwd)"
MEDIALIBRARY_DIR="${ROOT_DIR}/libmedialibrary/medialibrary"
DEPENDENCIES_DIR="${MEDIALIBRARY_DIR}/dependencies"
VLC_DIR=""
LIBJPEG_DIR="${DEPENDENCIES_DIR}/libjpeg-turbo"
LIBJPEG_BUILD_DIR=""
LIBJPEG_INCLUDE_DIR=""

SQLITE_RELEASE="sqlite-autoconf-3260000"
SQLITE_SHA1="9af2df1a6da5db6e2ecf3f463625f16740e036e9"
SQLITE_DIR="${DEPENDENCIES_DIR}/${SQLITE_RELEASE}"
SQLITE_INCLUDE_DIR=""
SQLITE_BUILD_DIR=""

# Helpers

spushd()
{
    pushd "$1" 2>&1> /dev/null
}

spopd()
{
    popd 2>&1> /dev/null
}


log()
{
    local green="\033[1;32m"
    local orange="\033[1;91m"
    local red="\033[1;31m"
    local normal="\033[0m"
    local color=$green
    local msgType=$1

    if [ "$1" = "warning" ]; then
        color=$orange
        msgType="warning"
    elif [ "$1" = "error" ]; then
        color=$red
        msgType="error"
    fi
    echo "[${color}${msgType}${normal}] $2"
}

getActualArch()
{
    if [ "$1" = "aarch64" ]; then
        echo "arm64"
    else
        echo "$1"
    fi
}

isSimulatorArch() {
    if [ "$1" = "i386" -o "$1" = "x86_64" ];then
        return 0
    else
        return 1
    fi
}

cleanEnvironment()
{
    export AS=""
    export CCAS=""
    export ASCPP=""
    export CC=""
    export CFLAGS=""
    export CPPFLAGS=""
    export CXX=""
    export CXXFLAGS=""
    export CXXCPPFLAGS=""
    export OBJC=""
    export OBJCFLAGS=""
    export LD=""
    export LDFLAGS=""
    export STRIP=""
    export PKG_CONFIG_LIBDIR=""
    export PKG_CONFIG_PATH=""
}

locateVLCKit()
{
    log "info" "Looking for VLCKit..."
    local path=$VLCKIT_PATH

    if [ "$BUILD_VLCKIT" == "yes" ]; then
        log "info" "Cloning VLCKit..."
        git clone https://code.videolan.org/videolan/VLCKit.git
        spushd VLCKit
            git checkout 3.0
            log "info" "Starting VLCKit 3.0 build..."
            # A specific architecture isn't needed, aarch64 was choosen.
            ./buildMobileVLCKit.sh -vfa aarch64
            path="`pwd`"
        spopd # VLCKit
    elif [ "$VLCKIT_PATH" == ~ ]; then
        log "warning" "VLCKit path not provided, will look for it at ~/"

        path="`find ${VLCKIT_PATH} -maxdepth 5 -type d -name 'VLCKit' -print -quit`"
        if [ -z "${path}" ]; then
            log "error" "Unable to find VLCKit!"
            exit 1
        fi
    fi

    VLC_DIR="${path}/libvlc/vlc"
    log "info" "Found at ${path}"
    log "info" "Setting libvlc directory at ${VLC_DIR}"
}

exportVLC()
{
    local os=$1
    local platform=$2
    local architecture=$3

    export PKG_CONFIG_PATH="${VLC_DIR}/install-${os}${platform}/${architecture}/lib/pkgconfig"
    log "info" "PKG_CONFIG_PATH setted to ${PKG_CONFIG_PATH}"
}

# Retrieve medialibrary

fetchMedialibrary()
{
    log "info" "Fetching Medialibrary..."
    mkdir -p libmedialibrary
    spushd libmedialibrary
        if [ "$NO_NETWORK" = "no" ]; then
            if [ -d medialibrary ]; then
                spushd medialibrary
                    git pull origin master --rebase
                    git reset --hard ${TESTED_HASH}
            else
                git clone https://code.videolan.org/videolan/medialibrary.git
                spushd medialibrary
                    git checkout -B localBranch ${TESTED_HASH}
            fi
                    git submodule update --init
                    spushd libvlcpp
                        git am $ROOT_DIR/Resources/patches/*.patch
                    spopd #libvlcpp
            spopd #medialibrary
        fi
    spopd #libmedialibrary
}

buildLibJpeg()
{
    local arch=$1
    local target=$2
    local libjpegRelease="1.5.2"
    local prefix="${LIBJPEG_DIR}/install/${arch}"

    if [ ! -d "${LIBJPEG_DIR}" ]; then
        if [ "$NO_NETWORK" = "no" ]; then
            log "warning" "libjpeg source not found! Starting download..."
            git clone https://github.com/libjpeg-turbo/libjpeg-turbo.git
            spushd libjpeg-turbo
                git checkout tags/${libjpegRelease}
            spopd
        fi
    fi
    log "info" "Starting libjpeg configuration..."
    spushd libjpeg-turbo
        if [ ! -d "configure" ]; then
            autoreconf --install
        fi
        if [ ! -d "build" ]; then
            mkdir build
        fi
        spushd build
            if [ ! -d "$arch" ]; then
                mkdir $arch
            fi
            spushd $arch
                ${LIBJPEG_DIR}/configure \
                               --host=$target \
                               --prefix=$prefix \
                               --disable-shared \
                               CXX=$CXX_COMPILATOR
                log "info" "Starting libjpeg make..."
                make
                if [ ! -d "${prefix}" ]; then
                    mkdir -p $prefix
                fi
                make install
                LIBJPEG_BUILD_DIR="${prefix}/lib/"
                LIBJPEG_INCLUDE_DIR="${prefix}/include/"
                log "info" "libjpeg armed and ready for ${arch}!"
            spopd
        spopd
    spopd
}

buildSqlite()
{
    local arch=$1
    local target=$2
    local prefix="${SQLITE_DIR}/build/${arch}/install-dir"

    if [ ! -d "${SQLITE_DIR}" ]; then
        if [ "$NO_NETWORK" = "no" ]; then
            log "warning" "sqlite source not found! Starting download..."
            curl -O https://download.videolan.org/pub/contrib/sqlite/${SQLITE_RELEASE}.tar.gz

            if [ ! "`shasum ${SQLITE_RELEASE}.tar.gz`" = "${SQLITE_SHA1}  ${SQLITE_RELEASE}.tar.gz" ]; then
                log "error" "Wrong sha1 for ${SQLITE_RELEASE}.tar.gz"
                exit 1
            fi

            tar -xozf ${SQLITE_RELEASE}.tar.gz
            rm -f ${SQLITE_RELEASE}.tar.gz
        fi
    fi
    log "info" "Starting sqlite configuration..."
    spushd ${SQLITE_RELEASE}
        if [ ! -e "configure" ]; then
            log "warning" "Found configure file, launching autoreconf..."
            autoreconf --install
        fi
        if [ ! -d "build" ]; then
            mkdir build
        fi
        spushd build
            if [ ! -d "$arch" ]; then
                mkdir $arch
            fi
            spushd $arch
                ${SQLITE_DIR}/configure \
                               --host=$target \
                               --disable-shared \
                               --disable-readline \
                               CXX=$CXX_COMPILATOR
                log "info" "Starting sqlite make..."
                make libsqlite3.la
                SQLITE_BUILD_DIR="${SQLITE_DIR}/build/"
                SQLITE_INCLUDE_DIR="${SQLITE_DIR}"
                log "info" "sqlite armed and ready for ${arch}!"
            spopd # $arch
        spopd # build
     spopd # $SQLITE_RELEASE
}

buildDependencies()
{
    log "info" "Starting build for medialibrary dependencies..."
    if [ ! -d "${DEPENDENCIES_DIR}" ]; then
        mkdir -p $DEPENDENCIES_DIR
    fi
    spushd $DEPENDENCIES_DIR
        buildLibJpeg $1 $2
        buildSqlite $1 $2
    spopd
}

buildMedialibrary()
{
    log "info" "Starting Medialibrary build..."

    local os=$1
    local arch=$2
    local platform=$3
    local makeOptions=""

    spushd libmedialibrary
        spushd medialibrary
            if [ ! -d build ]; then
                mkdir build
            fi
            spushd build
                local actualArch="`getActualArch ${arch}`"
                local currentDir="`pwd`"
                local prefix="${currentDir}/${os}${platform}-install/${actualArch}"
                local buildDir="${currentDir}/${os}${platform}-build/${actualArch}"
                local target="${arch}-apple-darwin16.5.0" #xcode 8.3 clang version
                local optim="-O3 -g"
                local medialibraryFlag="--disable-debug"

                log "info" "Building ${arch} with SDK version ${SDK_VERSION} for platform: ${platform}"

                SDKROOT=`xcode-select -print-path`/Platforms/${os}${platform}.platform/Developer/SDKs/${os}${platform}${SDK_VERSION}.sdk
                if [ ! -d "${SDKROOT}" ]; then
                    log "error" "${SDKROOT} does not exist, please install required SDK, or set SDKROOT manually."
                    exit 1
                fi

                if [ "$BUILD_TYPE" = "Debug" ]; then
                    optim="-O0 -g"
                    medialibraryFlag="--enable-debug"
                fi

                CFLAGS="-isysroot ${SDKROOT} -arch ${actualArch} ${optim}"
                CFLAGS+=" -${OSVERSIONMINCFLAG}=${SDK_MIN}"
                EXTRA_CFLAGS+=" -${OSVERSIONMINCFLAG}=${SDK_MIN}"

                # there is no thread_local in the C++ i386 runtime
                if [ "$actualArch" = "i386" ]; then
                    CFLAGS+=" -D__thread="
                fi

                LDFLAGS="-isysroot ${SDKROOT} -arch ${actualArch}"
                EXTRA_LDFLAGS="-arch ${actualArch}"
                LDFLAGS+=" -Wl,-${OSVERSIONMINLDFLAG},${SDK_MIN}"
                EXTRA_LDFLAGS+=" -Wl,-${OSVERSIONMINLDFLAG},${SDK_MIN}"

                export CFLAGS="${CFLAGS}"
                export CXXFLAGS="${CFLAGS}"
                export CPPFLAGS="${CFLAGS}"
                export LDFLAGS=${LDFLAGS}

                exportVLC ${os} ${platform} ${actualArch}

                if [ "${SKIP_DEPENDENCIES}" != "yes" ]; then
                    buildDependencies $actualArch $target
                else
                    log "warning" "Build of medialibrary dependencies skipped..."
                    LIBJPEG_BUILD_DIR="${LIBJPEG_DIR}/build/${arch}"
                    LIBJPEG_INCLUDE_DIR="${LIBJPEG_DIR}/install/${arch}/include/"
                    SQLITE_BUILD_DIR="${SQLITE_DIR}/build/"
                    SQLITE_INCLUDE_DIR="${SQLITE_DIR}"
                fi

                if [ "$VERBOSE" = "yes" ]; then
                    makeOptions="${makeOptions} V=1"
                fi

                local currentXcode="/Application/Xcode.app/Contents/Developer/Platforms/${os}${platform}.platform/Developer/SDKs/${os}${platform}.sdk/usr"
                mkdir -p $buildDir && spushd $buildDir

                    $MEDIALIBRARY_DIR/bootstrap && \
                    $MEDIALIBRARY_DIR/configure \
                                       --disable-shared \
                                       $medialibraryFlag \
                                       --prefix=$prefix \
                                       --host=$target \
                                       CXX=$CXX_COMPILATOR \
                                       OBJCXX=$OBJCXX_COMPILATOR \
                                       LIBJPEG_LIBS="-L${LIBJPEG_BUILD_DIR} -ljpeg" \
                                       LIBJPEG_CFLAGS="-I${LIBJPEG_INCLUDE_DIR}" \
                                       SQLITE_LIBS="-L${SQLITE_BUILD_DIR}${actualArch}/.libs -lsqlite3" \
                                       SQLITE_CFLAGS="-I${SQLITE_INCLUDE_DIR}"

                    log "info" "Starting make in ${buildDir}..."
                    make -C $buildDir $makeOptions > ${out}
                    make -C $buildDir install > ${out}

                spopd

                if [ $? -ne 0 ]; then
                    log "error" "medialibrary build failed!"
                    exit 1
                fi
                log "info" "medialibrary armed and ready for ${arch}!"
            spopd #build
        spopd #medialibrary
    spopd #libmedialibrary
}

# from buildMobileVLCKit.sh
buildXcodeproj()
{
    local target="$2"
    local platform="$3"

    log "info" "Starting build $1 ($target, ${BUILD_TYPE}, $platform)..."

    local architectures=""
    if [ "$ARCH" == "all" ]; then
        if [ "$platform" = "iphonesimulator" ]; then
            architectures="x86_64 i386"
        else
            architectures="armv7 armv7s arm64"
        fi
    else
        architectures="`getActualArch $ARCH`"
    fi
    xcodebuild -project "$1.xcodeproj" \
               -target "$target" \
               -sdk $platform$SDK \
               -configuration ${BUILD_TYPE} \
               ARCHS="${architectures}" \
               IPHONEOS_DEPLOYMENT_TARGET=${SDK_MIN} \
               > ${out}
}

lipoMedialibrary()
{
    local medialibraryInstallDir="${MEDIALIBRARY_DIR}/build/iPhoneOS-install"
    local medialibrarySimulatorInstallDir="${MEDIALIBRARY_DIR}/build/iPhoneSimulator-install"
    local medialibraryArch="`ls ${medialibraryInstallDir}`"
    local medialibrarySimulatorArch="`ls ${medialibrarySimulatorInstallDir}`"
    local files=""

    log "info" "Starting the creation of a libmedialibrary.a bundle..."

    for i in ${medialibraryArch}
    do
        files="${medialibraryInstallDir}/${i}/lib/libmedialibrary.a ${files}"
    done

    if [ "$ARCH" = "all" ] || isSimulatorArch $ARCH; then
        for i in ${medialibrarySimulatorArch}
        do
            files="${medialibrarySimulatorInstallDir}/${i}/lib/libmedialibrary.a ${files}"
        done
    fi

    lipo ${files} -create -output "${MEDIALIBRARY_DIR}/build/libmedialibrary.a"
    log "info" "libmedialibrary.a bundle armed and ready to use!"
}

lipoJpeg()
{
    local libjpegInstallDir="${LIBJPEG_DIR}/install"
    local libjpegArch="`ls ${libjpegInstallDir}`"
    local files=""

    log "info" "Starting the creation of a libjpeg.a bundle..."

    for i in ${libjpegArch}
    do
        files="${libjpegInstallDir}/${i}/lib/libjpeg.a ${files}"
    done

    lipo ${files} -create -output "${MEDIALIBRARY_DIR}/build/libjpeg.a"
    log "info" "libjpeg.a bundle armed and ready to use!"
}

lipoSqlite()
{
    local sqliteInstallDir="${SQLITE_DIR}/build"
    local sqliteArch="`ls ${sqliteInstallDir}`"
    local files=""

    log "info" "Starting the creation of a libsqlite3.a bundle..."

    for i in ${sqliteArch}
    do
        files="${sqliteInstallDir}/${i}/.libs/libsqlite3.a ${files}"
    done

    lipo ${files} -create -output "${MEDIALIBRARY_DIR}/build/libsqlite3.a"
    log "info" "libsqlite3.a bundle armed and ready to use!"
}

createFramework()
{
    local target="$1"
    local libPath=""
    local platform="iphoneos"
    local framework="${target}.framework"
    local medialibraryLibDir="${MEDIALIBRARY_DIR}/build"

    log "info" "Starting the creation of $framework..."

    if [ ! -d build ]; then
        mkdir build
    fi
    if [ "$ARCH" = "all" ] || ! isSimulatorArch $ARCH; then
        libPath="${libPath} $BUILD_TYPE-iphoneos/libVLCMediaLibraryKit.a"
    fi
    if [ "$ARCH" = "all" ] || isSimulatorArch $ARCH; then
        platform="iphonesimulator"
        libPath="${libPath} $BUILD_TYPE-iphonesimulator/libVLCMediaLibraryKit.a"
    fi
    spushd build
        rm -rf $framework && \
        mkdir $framework && \
        lipo -create ${libPath} -o $framework/$target && \
        chmod a+x $framework/$target && \
        cp -pr $BUILD_TYPE-$platform/$target $framework/Headers
    spopd

    log "info" "$framework armed and ready to use!"
}

out="/dev/null"
if [ "$VERBOSE" = "yes" ]; then
    out="/dev/stdout"
fi

##################
# Command Center #
##################

if [ "x$1" != "x" ]; then
    usage
    exit 1
fi

cleanEnvironment

locateVLCKit

if [ "$SKIP_MEDIALIBRARY" != "yes" ]; then
    fetchMedialibrary

    #Mobile first!
    if [ "$ARCH" = "all" ]; then
        buildMedialibrary "iPhone" "i386" "Simulator"
        buildMedialibrary "iPhone" "x86_64" "Simulator"
        buildMedialibrary "iPhone" "armv7" "OS"
        buildMedialibrary "iPhone" "armv7s" "OS"
        buildMedialibrary "iPhone" "aarch64" "OS"
    else
        platform="OS"

        if isSimulatorArch $ARCH; then
            platform="Simulator"
        fi
        buildMedialibrary "iPhone" "$ARCH" "$platform"
    fi

else
    log "warning" "Build of Medialibrary skipped..."
fi

if [ "$CLEAN" = "yes" ]; then
    xcodebuild -alltargets clean
    log "info" "Xcode build cleaned!"
fi
lipoJpeg
lipoSqlite
lipoMedialibrary
if [ "$ARCH" = "all" ] || isSimulatorArch $ARCH; then
    buildXcodeproj VLCMediaLibraryKit "VLCMediaLibraryKit" iphonesimulator
fi
if [ "$ARCH" = "all" ] || ! isSimulatorArch $ARCH; then
    buildXcodeproj VLCMediaLibraryKit "VLCMediaLibraryKit" iphoneos
fi

createFramework "VLCMediaLibraryKit"
