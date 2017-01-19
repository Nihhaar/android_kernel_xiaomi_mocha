#!/bin/bash
ROOT_DIR=$(pwd)
export ARCH=arm
DEFCONFIG=mocha_debug_defconfig
CROSS_COMPILER=$ROOT_DIR/toolchain/arm-eabi-5.3/bin/arm-eabi-
OUT_DIR=$ROOT_DIR/out
BUILDING_DIR=$OUT_DIR/kernel_obj
MODULES_DIR=$OUT_DIR/modules
ANYKERNEL_DIR=$ROOT_DIR/AnyKernel2
JOBS=16 #2 x Number of cores

mkdir -p $OUT_DIR $BUILDING_DIR $MODULES_DIR
FUNC_CLEANUP()
{
	echo -e "\n\e[95mCleaning up..."
	rm -rf $OUT_DIR $ANYKERNEL_DIR
	mkdir -p $OUT_DIR $BUILDING_DIR $MODULES_DIR
	echo -e "\e[34mAll clean!"
}

FUNC_COMPILE()
{
	echo -e "\n\e[95mStarting the build..."
	make -C $ROOT_DIR O=$BUILDING_DIR $DEFCONFIG 
	make -j$JOBS -C $ROOT_DIR O=$BUILDING_DIR ARCH=arm CROSS_COMPILE=$CROSS_COMPILER
	cp $OUT_DIR/kernel_obj/arch/arm/boot/zImage $OUT_DIR/zImage
	echo -e "\e[34mJob done!"

	echo -e "\n\e[95mCopying the Modules..."
	rm -rf $MODULES_DIR
	mkdir $MODULES_DIR
	find . -name "*.ko" -exec cp {} $MODULES_DIR \;
	echo -e "\e[34mDone!"
}

FUNC_MAKEZIP()
{
	echo -e "\e[95mCloning AnyKernel2 git..."
	git clone "https://github.com/osm0sis/AnyKernel2" $ANYKERNEL_DIR
	echo -e "\e[95mModifying it for your device..."
	FILE=$ROOT_DIR/AnyKernel2/anykernel.sh
	cp $MODULES_DIR/* $ANYKERNEL_DIR/modules/
	/bin/cat << EOF >$FILE
    kernel.string=FridayKernel by Nihhaar @ xda-developers
    
    do.devicecheck=1
    do.initd=1
    do.modules=1
    do.cleanup=1
    device.name1=mocha

    #Boot Partition
    block=/dev/block/platform/sdhci-tegra.3/by-name/LNX;
    is_slot_device=0;

    ## AnyKernel methods (DO NOT CHANGE)
    # import patching functions/variables - see for reference
    . /tmp/anykernel/tools/ak2-core.sh;
    
    
    ## AnyKernel permissions
    # set permissions for included ramdisk files
    chmod -R 755 $ramdisk
    chmod 644 $ramdisk/sbin/media_profiles.xml
    
    
    ## AnyKernel install
    dump_boot;
    write_boot;
    
    ## end install
EOF
	echo -e "\e[95mMaking kernel.zip file..."
	cd AnyKernel2
	rm -rf zImage
	cp $OUT_DIR/zImage zImage
	zip -r9 FridayKernel-$(date +%F).zip * -x README FridayKernel-$(date +%F).zip
	mv FridayKernel-$(date +%F).zip $OUT_DIR
	cd ..
	echo -e "\e[34mDone! Now Collect ur zip file.\n"
	
}

echo -e -n "\e[33mDo you want to clean build directory (y/n)? "
old_stty_cfg=$(stty -g)
stty raw -echo
answer=$( while ! head -c 1 | grep -i '[ny]' ;do true ;done )
stty $old_stty_cfg

if echo "$answer" | grep -iq "^y" ;then
    FUNC_CLEANUP
    FUNC_COMPILE
else
    rm -r $OUT_DIR/zImage
    FUNC_COMPILE
fi

echo -e -n "\e[33mDo you want to make flashable zip (y/n)? "
old_stty_cfg=$(stty -g)
stty raw -echo
answer=$( while ! head -c 1 | grep -i '[ny]' ;do true ;done )
stty $old_stty_cfg

if echo "$answer" | grep -iq "^y" ;then
    FUNC_MAKEZIP
else
    exit
fi
