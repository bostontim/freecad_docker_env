FROM debian:stable

SHELL ["/bin/bash", "-c"]

WORKDIR /tmp

### Install FreeCAD dependancies
RUN apt update

# Build tools
RUN apt install -y build-essential cmake libtool wget git

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
RUN make && make install
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
RUN make && make install
WORKDIR /tmp

# Gmsh v4.1.4
# Note: I should move this higher, later
RUN apt install -y gfortran
RUN wget gmsh.info/src/gmsh-4.1.4-source.tgz
RUN tar -xzf gmsh-4.1.4-source.tgz && rm gmsh-4.1.4-source.tgz
WORKDIR /tmp/gmsh-4.1.4-source/build
RUN cmake ..
RUN make && make install
WORKDIR /tmp

# Coin 3D v3.1.3
# Note: I should move this up higher, later
RUN apt install -y unzip
RUN wget https://bitbucket.org/Coin3D/coin/get/cbbeac5f7984.zip
RUN unzip cbbeac5f7984.zip && rm cbbeac5f7984.zip
WORKDIR /tmp/Coin3D-coin-cbbeac5f7984/build_tmp
RUN ../configure
RUN make && make install
WORKDIR /tmp

# HDF5 v1.8.21
ENV hdf5_path=/usr/local/hdf5
RUN wget https://support.hdfgroup.org/ftp/HDF5/releases/hdf5-1.8/hdf5-1.8.21/src/hdf5-1.8.21.tar.gz
RUN tar -xzf hdf5-1.8.21.tar.gz && rm hdf5-1.8.21.tar.gz  
WORKDIR /tmp/hdf5-1.8.21/build
RUN ../configure --prefix=$hdf5_path
RUN make && make install
WORKDIR /tmp

# Libmed v3.3.1-4(AKA: MED-fichier/Modelisation and Data Exchange)
RUN wget https://salsa.debian.org/science-team/med-fichier/-/archive/76832d81fbd8371eeec96d88f6df10bcd9393372/med-fichier-76832d81fbd8371eeec96d88f6df10bcd9393372.tar.gz
RUN tar -xzf med-fichier-76832d81fbd8371eeec96d88f6df10bcd9393372.tar.gz && rm med-fichier-76832d81fbd8371eeec96d88f6df10bcd9393372.tar.gz
WORKDIR /tmp/med-fichier-76832d81fbd8371eeec96d88f6df10bcd9393372/build
RUN ../configure --with-hdf5=$hdf5_path
RUN make && make install

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
