#!/bin/sh
# This configuration file was taken originally from the mpi4py project
# <http://mpi4py.scipy.org/>, and then modified for Julia

set -e
set -x

os=`uname`
TRAVIS_ROOT="$1"
MPI_IMPL="$2"

# this is where updated Autotools will be for Linux
export PATH=$TRAVIS_ROOT/bin:$PATH

case "$os" in
    Darwin)
        echo "Mac"
        brew update
        case "$MPI_IMPL" in
            mpich)
                brew install gcc || brew upgrade gcc || true
                brew link --overwrite gcc || true
                brew install mpich || true
                ;;
            openmpi)
                brew info open-mpi || true
                brew install open-mpi || true
                ;;
            *)
                echo "Unknown MPI implementation: $MPI_IMPL"
                exit 10
                ;;
        esac
    ;;

    Linux)
        echo "Linux"
        case "$MPI_IMPL" in
            mpich)
                if [ ! -d "$TRAVIS_ROOT/mpich" ]; then
                    VERSION=3.3b3
                    wget --no-check-certificate http://www.mpich.org/static/downloads/$VERSION/mpich-$VERSION.tar.gz
                    tar -xzf mpich-$VERSION.tar.gz
                    cd mpich-3*
                    mkdir build && cd build
                    ../configure CFLAGS="-w" --prefix=$TRAVIS_ROOT/mpich --disable-fortran --disable-static
                    make -j2
                    make install
                else
                    echo "MPICH already installed"
                fi
                ;;
            openmpi)
                if [ ! -d "$TRAVIS_ROOT/open-mpi" ]; then
                    VERSION=4.0.0
                    wget --no-check-certificate https://www.open-mpi.org/software/ompi/v4.0/downloads/openmpi-$VERSION.tar.gz
                    # Fix opal_convertor_raw()
                    wget --no-check-certificate https://github.com/open-mpi/ompi/pull/6347.patch
                    # Fix ompi_datatype_set_args()
                    wget --no-check-certificate https://github.com/open-mpi/ompi/pull/6330.patch
                    # Fix ompi_op_reduce()
                    wget --no-check-certificate https://github.com/open-mpi/ompi/pull/6327.patch
                    # Misc osc/rdma fixes
                    #wget --no-check-certificate https://github.com/open-mpi/ompi/pull/6301.patch
                    wget --no-check-certificate https://gist.githubusercontent.com/ggouaillardet/2ea8d2207c1bdeedcc655e556f7eeed2/raw/623c6b499bdd4858e5a4d10c40b04f0dd83e66bb/6301-v4.0.x.diff
                    tar -xzf openmpi-$VERSION.tar.gz
                    cd openmpi-$VERSION
                    patch -p1 < ../6347.patch || exit 1
                    patch -p1 < ../6330.patch || exit 1
                    patch -p1 < ../6327.patch || exit 1
                    patch -p1 < ../6301-v4.0.x.diff || exit 1
                    mkdir build && cd build
                    ../configure CFLAGS="-w" --prefix=$TRAVIS_ROOT/open-mpi \
                                --without-verbs --without-fca --without-mxm --without-ucx \
                                --without-portals4 --without-psm --without-psm2 \
                                --without-libfabric --without-usnic \
                                --without-udreg --without-ugni --without-xpmem \
                                --without-alps --without-munge \
                                --without-sge --without-loadleveler --without-tm \
                                --without-lsf --without-slurm \
                                --without-pvfs2 --without-plfs \
                                --with-libevent=external --with-hwloc=external \
                                --without-cuda --disable-oshmem \
                                --disable-mpi-fortran --disable-oshmem-fortran \
                                --disable-libompitrace \
                                --disable-io-romio \
                                --disable-static \
                                --enable-mpirun-prefix-by-default #--enable-mpi-thread-multiple
                    make -j2
                    make install
                else
                    echo "Open-MPI already installed"
                fi
                ;;
            *)
                echo "Unknown MPI implementation: $MPI_IMPL"
                exit 20
                ;;
        esac
        ;;
esac
