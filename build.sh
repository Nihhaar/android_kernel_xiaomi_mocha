#!/bin/bash
ROOT_DIR=$(pwd)
export ARCH=arm
DEFCONFIG=mocha_user_defconfig
CROSS_COMPILER=$ROOT_DIR/toolchain/arm-eabi-5.3/bin/arm-eabi-
COMPILED=$ROOT_DIR/out
BUILDING_DIR=$COMPILED/kernel_obj
OUT_DIR=$COMPILED
MODULES_DIR=$COMPILED/modules

mkdir -p $OUT_DIR $COMPILED $BUILDING_DIR
FUNC_CLEANUP()
{
	echo "Cleaning up..."
	rm -rf $COMPILED
	mkdir -p $OUT_DIR $COMPILED $BUILDING_DIR
	echo "All clean!"
}

FUNC_COMPILE()
{
	echo "Starting the build..."
	make -C $ROOT_DIR O=$BUILDING_DIR $DEFCONFIG 
	make -C $ROOT_DIR O=$BUILDING_DIR ARCH=arm CROSS_COMPILE=$CROSS_COMPILER
	cp $COMPILED/kernel_obj/arch/arm/boot/zImage $OUT_DIR/zImage
	echo "Job done!"

	echo "Copying the Modules..."
	find . -name "*.ko" -exec cp {} $MODULES_DIR \;
	echo "Done!"
}

echo -n "Do you want to clean build directory (y/n)? "
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
