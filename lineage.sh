#!/bin/bash
alias ota="signed-ota_update.zip"
alias target="signed-target_files.zip"

unset JAVAC
unset JAVA_HOME
unset JDK_HOME
unset LEX
  
if [ $INIT = "true" ]; then
	repo init -u https://github.com/LineageOS/android.git -b lineage-20.0 --git-lfs
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
    #export OUT_DIR=/home/pppig/out/lost/out
    if [ -z "$BUILD_UUID" ]; then
        export BUILD_UUID=$(uuidgen)
    fi
    if [ $WITH_GMS = "true" ]; then
		export WITH_GMS=true
    	export TARGET_UNOFFICIAL_BUILD_ID=Pig-Gapps
	fi
    if [ ! -f /tmp/los_buildNumber ]; then
      ( (
          date +%s%N
          echo $BUILD_UUID
          hostname
      ) | openssl sha1 | sed -e 's/.*=//g; s/ //g' | cut -c1-10) > /tmp/los_buildNumber
      export BUILD_NUMBER=$(cat /tmp/los_buildNumber)
    fi
    lunch lineage_${device}-${TYPE}
    if [ $CLEAN = "true" ]; then
        rm -rf out/target/product/${device}
    fi
    mka ${target} || 
    if [ $SIGN ]; then
        PATH=$PATH:$OUT/host/linux-x86/bin/
        if [ -f $OUT/obj/PACKAGING/target_files_intermediates/*${BUILD_UUID}*.zip ]; then
            sign_target_files_apks -o -d ~/.android-certs \
                $OUT/obj/PACKAGING/target_files_intermediates/*${BUILD_UUID}*.zip \
                $target

            ota_from_target_files -k ~/.android-certs/releasekey \
                --block --backup=true \
                $target \
                $ota
                    
            if [ -f $ota ]; then
                final=lineage-20.0-$(date +%F | sed s@-@@g)-UNOFFICIAL-Pig-davinci.zip
                mv $ota /home/pppig/dl/$final
            fi
        fi
    fi
fi
