FROM debian:stretch

SHELL ["/bin/bash", "-c"]

WORKDIR /tmp

# Build tools, and misc supporting tools
RUN apt update && \
    apt install -y build-essential gfortran automake bison libtool git \
    mercurial wget unzip 

# Configure mercurial to use python 2.7 binary, instead of the standard
# /usr/bin/python binary, which uses python 3.7, which breaks mercurial.
RUN sed -i "s/#!\/usr\/bin\/python/#!\/usr\/bin\/python2/g" /usr/bin/hg

# Python v3.7.2
RUN apt install -y zlib1g-dev libffi-dev libssl-dev && \
    wget https://www.python.org/ftp/python/3.7.2/Python-3.7.2.tar.xz && \
    tar -xf Python-3.7.2.tar.xz && rm Python-3.7.2.tar.xz 
WORKDIR /tmp/Python-3.7.2/build
RUN CFLAGS="-fPIC" ../configure --without-pymalloc && \
# For an unknown reason, the boost build tool (irrelevant of what flags are
# used) will not find the correct python include directories unless the
# .../include/python3.7m dir is linked to the .../include/python3.7 dir. Note
# that here, the m on the end, represents that the python was built with
# malloc. For that reason, I'm building python without malloc.
    make -j $(nproc --ignore=2) && \
    make install -j $(nproc --ignore=2)
WORKDIR /tmp

# Ensuring Python3.7 is the default version
RUN ln -sf /usr/local/bin/python3.7 /usr/bin/python && \
    ln -sf /usr/local/bin/python3.7-config /usr/local/bin/python-config

# CMake v3.13.4
RUN git clone -n https://gitlab.kitware.com/cmake/cmake.git
WORKDIR /tmp/cmake/build
RUN git checkout v3.13.4 && \
# I may want to revert to an earlier version to see if the list concatenating
# issue encountered with Pivy remains.
    ../bootstrap --parallel=$(nproc --ignore=2) && \
    make -j $(nproc --ignore=2) && \
    make install -j $(nproc --ignore=2)
WORKDIR /tmp

# Boost v1.67.0
RUN wget https://dl.bintray.com/boostorg/release/1.67.0/source/boost_1_67_0.tar.gz && \
    tar -xzf boost_1_67_0.tar.gz && rm boost_1_67_0.tar.gz
WORKDIR /tmp/boost_1_67_0
RUN ./bootstrap.sh --with-python=/usr/local/bin/python3.7 \
    --with-python-root=/usr/local/include/python3.7 && \
    ./b2 -j$(nproc --ignore=2) && \
    ./b2 -j$(nproc --ignore=2) install
WORKDIR /tmp

# Link libboost_python, so it can be found without it's python version
RUN ln -s /usr/local/lib/libboost_python37.so.1.67.0 /usr/local/lib/libboost_python.so  

# Infrequently used languages
RUN apt install -y perl ruby

# Freetype v 2.9.1
RUN wget https://download.savannah.gnu.org/releases/freetype/freetype-2.9.1.tar.gz && \
    tar -xzf freetype-2.9.1.tar.gz && rm freetype-2.9.1.tar.gz
WORKDIR /tmp/freetype-2.9.1
RUN make -j $(nproc --ignore=2) && \
    make -j $(nproc --ignore=2) install
WORKDIR /tmp

# QT5's accessability dependancies, webkit dependancies, multimedia
# dependancies, and Libxcb
RUN apt install -y libatspi2.0-dev libdbus-1-dev flex gperf libicu-dev \
    libxslt-dev ruby bison libasound2-dev libgstreamer1.0-dev \
    libgstreamer-plugins-base1.0-dev '^libxcb.*-dev' libx11-xcb-dev \
    libglu1-mesa-dev libxrender-dev libxi-dev libxcb-xinerama0-dev \
    libfontconfig1-dev libx11-dev libxext-dev libxfixes-dev libxcb1-dev \
    libxkbcommon-dev

# QT5 v5.12
RUN git clone -n git://code.qt.io/qt/qt5.git && \
    cd /tmp/qt5 && git checkout 5.12
WORKDIR /tmp/qt5
RUN perl init-repository --module-subset=default,-qtwebengine,-qtpurchasing,\
-qtsensors,-qtgamepad,-qtdoc,-qtfeedback,-qtandroidextras
RUN ./configure -opensource -confirm-license -qt-xcb \
    -nomake examples -nomake tests && \
    make -j $(nproc --ignore=2) && \
    make -j $(nproc --ignore=2) install && \
    ln -s /usr/local/Qt-5.12.2 /usr/local/Qt-5
