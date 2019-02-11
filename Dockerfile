FROM debian:stable

SHELL ["/bin/bash", "-c"]

WORKDIR /tmp

### Install FreeCAD dependancies
RUN apt update

# Build tools
RUN apt install -y build-essential gfortran cmake automake bison libtool wget git mercurial unzip

# Python 3
RUN apt install -y python3 python3-dev python3-pip

# QT5, pyside2, and Siboleth2
RUN apt install -y qt5-default
RUN pip3 install --index-url=https://download.qt.io/official_releases/QtForPython/ pyside2 \
    --trusted-host download.qt.io

# The used boost libraries
RUN apt install -y libboost-dev libboost-filesystem-dev libboost-regex-dev \
    libboost-thread-dev libboost-python-dev libboost-signals-dev \
    libboost-program-options-dev

# Open Cascade v7.2, and it's dependancies
RUN wget https://download.savannah.gnu.org/releases/freetype/freetype-2.9.1.tar.gz
RUN tar -xzf freetype-2.9.1.tar.gz && rm freetype-2.9.1.tar.gz
WORKDIR /tmp/freetype-2.9.1
RUN make -j && make -j install
WORKDIR /tmp

### # Note: I couldn't get OCCT's CMake script to recognise these builds' binaries, so
### # I've just used the offical debian packages instead.
### # TCL
### RUN wget https://prdownloads.sourceforge.net/tcl/tcl8.7a1-src.tar.gz
### RUN tar -xzf tcl8.7a1-src.tar.gz && rm tcl8.7a1-src.tar.gz 
### WORKDIR /tmp/tcl8.7a1/unix
### RUN ./configure --enable-64bit --enable-shared --enable-gcc --enable-threads
### RUN make && make install
### WORKDIR /tmp
### 
### # TK
### RUN wget https://prdownloads.sourceforge.net/tcl/tk8.7a1-src.tar.gz
### RUN tar -xzf tk8.7a1-src.tar.gz && rm tk8.7a1-src.tar.gz
### WORKDIR /tmp/tk8.7a1/unix
### RUN ./configure --enable-64bit --enable-shared --enable-gcc --enable-threads
### RUN make && make install
### WORKDIR /tmp

RUN apt install -y tcllib tklib tcl-dev tk-dev libxt-dev libxmu-dev libxi-dev libgl1-mesa-dev libglu1-mesa-dev libfreeimage-dev libtbb-dev

RUN wget "git.dev.opencascade.org/gitweb/?p=occt.git;a=snapshot;h=42da0d5115bff683c6b596e66cdeaff957f81e7d;sf=tgz" -O occt.tar.gz
RUN tar -xzf occt.tar.gz && rm occt.tar.gz
WORKDIR /tmp/occt-42da0d5/build
RUN cmake ..
RUN make -j && make -j install
WORKDIR /tmp

# Gmsh v4.1.4
RUN wget gmsh.info/src/gmsh-4.1.4-source.tgz
RUN tar -xzf gmsh-4.1.4-source.tgz && rm gmsh-4.1.4-source.tgz
WORKDIR /tmp/gmsh-4.1.4-source/build
RUN cmake ..
RUN make -j && make -j install
WORKDIR /tmp

# Coin 3D v3.1.3
RUN apt install -y
# Move this higher later.
RUN hg clone https://bitbucket.org/Coin3D/coin
WORKDIR /tmp/coin/build_tmp
RUN cmake -DCOIN_BUILD_DOCUMENTATION=OFF ..
RUN make -j && make -j install
WORKDIR /tmp

# HDF5 v1.8.21
ENV hdf5_path=/usr/local/hdf5
RUN wget https://support.hdfgroup.org/ftp/HDF5/releases/hdf5-1.8/hdf5-1.8.21/src/hdf5-1.8.21.tar.gz
RUN tar -xzf hdf5-1.8.21.tar.gz && rm hdf5-1.8.21.tar.gz  
WORKDIR /tmp/hdf5-1.8.21/build
RUN ../configure --prefix=$hdf5_path
RUN make -j && make -j install
WORKDIR /tmp

