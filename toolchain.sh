#/bin/bash
echo "Removing existing directories..."
rm -rf toolchain/arm-eabi-5.3/
echo "Cloning toolchain..."
git clone "https://bitbucket.org/UBERTC/arm-eabi-5.3" toolchain/arm-eabi-5.3
echo "Done!"