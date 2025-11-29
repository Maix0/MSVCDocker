ARG WINE_VER=10.0.0.0
FROM wine:$WINE_VER
USER root

# clang-cl shims
RUN mkdir /etc/vcclang && \
    touch /etc/vcclang/vcvars32 && \
    touch /etc/vcclang/vcvars64;

# vcwine
RUN mkdir /etc/vcwine && \
    touch /etc/vcwine/vcvars32 && \
    touch /etc/vcwine/vcvars64;
ADD dockertools/vcwine /usr/local/bin/vcwine

# bring over the msvc snapshots
ARG MSVC
ENV MSVC="$MSVC"
ADD --chown=wine:wine build/msvc$MSVC/snapshots snapshots
USER wine

# import the msvc snapshot files
RUN umask $WINE_UMASK && \
    cd $WINEPREFIX/drive_c && \
    unzip -n $HOME/snapshots/CMP/files.zip;
RUN umask $WINE_UMASK && \
    cd $WINEPREFIX/drive_c && mkdir -p Windows && \
    cd $WINEPREFIX/drive_c/Windows && mkdir -p INF System32 SysWOW64 WinSxS && \
    mv INF      inf && \
    mv System32 system32 && \
    mv SysWOW64 syswow64 && \
    mv WinSxS   winsxs && \
    cd $WINEPREFIX/drive_c && \
    cp -R $WINEPREFIX/drive_c/Windows/* $WINEPREFIX/drive_c/windows && \
    rm -rf $WINEPREFIX/drive_c/Windows;

# import msvc environment snapshot
USER root
ADD --chown=wine:wine dockertools/diffenv diffenv
ADD --chown=wine:wine dockertools/make-vcclang-vars make-vcclang-vars
RUN ./diffenv $PWD/snapshots/SNAPSHOT-01/env.txt $PWD/snapshots/SNAPSHOT-02/vcvars32.txt /etc/vcwine/vcvars32 && \
    ./make-vcclang-vars /etc/vcwine/vcvars32 /etc/vcclang/vcvars32;
RUN ./diffenv $PWD/snapshots/SNAPSHOT-01/env.txt $PWD/snapshots/SNAPSHOT-02/vcvars64.txt /etc/vcwine/vcvars64 && \
    ./make-vcclang-vars /etc/vcwine/vcvars64 /etc/vcclang/vcvars64;
RUN rm diffenv make-vcclang-vars;
USER wine

# clean up
RUN rm -rf $HOME/snapshots;

# 64-bit linking has trouble finding cvtres, so help it out
RUN umask $WINE_UMASK && \
    find $WINEPREFIX -iname x86_amd64 | xargs -Ifile cp "file/../cvtres.exe" "file";

# workaround bugs in wine's cmd that prevents msvc setup bat files from working
ADD --chown=wine:wine dockertools/hackvcvars hackvcvars
RUN umask $WINE_UMASK && \
    find $WINEPREFIX/drive_c -iname v[cs]\*.bat | xargs -Ifile $HOME/hackvcvars "file" && \
    find $WINEPREFIX/drive_c -iname win\*.bat | xargs -Ifile $HOME/hackvcvars "file" && \
    rm hackvcvars;

# fix inconsistent casing in msvc filenames
RUN umask $WINE_UMASK && \
    find $WINEPREFIX -name Include -execdir mv Include include \; || \
    find $WINEPREFIX -name Lib -execdir mv Lib lib \; || \
    find $WINEPREFIX -name \*.Lib -execdir rename 'y/A-Z/a-z/' {} \; ;

# make sure we can compile with MSVC
ADD --chown=wine:wine test test
RUN umask $WINE_UMASK && \
    cd test && \
    MSVCARCH=32 vcwine cl helloworld.cpp && vcwine helloworld.exe && \
    MSVCARCH=64 vcwine cl helloworld.cpp && vcwine helloworld.exe && \
    vcwine cl helloworld.cpp && vcwine helloworld.exe && \
    cd .. && rm -rf test ;

# reboot for luck
RUN umask $WINE_UMASK && winetricks win10 ;
RUN umask $WINE_UMASK && wineboot -r ;

USER root
RUN apt-get update && \
    apt-get install -y build-essential && \
    rm -rf /var/lib/apt/lists/*;

USER wine
# entrypoint
ENV MSVCARCH=64
ADD dockertools/vcentrypoint /usr/local/bin/vcentrypoint
ENTRYPOINT [ "/usr/local/bin/vcentrypoint" ]
