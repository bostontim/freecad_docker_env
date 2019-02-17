FROM debian:stable

SHELL ["/bin/bash", "-c"]

WORKDIR /tmp

RUN apt update

# Build tools, and misc supporting tools
RUN apt install -y build-essential gfortran automake bison libtool 
RUN apt install -y git mercurial wget unzip

# CMake v3.14.0
RUN git clone -n https://gitlab.kitware.com/cmake/cmake.git
WORKDIR /tmp/cmake/build
RUN git checkout v3.14.0-rc2
RUN ../bootstrap --parallel=$(nproc --ignore=2)
RUN make -j $(nproc --ignore=2)
RUN make install -j $(nproc --ignore=2)
WORKDIR /tmp

# Python v3.7.2
RUN apt install -y zlib1g-dev libffi-dev libssl-dev 
RUN wget https://www.python.org/ftp/python/3.7.2/Python-3.7.2.tar.xz 
RUN tar -xf Python-3.7.2.tar.xz && rm Python-3.7.2.tar.xz 
WORKDIR /tmp/Python-3.7.2/build
RUN ../configure
RUN make -j $(nproc --ignore=2)
RUN make install -j $(nproc --ignore=2)
WORKDIR /tmp
 
# Infrequently used languages
RUN apt install -y perl ruby

# Libxcb
RUN apt install -y '^libxcb.*-dev' libx11-xcb-dev libglu1-mesa-dev \
    libxrender-dev libxi-dev libxcb-xinerama0-dev

# QT5's accessability dependancies 
RUN apt install -y libatspi2.0-dev libdbus-1-dev

# QT5's webkit dependancies
RUN apt install -y flex gperf libicu-dev libxslt-dev ruby bison

# QT5's multimedia dependancies
RUN apt install -y libasound2-dev libgstreamer1.0-dev \
    libgstreamer-plugins-base1.0-dev

# QT5 v5.12
RUN git clone -n git://code.qt.io/qt/qt5.git
WORKDIR /tmp/qt5
RUN git checkout 5.12
RUN perl init-repository --module-subset=default,-qtwebengine,-qtpurchasing,\
-qtsensors,-qtgamepad,-qtdoc,-qtfeedback,-qtandroidextras
RUN ./configure -opensource -confirm-license -nomake examples -nomake tests
RUN make -j $(nproc --ignore=2)
RUN make -j $(nproc --ignore=2) install
RUN ln -s /usr/local/Qt-5.12.2 /usr/local/Qt-5
WORKDIR /tmp

# Pyside2 and shiboken2 v2-5.12.1
RUN apt install -y libclang-dev
RUN pip3 install --index-url=https://download.qt.io/official_releases/QtForPython/ pyside2 --trusted-host download.qt.io

# The used boost libraries
RUN apt install -y libboost-dev libboost-filesystem-dev libboost-regex-dev \
    libboost-thread-dev libboost-python-dev libboost-signals-dev \
    libboost-program-options-dev

# Freetype v 2.9.1
RUN wget https://download.savannah.gnu.org/releases/freetype/freetype-2.9.1.tar.gz
RUN tar -xzf freetype-2.9.1.tar.gz && rm freetype-2.9.1.tar.gz
WORKDIR /tmp/freetype-2.9.1
RUN make -j $(nproc --ignore=2) && make -j $(nproc --ignore=2) install
WORKDIR /tmp

# TCL v8.7
RUN wget https://prdownloads.sourceforge.net/tcl/tcl8.7a1-src.tar.gz
RUN tar -xzf tcl8.7a1-src.tar.gz && rm tcl8.7a1-src.tar.gz 
WORKDIR /tmp/tcl8.7a1/unix
RUN ./configure --enable-64bit --enable-shared --enable-gcc --enable-threads
RUN make && make install
WORKDIR /tmp

# TK v8.7
RUN wget https://prdownloads.sourceforge.net/tcl/tk8.7a1-src.tar.gz
RUN tar -xzf tk8.7a1-src.tar.gz && rm tk8.7a1-src.tar.gz
WORKDIR /tmp/tk8.7a1/unix
RUN ./configure --enable-64bit --enable-shared --enable-gcc --enable-threads
RUN make && make install
WORKDIR /tmp

