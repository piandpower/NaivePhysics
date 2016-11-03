Installation guide for Naive Physics data generator
===================================================

This step by step installation process has been executed on Debian
jessie (it may be fine for Ubuntu 14.04 as well)

* First of all set up an Epic Games account at
  https://github.com/EpicGames/Signup/, needed to clone the Unreal
  Engine repository from github. UETorch currently only works with the
  source distribution of UE4, not the binary download.

* We will install the project and all its dependencies in the
  `./naive_physics` dircetory:

        mkdir naive_physics
        cd naive_physics

* First install Torch and Lua 5.2 in `naive_physics/torch` and activate
  Torch in your `.bashrc`:

        # clone and install torch
        git clone git@github.com:torch/distro.git ./torch
        cd ./torch
        bash install-deps
        TORCH_LUA_VERSION=LUA52 ./install.sh

        # activate torch
        echo ". $(readlink -f ./install/bin/torch-activate)" >> ~/.bashrc
        source ~/.bashrc
        cd ..

        # install lua dependancies
        luarocks install cjson paths

* Install the Unreal Engine along with the NaivePhysics UETorch plugin,
  activate UETorch in your `.bashrc`:

        # clone Unreal Engine
        git clone -b 4.8 git@github.com:EpicGames/UnrealEngine.git
        cd UnrealEngine

        # clone and install UETorch (from the NaivePhysics fork)
        git clone git@github.com:marioyc/UETorch.git Engine/Plugins/UETorch
        Engine/Plugins/UETorch/Setup.sh

        # install Unreal Engine (the setup step may fail and need manual intervention)
        ./Setup.sh
        ./GenerateProjectFiles.sh
        make  # this take a while...

        # activate UETorch
        echo "source $(readlink -f Engine/Plugins/UETorch/uetorch_activate.sh) > /dev/null" >> ~/.bashrc
        source ~/.bashrc
        cd ..

* Clone the NaivePhysics project and add it to the Lua path:

        git clone git@github.com:bootphon/NaivePhysics.git
        echo "LUA_PATH=\"$(readlink -f ./NaivePhysics/Scripts)"'/?.lua;$LUA_PATH"' >> ~/.bashrc
        source ~/.bashrc

* Compile the NaivePhysics project as a standalone binary in the
  `./NaivePhysics/Package` directory

    * **Script way** Simply execute the `build_package.sh` script

    * **Graphical way** Alternatively you can package it within the
      Unreal Editor (this takes a while the first time)

            cd ./UnrealEngine/Engine/Binaries/Linux/
            ./UE4Editor $(readlink -f ../../../../NaivePhysics/NaivePhysics.uproject)

      In the *File/Package Project* menu, select the Linux target and
      `./NaivePhysics/Package` as the package directory. This
      operation takes a while on the first time.

      ![Packaging menu](https://docs.unrealengine.com/latest/images/Engine/Basics/Projects/Packaging/packaging_menu.jpg)
