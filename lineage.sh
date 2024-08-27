#!/bin/bash
# Usage: lineage.sh 21.0
# current REL: ap2a
losVersion=$1
  
if [ $INIT = "true" ]; then
    repo init -u https://github.com/LineageOS/android.git -b lineage-$losVersion --git-lfs
fi

if [ $SYNC = "true" ]; then
    repo sync -j$(nproc) --force-sync -c --no-clone-bundle --no-tags --optimized-fetch --prune
fi
if [ $BUILD = "true" ]; then
    source build/envsetup.sh
    export USE_CCACHE=1
    export CCACHE_EXEC=/usr/bin/ccache
    export CCACHE_DIR=/src/.cache
    /usr/bin/ccache -M 100G
    export LC_ALL=C
    export KBUILD_BUILD_USER=pppig
    export KBUILD_BUILD_HOST=gentoolinux
    export TARGET_UNOFFICIAL_BUILD_ID=Pig
    export KERNEL_LTO=$KERNEL_LTO
    if [ $WITH_GMS = "true" ]; then
      export WITH_GMS=true
    	export TARGET_UNOFFICIAL_BUILD_ID=Pig-Gapps
    fi
    if [ $REGENERATE_BUILD_NUMBER = "true" ]; then
      rm -f /tmp/los_buildNumber
    fi
    if [ ! -f /tmp/los_buildNumber ]; then
      export BUILD_UUID=$(uuidgen)
      ( (
          date +%s%N
          echo $BUILD_UUID
          hostname
      ) | openssl sha1 | sed -e 's/.*=//g; s/ //g' | cut -c1-10) > /tmp/los_buildNumber
    fi
    export BUILD_NUMBER=$(cat /tmp/los_buildNumber)
    lunch lineage_${device}-${REL}-${TYPE}
    if [ $CLEAN = "true" ]; then
        rm -rf out/target/product/${device}
    fi
    mka ${target} || exit 1
fi
