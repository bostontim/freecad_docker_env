FROM debian:stable

WORKDIR /root

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

# Install IFC Open Shell
RUN apt install -y wget unzip
RUN wget https://github.com/IfcOpenShell/IfcOpenShell/releases/download/v0.5.0-preview2/ifcopenshell-python27-master-9ad68db-linux64.zip -O /tmp/tmp_openifc.zip
RUN unzip /tmp/tmp_openifc.zip -d /tmp
RUN mv /tmp/ifcopenshell /usr/lib/python2.7/dist-packages

# Add arc GTK theme, and add an alias so that FreeCAD uses it, to make the GUI bearable
# to look at.
RUN apt install -y arc-theme
RUN echo "alias FreeCAD='GTK2_RC_FILES=/usr/share/themes/Arc-Dark/gtk-2.0/gtkrc FreeCAD -style=gtk'" >> ~/.bashrc

ADD . /root

# Add FreeCAD binary dir to path
RUN echo "PATH=$PATH:/mnt/build/bin" >> ~/.bashrc

CMD /bin/bash