# Open Cascade v7.2
RUN apt install -y libxt-dev libxmu-dev libxi-dev libgl1-mesa-dev libglu1-mesa-dev libfreeimage-dev libtbb-dev
# RUN apt install -y tcllib tklib tcl-dev tk-dev libxt-dev libxmu-dev libxi-dev libgl1-mesa-dev libglu1-mesa-dev libfreeimage-dev libtbb-dev
RUN wget "git.dev.opencascade.org/gitweb/?p=occt.git;a=snapshot;h=42da0d5115bff683c6b596e66cdeaff957f81e7d;sf=tgz" -O occt.tar.gz
# I should probabably have this as a more conventional git clone and checkout.
RUN tar -xzf occt.tar.gz && rm occt.tar.gz
WORKDIR /tmp/occt-42da0d5/build
RUN cmake ..
RUN make -j $(nproc --ignore=2) && make -j $(nproc --ignore=2) install
WORKDIR /tmp

# Gmsh v4.1.4
RUN wget gmsh.info/src/gmsh-4.1.4-source.tgz
RUN tar -xzf gmsh-4.1.4-source.tgz && rm gmsh-4.1.4-source.tgz
WORKDIR /tmp/gmsh-4.1.4-source/build
RUN cmake ..
RUN make -j $(nproc --ignore=2) && make -j $(nproc --ignore=2) install
WORKDIR /tmp

# Coin 3D v3.1.3
RUN hg clone https://bitbucket.org/Coin3D/coin
WORKDIR /tmp/coin/build_tmp
RUN cmake -DCOIN_BUILD_DOCUMENTATION=OFF ..
RUN make -j $(nproc --ignore=2) && make -j $(nproc --ignore=2) install
WORKDIR /tmp

# HDF5 v1.8.21
ENV hdf5_path=/usr/local/hdf5
RUN wget https://support.hdfgroup.org/ftp/HDF5/releases/hdf5-1.8/hdf5-1.8.21/src/hdf5-1.8.21.tar.gz
RUN tar -xzf hdf5-1.8.21.tar.gz && rm hdf5-1.8.21.tar.gz  
WORKDIR /tmp/hdf5-1.8.21/build
RUN ../configure --prefix=$hdf5_path
RUN make -j $(nproc --ignore=2) && make -j $(nproc --ignore=2) install
WORKDIR /tmp

# Libmed v3.0.6-11 (AKA: MED-fichier/Modelisation and Data Exchange)
RUN wget https://salsa.debian.org/science-team/med-fichier/-/archive/debian/3.0.6-11/med-fichier-debian-3.0.6-11.tar.gz
RUN tar -xzf med-fichier-debian-3.0.6-11.tar.gz && rm med-fichier-debian-3.0.6-11.tar.gz 
WORKDIR /tmp/med-fichier-debian-3.0.6-11/build
RUN ../configure --with-hdf5=$hdf5_path
RUN make -j $(nproc --ignore=2) && make -j $(nproc --ignore=2) install
WORKDIR /tmp

# Swig v3.0.12
RUN apt install -y libpcre3-dev
RUN wget https://astuteinternet.dl.sourceforge.net/project/swig/swig/swig-3.0.12/swig-3.0.12.tar.gz
RUN tar -xzf swig-3.0.12.tar.gz && rm swig-3.0.12.tar.gz
WORKDIR /tmp/swig-3.0.12
RUN ./configure
RUN make -j $(nproc --ignore=2) && make -j $(nproc --ignore=2) install
WORKDIR /tmp

# SOQT v1.5.0
RUN hg clone https://bitbucket.org/Coin3D/soqt
WORKDIR /tmp/soqt/build_tmp
RUN cmake -DCMAKE_PREFIX_PATH=/usr/local/Qt-5 -DSOQT_BUILD_DOCUMENTATION=OFF ..
RUN make -j $(nproc --ignore=2) && make -j $(nproc --ignore=2) install
WORKDIR /tmp