WORKDIR /tmp

# Clang v7.0.1
RUN git clone -n https://github.com/llvm/llvm-project.git && \
    cd /tmp/llvm-project && git checkout llvmorg-7.0.1
WORKDIR /tmp/llvm-project/build
RUN cmake -DLLVM_ENABLE_PROJECTS=clang -G "Unix Makefiles" \
    -DCMAKE_BUILD_TYPE=Release ../llvm && \
    make -j $(nproc --ignore=2) && \
    make -j $(nproc --ignore=2) install
WORKDIR /tmp


# TCL v8.7
RUN wget https://prdownloads.sourceforge.net/tcl/tcl8.7a1-src.tar.gz && \
    tar -xzf tcl8.7a1-src.tar.gz && rm tcl8.7a1-src.tar.gz 
WORKDIR /tmp/tcl8.7a1/unix
RUN ./configure --enable-64bit --enable-shared --enable-gcc --enable-threads && \
    make -j $(nproc --ignore=2) && \
    make -j $(nproc --ignore=2) install
WORKDIR /tmp

# TK v8.7
RUN wget https://prdownloads.sourceforge.net/tcl/tk8.7a1-src.tar.gz && \
    tar -xzf tk8.7a1-src.tar.gz && rm tk8.7a1-src.tar.gz
WORKDIR /tmp/tk8.7a1/unix
RUN ./configure --enable-64bit --enable-shared --enable-gcc --enable-threads && \
    make -j $(nproc --ignore=2) && \
    make -j $(nproc --ignore=2) install
WORKDIR /tmp

# Open Cascade v7.3
RUN apt install -y libxt-dev libxmu-dev libxi-dev libgl1-mesa-dev \
    libglu1-mesa-dev libfreeimage-dev libtbb-dev && \
    wget "http://git.dev.opencascade.org/gitweb/?p=occt.git;a=snapshot;h=42da0d5115bff683c6b596e66cdeaff957f81e7d;sf=tgz" -O occt.tar.gz && \
    mkdir /tmp/occt && \
    tar -xzf occt.tar.gz -C /tmp/occt --strip-components 1
WORKDIR /tmp/occt/build
RUN cmake .. && \
    make -j $(nproc --ignore=2) && \
    make -j $(nproc --ignore=2) install
WORKDIR /tmp

# Gmsh v4.1.4
RUN wget gmsh.info/src/gmsh-4.1.4-source.tgz && \
    tar -xzf gmsh-4.1.4-source.tgz && rm gmsh-4.1.4-source.tgz
WORKDIR /tmp/gmsh-4.1.4-source/build
RUN cmake .. && \
    make -j $(nproc --ignore=2) && \
    make -j $(nproc --ignore=2) install
WORKDIR /tmp

# Coin 3D v3.1.3
RUN hg clone https://bitbucket.org/Coin3D/coin && \
    cd /tmp/coin && hg checkout 40877d4
WORKDIR /tmp/coin/build_tmp
RUN cmake -DCOIN_BUILD_DOCUMENTATION=OFF .. && \
    make -j $(nproc --ignore=2) && \
    make -j $(nproc --ignore=2) install
WORKDIR /tmp

# HDF5 v1.8.21
ENV hdf5_path=/usr/local/hdf5
RUN wget https://support.hdfgroup.org/ftp/HDF5/releases/hdf5-1.8/hdf5-1.8.21/src/hdf5-1.8.21.tar.gz && \
    tar -xzf hdf5-1.8.21.tar.gz && rm hdf5-1.8.21.tar.gz  
WORKDIR /tmp/hdf5-1.8.21/build
RUN ../configure --prefix=$hdf5_path && \
    make -j $(nproc --ignore=2) && make -j $(nproc --ignore=2) install
WORKDIR /tmp

# Libmed v3.0.6-11 (AKA: MED-fichier/Modelisation and Data Exchange)
RUN wget https://salsa.debian.org/science-team/med-fichier/-/archive/debian/3.0.6-11/med-fichier-debian-3.0.6-11.tar.gz && \
    tar -xzf med-fichier-debian-3.0.6-11.tar.gz && \
    rm med-fichier-debian-3.0.6-11.tar.gz 
WORKDIR /tmp/med-fichier-debian-3.0.6-11/build
RUN ../configure --with-hdf5=$hdf5_path && \
    make -j $(nproc --ignore=2) && make -j $(nproc --ignore=2) install
WORKDIR /tmp

