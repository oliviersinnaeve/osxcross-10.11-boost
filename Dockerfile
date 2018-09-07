FROM ubuntu:16.04
MAINTAINER Olivier Sinnaeve

# Install build tools
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get upgrade -yy && \
    DEBIAN_FRONTEND=noninteractive apt-get install -yy \
        automake            \
        bison               \
        curl                \
        file                \
        flex                \
        git                 \
        libtool             \
        pkg-config          \
        python              \
        texinfo             \
        cmake               \
        wget                \
	zip 		    \
        software-properties-common \
        python-software-properties && \
    apt-add-repository "deb http://llvm.org/apt/trusty/ llvm-toolchain-trusty-3.8 main" && \
    apt-get update && \
    apt-get -yy -qq --force-yes install clang-3.8 lldb-3.8
	
RUN ln -f -s /usr/bin/clang-3.8 /usr/bin/clang	&& ln -f -s /usr/bin/clang++-3.8 /usr/bin/clang++

# Install osxcross
# NOTE: The Docker Hub's build machines run varying types of CPUs, so an image
# built with `-march=native` on one of those may not run on every machine - I
# ran into this problem when the images wouldn't run on my 2013-era Macbook
# Pro.  As such, we remove this flag entirely.
ENV OSXCROSS_SDK_VERSION 10.11
ENV MACOSX_DEPLOYMENT_TARGET 10.11

RUN SDK_VERSION=$OSXCROSS_SDK_VERSION                           \
    OSX_VERSION_MIN=$MACOSX_DEPLOYMENT_TARGET                   \
    mkdir /opt/osxcross &&                                      \
    cd /opt &&                                                  \
    git clone https://github.com/tpoechtrager/osxcross.git &&   \
    cd osxcross &&                                              \
    git checkout c5ffd32171b3771ef6412e5ba2a6fd09e694294a &&    \
    sed -i -e 's|-march=native||g' ./build_clang.sh ./wrapper/build.sh && \
    ./tools/get_dependencies.sh &&                              \
    curl -L -o ./tarballs/MacOSX${OSXCROSS_SDK_VERSION}.sdk.tar.xz \
    https://github.com/apriorit/osxcross-sdks/raw/master/MacOSX${OSXCROSS_SDK_VERSION}.sdk.tar.xz && \
    yes | PORTABLE=true ./build.sh &&                           \
    ./build_compiler_rt.sh
    
ENV UNATTENDED 1
ENV AR x86_64-apple-darwin15-ar
ENV LD x86_64-apple-darwin15-ld
ENV CC x86_64-apple-darwin15-cc
ENV CXX x86_64-apple-darwin15-c++
ENV PATH $PATH:/opt/osxcross/target/bin

RUN osxcross-macports -v install boost && \
    ln -s /opt/osxcross/target/bin/x86_64-apple-darwin15-otool /opt/osxcross/target/bin/otool && \
    ln -s /opt/osxcross/target/bin/x86_64-apple-darwin15-install_name_tool /opt/osxcross/target/bin/install_name_tool

RUN apt-add-repository "deb http://llvm.org/apt/trusty/ llvm-toolchain-trusty-3.8 main" && \
    apt-get update && \
    apt-get -yy -qq --force-yes install clang-3.8 lldb-3.8 && \
    ln -f -s /usr/bin/clang-3.8 /usr/bin/clang	&& ln -f -s /usr/bin/clang++-3.8 /usr/bin/clang++

CMD /bin/bash
