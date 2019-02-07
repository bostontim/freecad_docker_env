FROM debian:stable

# Install FreeCAD dependancies
RUN apt update
RUN apt install -y build-essential cmake python python-matplotlib libtool \
    libcoin80-dev libsoqt4-dev libxerces-c-dev libboost-dev libboost-filesystem-dev \
    libboost-regex-dev libboost-program-options-dev libboost-signals-dev \
    libboost-thread-dev libboost-python-dev libqt4-dev libqt4-opengl-dev \
    qt4-dev-tools python-dev python-pyside pyside-tools libeigen3-dev \
    libqtwebkit-dev libshiboken-dev libpyside-dev libode-dev swig libzipios++-dev \
    libfreetype6-dev liboce-foundation-dev liboce-modeling-dev liboce-ocaf-dev \
    liboce-visualization-dev liboce-ocaf-lite-dev libsimage-dev checkinstall \
    python-pivy python-qt4 doxygen libspnav-dev oce-draw liboce-foundation-dev \
    liboce-modeling-dev liboce-ocaf-dev liboce-ocaf-lite-dev \
    liboce-visualization-dev libmedc-dev libvtk6-dev libproj-dev

# Add arc GTK theme, and add an alias so that FreeCAD uses it, to make the GUI bearable
# to look at.
RUN apt install -y arc-theme
RUN echo "alias FreeCAD='GTK2_RC_FILES=/usr/share/themes/Arc-Dark/gtk-2.0/gtkrc FreeCAD -style=gtk'" >> ~/.bashrc

WORKDIR /root
ADD . /root

# Add FreeCAD binary dir to path
RUN echo "PATH=$PATH:/mnt/build/bin" >> ~/.bashrc

CMD /bin/bash