# Swig v3.0.12
RUN apt install -y libpcre3-dev && \
    wget https://astuteinternet.dl.sourceforge.net/project/swig/swig/swig-3.0.12/swig-3.0.12.tar.gz && \
    tar -xzf swig-3.0.12.tar.gz && rm swig-3.0.12.tar.gz
WORKDIR /tmp/swig-3.0.12
RUN ./configure && \
    make -j $(nproc --ignore=2) && \
    make -j $(nproc --ignore=2) install
WORKDIR /tmp

# SOQT v1.5.0
RUN hg clone https://bitbucket.org/Coin3D/soqt && \
    cd /tmp/soqt && hg checkout 423d44b
WORKDIR /tmp/soqt/build_tmp
RUN cmake -DCMAKE_PREFIX_PATH=/usr/local/Qt-5 -DSOQT_BUILD_DOCUMENTATION=OFF .. && \
    make -j $(nproc --ignore=2) && make -j $(nproc --ignore=2) install
WORKDIR /tmp

# Pivy v0.6.4
RUN apt install -y gcc-multilib g++-multilib && \
    hg clone https://bitbucket.org/Coin3D/pivy
WORKDIR /tmp/pivy
RUN hg checkout 0.6.4
ENV CMAKE_PREFIX_PATH=/usr/local/Qt-5
RUN rm setup.py
ADD add_files/pivy_setup.py setup.py
RUN CFLAGS="-fpermissive" python3 setup.py build && \
    python3 setup.py install
WORKDIR /tmp
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
    cd /tmp/simage && hg checkout 2a7542b
WORKDIR /tmp/simage/build
RUN ../configure && \
    make -j $(nproc --ignore=2) && \
    make -j $(nproc --ignore=2) install
WORKDIR /tmp

# Eigen v3.3.7
RUN hg clone https://bitbucket.org/eigen/eigen/ && \
    cd /tmp/eigen && hg checkout 3.3.7
WORKDIR /tmp/eigen/build
RUN cmake .. && \
    make -j $(nproc --ignore=2) install
WORKDIR /tmp

# LibArea v12/7/2015
RUN git clone -n https://github.com/danielfalck/libarea.git && \
    cd /tmp/libarea && git checkout 51e6778
WORKDIR /tmp/libarea/build
RUN cmake .. && \
    make -j $(nproc --ignore=2) && \
    make -j $(nproc --ignore=2) install
WORKDIR /tmp

# Xerces C++ v3.2.2
RUN wget https://www-eu.apache.org/dist//xerces/c/3/sources/xerces-c-3.2.2.tar.gz && \
    tar -xzf xerces-c-3.2.2.tar.gz && rm xerces-c-3.2.2.tar.gz
WORKDIR /tmp/xerces-c-3.2.2/build
RUN cmake .. && \
    make -j $(nproc --ignore=2) && \
    make -j $(nproc --ignore=2) install
WORKDIR /tmp

# Pyside2 and shiboken2 v2-5.12
RUN git clone -n https://code.qt.io/pyside/pyside-setup
WORKDIR /tmp/pyside-setup
RUN git checkout 5.12 && \
    git submodule update --init --recursive --progress && \
    python setup.py install --cmake=/usr/local/bin/cmake \
    --qmake=/usr/local/Qt-5/bin/qmake --ignore-git \
    --skip-docs --parallel=$(nproc --ignore=2)
WORKDIR /tmp

# IFC Open Shell v0.6.0a1
RUN git clone -n https://github.com/IfcOpenShell/IfcOpenShell.git && \
    cd /tmp/IfcOpenShell && git checkout v0.6.0a1
WORKDIR /tmp/IfcOpenShell/build
RUN cmake ../cmake -DCOLLADA_SUPPORT=0 \
    -DOCC_INCLUDE_DIR=/usr/local/include/opencascade \
    -DOCC_LIBRARY_DIR=/usr/local/lib && \
    make -j $(nproc --ignore=2) && \
    make -j $(nproc --ignore=2) install
WORKDIR /tmp

# Remove temporary files
RUN rm -rfv /tmp/*

# Add the build script
ADD add_files/freecad_build_script.sh /root/build_script.sh

# Note, had to add this to freecad source CMakeLists.txt:
# add_compile_options(-fpermissive -fPIC)

# # Add arc GTK theme, and add an alias so that FreeCAD uses it, to make the GUI bearable
# # to look at.
# RUN apt install -y arc-theme
# RUN echo "alias FreeCAD='GTK2_RC_FILES=/usr/share/themes/Arc-Dark/gtk-2.0/gtkrc FreeCAD -style=gtk'" >> ~/.bashrc

WORKDIR /root
