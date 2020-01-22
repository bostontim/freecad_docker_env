FROM debian:stretch

SHELL ["/bin/bash", "-c"]

WORKDIR /tmp

# Build tools, and misc supporting tools
RUN apt update && \
    apt install -y build-essential gfortran automake bison flex libtool git \
    mercurial wget unzip doxygen

# Configure mercurial to use python 2.7 binary, instead of the standard
# /usr/bin/python binary, which uses python 3.7, which breaks mercurial.
RUN sed -i "s/#!\/usr\/bin\/python/#!\/usr\/bin\/python2/g" /usr/bin/hg

# Python v3.7.2
RUN apt install -y zlib1g-dev libffi-dev libssl-dev && \
    wget https://www.python.org/ftp/python/3.7.2/Python-3.7.2.tar.xz && \
    tar -xf Python-3.7.2.tar.xz && rm Python-3.7.2.tar.xz && \
    mkdir /tmp/Python-3.7.2/build && cd /tmp/Python-3.7.2/build && \
    CFLAGS="-fPIC" ../configure --without-pymalloc && \
# For an unknown reason, the boost build tool (irrelevant of what flags are
# used) will not find the correct python include directories unless the
# .../include/python3.7m dir is linked to the .../include/python3.7 dir. Note
# that here, the m on the end, represents that the python was built with
# malloc. For that reason, I'm building python without malloc.
    make -j $(nproc --ignore=2) && \
    make install -j $(nproc --ignore=2) && \
    rm -rfv /tmp/*

# Ensuring Python3.7 is the default version
RUN ln -sf /usr/local/bin/python3.7 /usr/bin/python && \
    ln -sf /usr/local/bin/python3.7-config /usr/local/bin/python-config

# CMake v3.13.4
RUN git clone -n https://gitlab.kitware.com/cmake/cmake.git && \
    mkdir /tmp/cmake/build && cd /tmp/cmake/build && \
    git checkout v3.13.4 && \
# I may want to revert to an earlier version to see if the list concatenating
# issue encountered with Pivy remains.
    ../bootstrap --parallel=$(nproc --ignore=2) && \
    make -j $(nproc --ignore=2) && \
    make install -j $(nproc --ignore=2) && \
    rm -rfv /tmp/*

# Boost v1.67.0
RUN wget https://dl.bintray.com/boostorg/release/1.67.0/source/boost_1_67_0.tar.gz && \
    tar -xzf boost_1_67_0.tar.gz && rm boost_1_67_0.tar.gz && \
    cd  /tmp/boost_1_67_0 && \
    ./bootstrap.sh --with-python=/usr/local/bin/python3.7 \
    --with-python-root=/usr/local/include/python3.7 && \
    ./b2 -j$(nproc --ignore=2) && \
    ./b2 -j$(nproc --ignore=2) install && \
    rm -rfv /tmp/*

# Link libboost_python, so it can be found without it's python version
RUN ln -s /usr/local/lib/libboost_python37.so.1.67.0 /usr/local/lib/libboost_python.so  

# Infrequently used languages
RUN apt install -y perl ruby

# Freetype v 2.9.1
RUN wget https://download.savannah.gnu.org/releases/freetype/freetype-2.9.1.tar.gz && \
    tar -xzf freetype-2.9.1.tar.gz && rm freetype-2.9.1.tar.gz && \
    cd  /tmp/freetype-2.9.1 && \
    make -j $(nproc --ignore=2) && \
    make -j $(nproc --ignore=2) install && \
    rm -rfv /tmp/*

# QT5's accessability dependancies, webkit dependancies, multimedia
# dependancies, and Libxcb
RUN apt install -y libatspi2.0-dev libdbus-1-dev flex gperf libicu-dev \
    libxslt-dev ruby bison libasound2-dev libgstreamer1.0-dev \
    libgstreamer-plugins-base1.0-dev '^libxcb.*-dev' libx11-xcb-dev \
    libglu1-mesa-dev libxrender-dev libxi-dev libxcb-xinerama0-dev \
    libfontconfig1-dev libx11-dev libxext-dev libxfixes-dev libxcb1-dev \
    libxkbcommon-dev

# QT5 v5.12.6
RUN QT_VER=5.12.6 && \
    git clone -n git://code.qt.io/qt/qt5.git && \
    cd /tmp/qt5 && git checkout $QT_VER && \
    perl init-repository --module-subset=default,-qtpurchasing,\
-qtgamepad,-qtfeedback,-qtandroidextras && \
    ./configure -opensource -confirm-license -qt-xcb \
    -nomake examples -nomake tests && \
    make -j $(nproc --ignore=2) && \
    make -j $(nproc --ignore=2) install && \
    rm -rfv /tmp/* && \
    ln -v -s /usr/local/Qt-$QT_VER /usr/local/Qt-5
ENV PATH="/usr/local/Qt-5/bin:${PATH}"

# QT Wayland v5.12
RUN apt install -y libwayland-dev libwayland-egl1-mesa libwayland-server0 \
    libgles2-mesa-dev libxkbcommon-dev && \
    git clone -n git://code.qt.io/qt/qtwayland.git && \
    cd qtwayland && git checkout 5.12 &&\
    qmake && \
    make -j $(nproc --ignore=2) && \
    make -j $(nproc --ignore=2) install && \
    rm -rfv /tmp/*

# QT WebKit v5.212
RUN apt install -y libsqlite3-dev libjpeg-dev libwebp-dev libxcomposite-dev && \
    git clone -n https://code.qt.io/qt/qtwebkit.git && \
    cd /tmp/qtwebkit && git checkout 5.212 && \
    # Disable the all-in-one buuld, because it causes GCC to hang indefinitely
    # (as far as I could tell).  Also, it appears to only be needed for the
    # Windows build.
    sed -i '1s/^/set(ENABLE_ALLINONE_BUILD OFF)\n/' /tmp/qtwebkit/Source/WebCore/CMakeLists.txt && \
    qmake && \
    make -j $(nproc --ignore=2) && \
    make -j $(nproc --ignore=2) install && \
    rm -rfv /tmp/*

# Clang v7.0.1
RUN git clone -n https://github.com/llvm/llvm-project.git && \
    cd /tmp/llvm-project && git checkout llvmorg-7.0.1 && \
    mkdir /tmp/llvm-project/build && cd /tmp/llvm-project/build && \
    cmake -DLLVM_ENABLE_PROJECTS=clang -G "Unix Makefiles" \
    -DCMAKE_BUILD_TYPE=Release ../llvm && \
    make -j $(nproc --ignore=2) && \
    make -j $(nproc --ignore=2) install && \
    rm -rfv /tmp/*

# TCL v8.7
RUN wget https://prdownloads.sourceforge.net/tcl/tcl8.7a1-src.tar.gz && \
    tar -xzf tcl8.7a1-src.tar.gz && rm tcl8.7a1-src.tar.gz && \
    cd /tmp/tcl8.7a1/unix && \
    ./configure --enable-64bit --enable-shared --enable-gcc --enable-threads && \
    make -j $(nproc --ignore=2) && \
    make -j $(nproc --ignore=2) install && \
    rm -rfv /tmp/*

# TK v8.7
RUN wget https://prdownloads.sourceforge.net/tcl/tk8.7a1-src.tar.gz && \
    tar -xzf tk8.7a1-src.tar.gz && rm tk8.7a1-src.tar.gz && \
    cd /tmp/tk8.7a1/unix && \
    ./configure --enable-64bit --enable-shared --enable-gcc --enable-threads && \
    make -j $(nproc --ignore=2) && \
    make -j $(nproc --ignore=2) install && \
    rm -rfv /tmp/*

# Open Cascade v7.3
RUN apt install -y libxt-dev libxmu-dev libxi-dev libgl1-mesa-dev \
    libglu1-mesa-dev libfreeimage-dev libtbb-dev && \
    wget "http://git.dev.opencascade.org/gitweb/?p=occt.git;a=snapshot;h=42da0d5115bff683c6b596e66cdeaff957f81e7d;sf=tgz" -O occt.tar.gz && \
    mkdir /tmp/occt && \
    tar -xzf occt.tar.gz -C /tmp/occt --strip-components 1 && \
    mkdir /tmp/occt/build && cd /tmp/occt/build && \
    cmake .. && \
    make -j $(nproc --ignore=2) && \
    make -j $(nproc --ignore=2) install && \
    rm -rfv /tmp/*

# Gmsh v4.1.4
RUN wget gmsh.info/src/gmsh-4.1.4-source.tgz && \
    tar -xzf gmsh-4.1.4-source.tgz && rm gmsh-4.1.4-source.tgz && \
    mkdir /tmp/gmsh-4.1.4-source/build && cd /tmp/gmsh-4.1.4-source/build && \
    cmake .. && \
    make -j $(nproc --ignore=2) && \
    make -j $(nproc --ignore=2) install && \
    rm -rfv /tmp/*

# Coin 3D v3.1.3
RUN hg clone https://bitbucket.org/Coin3D/coin && \
    cd /tmp/coin && hg checkout 40877d4 && \
    mkdir /tmp/coin/build_tmp && cd /tmp/coin/build_tmp && \
    cmake .. && \
    make -j $(nproc --ignore=2) && \
    make -j $(nproc --ignore=2) install && \
    rm -rfv /tmp/*

# HDF5 v1.8.21
ENV hdf5_path=/usr/local/hdf5
RUN wget https://support.hdfgroup.org/ftp/HDF5/releases/hdf5-1.8/hdf5-1.8.21/src/hdf5-1.8.21.tar.gz && \
    tar -xzf hdf5-1.8.21.tar.gz && rm hdf5-1.8.21.tar.gz && \
    mkdir /tmp/hdf5-1.8.21/build && cd /tmp/hdf5-1.8.21/build && \
    ../configure --prefix=$hdf5_path && \
    make -j $(nproc --ignore=2) && make -j $(nproc --ignore=2) install && \
    rm -rfv /tmp/*

# Libmed v3.0.6-11 (AKA: MED-fichier/Modelisation and Data Exchange)
RUN wget https://salsa.debian.org/science-team/med-fichier/-/archive/debian/3.0.6-11/med-fichier-debian-3.0.6-11.tar.gz && \
    tar -xzf med-fichier-debian-3.0.6-11.tar.gz && \
    rm med-fichier-debian-3.0.6-11.tar.gz && \
    mkdir /tmp/med-fichier-debian-3.0.6-11/build && \
    cd /tmp/med-fichier-debian-3.0.6-11/build && \
    ../configure --with-hdf5=$hdf5_path && \
    make -j $(nproc --ignore=2) && make -j $(nproc --ignore=2) install && \
    rm -rfv /tmp/*

# Swig v3.0.12
RUN apt install -y libpcre3-dev && \
    wget https://astuteinternet.dl.sourceforge.net/project/swig/swig/swig-3.0.12/swig-3.0.12.tar.gz && \
    tar -xzf swig-3.0.12.tar.gz && rm swig-3.0.12.tar.gz && \
    cd /tmp/swig-3.0.12 && \
    ./configure && \
    make -j $(nproc --ignore=2) && \
    make -j $(nproc --ignore=2) install && \
    rm -rfv /tmp/*

# SOQT v1.5.0
RUN hg clone https://bitbucket.org/Coin3D/soqt && \
    cd /tmp/soqt && hg checkout 423d44b && \
    mkdir /tmp/soqt/build_tmp && cd /tmp/soqt/build_tmp && \
    cmake -DCMAKE_PREFIX_PATH=/usr/local/Qt-5 .. && \
    make -j $(nproc --ignore=2) && make -j $(nproc --ignore=2) install && \
    rm -rfv /tmp/*

# Pivy v0.6.4
RUN apt install -y gcc-multilib g++-multilib && \
    hg clone https://bitbucket.org/Coin3D/pivy && \
    cd /tmp/pivy && hg checkout 0.6.4 && \
    rm setup.py
ADD add_files/pivy_setup.py /tmp/pivy/setup.py
RUN cd /tmp/pivy && \
    export CMAKE_PREFIX_PATH=/usr/local/Qt-5 && \
    CFLAGS="-fpermissive" python3 setup.py build && \
    python3 setup.py install && \
    rm -rfv /tmp/*
# There are four issues I ran into with the Pivy setup.py script while I was
# creating this Dockerfile. I am documenting the issues here, so I can resolve
# them in a less hacky way, later.
# 1) SWIG -I flags
#    SWIG needs to be given the following additional flags:
#    -I/usr/include/boost/compatibility/cpp_c_headers
#    -I/usr/include/x86_64-linux-gnu/c++/6/ 
#    -I/usr/include/c++/6
# 2) Finding qmake
#    The script cannot find the qmake binary, so when running:
#    `qtinfo.QtInfo()`, add this argument:
#    `qtinfo.QtInfo(qmake_command=['/usr/local/Qt-5/bin/qmake'])`
# 3) CMake misreporting SoQt include dirs
#    For some reason, CMake reports the SOQT_INCLUDE_DIR as
#    `/usr/local/include/usr/include`, instead of
#    `/usr/local/include;/usr/include`. I'm not entirely sure why. To work
#    around that, overwrite the stored value like this:
#    `config_dict["SOQT_INCLUDE_DIR"] = "/usr/local/include"`
# 4) -fpermissive flag
#    I ran into the following issue when the swig-generated file coin_wrap.cpp
#    got compiled. This forced me to add the -fpermissive flag to the
#    compilation. While I'm not an expert, it is my understanding this is
#    unsafe:
#    pivy/coin_wrap.cpp: In function ‘void SoSensorPythonCB(void*, SoSensor*)’:
#    pivy/coin_wrap.cpp:6342:40: warning: invalid conversion from ‘const char*’ to ‘char*’ [-fpermissive]
#         sensor_cast_name = PyUnicode_AsUTF8(item);
#                            ~~~~~~~~~~~~~~~~^~~~~~
#    pivy/coin_wrap.cpp: In function ‘void SoMarkerSet_addMarker__SWIG_3(int, const SbVec2s&, PyObject*, SbBool, SbBool)’:
#    pivy/coin_wrap.cpp:7236:43: warning: invalid conversion from ‘const char*’ to ‘char*’ [-fpermissive]
#                 coin_marker = PyUnicode_AsUTF8(string);
#                               ~~~~~~~~~~~~~~~~^~~~~~~~

# simage v1.7.0+
RUN hg clone https://bitbucket.org/Coin3D/simage && \
    cd /tmp/simage && hg checkout 2a7542b && \
    mkdir /tmp/simage/tmp_build && cd /tmp/simage/tmp_build && \
    ../configure && \
    make -j $(nproc --ignore=2) && \
    make -j $(nproc --ignore=2) install && \
    rm -rfv /tmp/*

# Eigen v3.3.7
RUN hg clone https://bitbucket.org/eigen/eigen/ && \
    cd /tmp/eigen && hg checkout 3.3.7 && \
    mkdir /tmp/eigen/build && cd /tmp/eigen/build && \
    cmake .. && \
    make -j $(nproc --ignore=2) install && \
    rm -rfv /tmp/*

# LibArea v12/7/2015
RUN git clone -n https://github.com/danielfalck/libarea.git && \
    cd /tmp/libarea && git checkout 51e6778 && \
    mkdir /tmp/libarea/build && cd /tmp/libarea/build && \ 
    cmake .. && \
    make -j $(nproc --ignore=2) && \
    make -j $(nproc --ignore=2) install && \
    rm -rfv /tmp/*

# Xerces C++ v3.2.2
RUN wget https://www-eu.apache.org/dist//xerces/c/3/sources/xerces-c-3.2.2.tar.gz && \
    tar -xzf xerces-c-3.2.2.tar.gz && rm xerces-c-3.2.2.tar.gz && \
    mkdir /tmp/xerces-c-3.2.2/build && cd /tmp/xerces-c-3.2.2/build && \
    cmake .. && \
    make -j $(nproc --ignore=2) && \
    make -j $(nproc --ignore=2) install && \
    rm -rfv /tmp/*

# Pyside2 and shiboken2 v2-5.12
RUN git clone -n https://code.qt.io/pyside/pyside-setup && \
    cd /tmp/pyside-setup && git checkout 5.12 && \
    git submodule update --init --recursive --progress && \
    python setup.py install --cmake=/usr/local/bin/cmake \
    --qmake=/usr/local/Qt-5/bin/qmake --ignore-git \
    --parallel=$(nproc --ignore=2) && \
    rm -rfv /tmp/*

# IFC Open Shell v0.6.0a1
RUN git clone -n https://github.com/IfcOpenShell/IfcOpenShell.git && \
    cd /tmp/IfcOpenShell && git checkout v0.6.0a1 && \
    mkdir /tmp/IfcOpenShell/build && cd /tmp/IfcOpenShell/build && \
    cmake ../cmake -DCOLLADA_SUPPORT=0 \
    -DOCC_INCLUDE_DIR=/usr/local/include/opencascade \
    -DOCC_LIBRARY_DIR=/usr/local/lib && \
    make -j $(nproc --ignore=2) && \
    make -j $(nproc --ignore=2) install && \
    rm -rfv /tmp/*

# Numpy v1.16.2 and Matplotlib v3.0.3
RUN python -m pip install numpy==1.16.2 matplotlib==3.0.3

# SPOOLES v2.2
RUN mkdir spooles && cd spooles && \
    wget www.netlib.org/linalg/spooles/spooles.2.2.tgz && \
    tar -xzf spooles.2.2.tgz && \
    make lib CC=cc -j $(nproc --ignore=2) && \
    mkdir /usr/local/SPOOLES.2.2 && \
    mv * /usr/local/SPOOLES.2.2 && \
    rm -rfv /tmp/*
    # Note: Spooles can be made as "make lib", "make drivers", or "make global". It is not immediately clear
    # which one should be used.

# ARpack v96
RUN mkdir arpack && cd arpack && \
    wget https://www.caam.rice.edu/software/ARPACK/SRC/arpack96.tar.gz && \
    wget https://www.caam.rice.edu/software/ARPACK/SRC/patch.tar.gz && \
    tar -xzf arpack96.tar.gz && \
    tar -xzf patch.tar.gz && \
    cd ARPACK && \
    sed -i 's/      EXTERNAL           ETIME/*     EXTERNAL           ETIME/' UTIL/second.f && \
    make lib home=/tmp/arpack/ARPACK MAKE=make SHELL=bash FC=gfortran PLAT=INTEL FFLAGS="-O"  && \
    mkdir /usr/local/ARPACK && \
    mv libarpack_INTEL.a /usr/local/ARPACK && \
    rm -rfv /tmp/*

# CalculiX v2.16
RUN cd /usr/local && \
    wget http://www.dhondt.de/ccx_2.16.src.tar.bz2 && \
    tar -xjvf ccx_2.16.src.tar.bz2 && \
    cd /usr/local/CalculiX/ccx_2.16/src && \
    make -j $(nproc --ignore=2)&& \
    mv ccx_2.16 /usr/local/bin/ccx && \
    cd /usr/local/bin && \
    chmod a+rx ccx

# VTK v8.2.0
RUN git clone -n https://gitlab.kitware.com/vtk/vtk.git && \
    mkdir /tmp/vtk/build && cd /tmp/vtk/build && \
    git checkout v8.2.0 && \
    cmake -DVTK_QT_VERSION:STRING=5 \
    -D QT_QMAKE_EXECUTABLE:PATH=/usr/local/Qt-5.12.6/bin/qmake \
    -D VTK_Group_Qt:BOOL=ON \
    -D CMAKE_PREFIX_PATH:PATH=/usr/local/Qt-5/lib/cmake  \
    -D BUILD_SHARED_LIBS:BOOL=ON \
    .. && \
    make -j $(nproc --ignore=2)


# Add the build script
ADD add_files/freecad_build_script.sh /root/build_script.sh

# Note, had to add this to freecad source CMakeLists.txt:
# add_compile_options(-fpermissive -fPIC)

# # Add arc GTK theme, and add an alias so that FreeCAD uses it, to make the GUI bearable
# # to look at.
# RUN apt install -y arc-theme
# RUN echo "alias FreeCAD='GTK2_RC_FILES=/usr/share/themes/Arc-Dark/gtk-2.0/gtkrc FreeCAD -style=gtk'" >> ~/.bashrc

# Add enviroment varaible so CMake can find QT5
ENV CMAKE_PREFIX_PATH=/usr/local/Qt-5

# Add enviroment variable so Qt5 can find it's shared libaries
ENV LD_LIBRARY_PATH=/usr/local/Qt-5/lib/

WORKDIR /root