# Pivy v0.6.4
RUN apt install -y gcc-multilib g++-multilib
RUN hg clone https://bitbucket.org/Coin3D/pivy
WORKDIR /tmp/pivy
RUN hg checkout 0.6.4
ENV CMAKE_PREFIX_PATH=/usr/local/Qt-5
RUN rm setup.py
ADD add_files/setup.py setup.py
#RUN python3 setup.py build
#RUN python3 setup.py install
# There are three issues I ran into with the Pivy setup.py script while I was
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
#    `qtinfo.QtInfo(qmake_command=['/usr/local/Qt-5.12.2/bin/qmake'])`
# 3) CMake misreporting SoQt include dirs
#    For some reason, CMake reports the SOQT_INCLUDE_DIR as
#    `/usr/local/include/usr/include`, instead of
#    `/usr/local/include;/usr/include`. I'm not entirely sure why. To work
#    around that, overwrite the stored value like this:
#    `config_dict["SOQT_INCLUDE_DIR"] = "/usr/local/include"`
WORKDIR /tmp

# # # Netgen v6.2.1901
# # RUN apt install -y libblas-dev liblapack-dev
# # RUN git clone -n https://github.com/NGSolve/ngsolve.git
# # WORKDIR /tmp/ngsolve
# # RUN git checkout v6.2.1901
# # RUN git submodule update --init --recursive
# # WORKDIR /tmp/ngsolve/build
# # RUN cmake ..
# # RUN make -j $(nproc --ignore=2); exit 0
# # RUN make install -j $(nproc --ignore=2); exit 0
# # # I need to update to CMAKE version 3.14, then I can remove the ; exit 0
# # WORKDIR /tmp
# # 
# # # RUN apt install -y build-essential cmake python python-matplotlib libtool \
# # #     libcoin80-dev libsoqt4-dev libxerces-c-dev libboost-dev libboost-filesystem-dev \
# # #     libboost-regex-dev libboost-program-options-dev libboost-signals-dev \
# # #     libboost-thread-dev libboost-python-dev libqt4-dev libqt4-opengl-dev \
# # #     qt4-dev-tools python-dev python-pyside pyside-tools libeigen3-dev \
# # #     libqtwebkit-dev libshiboken-dev libpyside-dev libode-dev swig libzipios++-dev \
# # #     libfreetype6-dev liboce-foundation-dev liboce-modeling-dev liboce-ocaf-dev \
# # #     liboce-visualization-dev liboce-ocaf-lite-dev libsimage-dev checkinstall \
# # #     python-pivy python-qt4 doxygen libspnav-dev oce-draw liboce-foundation-dev \
# # #     liboce-modeling-dev liboce-ocaf-dev liboce-ocaf-lite-dev \
# # #     liboce-visualization-dev libmedc-dev libvtk6-dev libproj-dev
# # # 
# # # Install IFC Open Shell
# # # RUN apt install -y wget unzip
# # # RUN wget https://github.com/IfcOpenShell/IfcOpenShell/releases/download/v0.5.0-preview2/ifcopenshell-python27-master-9ad68db-linux64.zip -O /tmp/tmp_openifc.zip
# # # RUN unzip /tmp/tmp_openifc.zip -d /tmp
# # # RUN mv /tmp/ifcopenshell /usr/lib/python2.7/dist-packages
# # # 
# # # # Add arc GTK theme, and add an alias so that FreeCAD uses it, to make the GUI bearable
# # # # to look at.
# # # RUN apt install -y arc-theme
# # # RUN echo "alias FreeCAD='GTK2_RC_FILES=/usr/share/themes/Arc-Dark/gtk-2.0/gtkrc FreeCAD -style=gtk'" >> ~/.bashrc
# # # 
# # # ADD . /root
# # # 
# # # # Add FreeCAD binary dir to path
# # # RUN echo "PATH=$PATH:/mnt/build/bin" >> ~/.bashrc
# # # 
# # # CMD /bin/bash
