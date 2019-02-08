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
# Open Cascade
ENV OCCT_commit="c1197a157530359ec94443c53bcd32a48b3e0b18"
RUN wget "git.dev.opencascade.org/gitweb/?p=occt.git;a=snapshot;h=$OCCT_commit;sf=tgz" -O occt.tar.gz
RUN tar -xzf occt.tar.gz
RUN mv occt-${OCCT_commit:0:7} occt

RUN wget https://download.savannah.gnu.org/releases/freetype/freetype-2.9.1.tar.gz
RUN tar -xzf freetype-2.9.1.tar.gz
WORKDIR /tmp/freetype-2.9.1
RUN make && make install
WORKDIR /tmp

RUN wget https://prdownloads.sourceforge.net/tcl/tcl8.7a1-src.tar.gz
RUN tar -xzf tcl8.7a1-src.tar.gz
WORKDIR /tmp/tcl8.7a1/unix
RUN ./configure --enable-64bit --enable-shared
RUN make && make install
WORKDIR /tmp

RUN wget https://prdownloads.sourceforge.net/tcl/tk8.7a1-src.tar.gz
RUN tar -xzf tk8.7a1-src.tar.gz
WORKDIR /tmp/tk8.7a1/unix
RUN ./configure --enable-64bit --enable-shared
RUN make && make install
WORKDIR /tmp

WORKDIR /tmp/occt/build

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