# Libmed v3.0.6-11 (AKA: MED-fichier/Modelisation and Data Exchange)
RUN wget https://salsa.debian.org/science-team/med-fichier/-/archive/debian/3.0.6-11/med-fichier-debian-3.0.6-11.tar.gz
RUN tar -xzf med-fichier-debian-3.0.6-11.tar.gz && rm med-fichier-debian-3.0.6-11.tar.gz 
WORKDIR /tmp/med-fichier-debian-3.0.6-11/build
RUN ../configure --with-hdf5=$hdf5_path
RUN make -j && make -j install
WORKDIR /tmp

# Swig v3.0.12
RUN apt install -y libpcre3-dev
# Move this higher later
RUN wget https://github.com/swig/swig/archive/rel-3.0.12.tar.gz
RUN tar -xzf rel-3.0.12.tar.gz && rm rel-3.0.12.tar.gz
WORKDIR /tmp/swig-rel-3.0.12
RUN ./autogen.sh
RUN ./configure
RUN make -j && make -j install
WORKDIR /tmp

# SOQT v1.5.0
RUN wget https://bitbucket.org/Coin3D/soqt/get/08958520df8f.zip
# RUN tar -xzf default.tar.gz && rm default.tar.gz
# WORKDIR /tmp/Coin3D-soqt-1a381ca22d93/build
# RUN ../configure
# RUN make -j && make -j install
# RUN /tmp

# # Pivy v0.6.4
# RUN wget https://bitbucket.org/Coin3D/pivy/get/0.6.4.tar.gz
# RUN tar -xzf 0.6.4.tar.gz && rm 0.6.4.tar.gz  
# WORKDIR /tmp/Coin3D-pivy-a84100beff22
# RUN python3 setup.py build
# RUN python3 setup.py install
# 
# # Netgen v6.2.1901
# RUN apt install -y libblas-dev liblapack-dev
# RUN git clone -n https://github.com/NGSolve/ngsolve.git
# WORKDIR /tmp/ngsolve
# RUN git checkout a31a905cac14b0c14c535b8063e2fd16941c4335
# RUN git submodule update --init --recursive
# WORKDIR /tmp/ngsolve/build
# RUN cmake ..
# RUN make; exit 0
# RUN make install
# # Leaving this for now, because I can't tell what's broken, but this is likely broken.
# WORKDIR /tmp

# RUN apt install -y build-essential cmake python python-matplotlib libtool \
#     libcoin80-dev libsoqt4-dev libxerces-c-dev libboost-dev libboost-filesystem-dev \
#     libboost-regex-dev libboost-program-options-dev libboost-signals-dev \
#     libboost-thread-dev libboost-python-dev libqt4-dev libqt4-opengl-dev \
#     qt4-dev-tools python-dev python-pyside pyside-tools libeigen3-dev \
#     libqtwebkit-dev libshiboken-dev libpyside-dev libode-dev swig libzipios++-dev \
#     libfreetype6-dev liboce-foundation-dev liboce-modeling-dev liboce-ocaf-dev \
#     liboce-visualization-dev liboce-ocaf-lite-dev libsimage-dev checkinstall \
#     python-pivy python-qt4 doxygen libspnav-dev oce-draw liboce-foundation-dev \
#     liboce-modeling-dev liboce-ocaf-dev liboce-ocaf-lite-dev \
#     liboce-visualization-dev libmedc-dev libvtk6-dev libproj-dev
# 
# Install IFC Open Shell
# RUN apt install -y wget unzip
# RUN wget https://github.com/IfcOpenShell/IfcOpenShell/releases/download/v0.5.0-preview2/ifcopenshell-python27-master-9ad68db-linux64.zip -O /tmp/tmp_openifc.zip
# RUN unzip /tmp/tmp_openifc.zip -d /tmp
# RUN mv /tmp/ifcopenshell /usr/lib/python2.7/dist-packages
# 
# # Add arc GTK theme, and add an alias so that FreeCAD uses it, to make the GUI bearable
# # to look at.
# RUN apt install -y arc-theme
# RUN echo "alias FreeCAD='GTK2_RC_FILES=/usr/share/themes/Arc-Dark/gtk-2.0/gtkrc FreeCAD -style=gtk'" >> ~/.bashrc
# 
# ADD . /root
# 
# # Add FreeCAD binary dir to path
# RUN echo "PATH=$PATH:/mnt/build/bin" >> ~/.bashrc
# 
# CMD /bin/bash
