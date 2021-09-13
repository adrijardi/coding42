FROM haskell:9.0.1
RUN apt update
COPY pandoc-2.7.3-1-amd64.deb /pandoc.deb
RUN dpkg -i /pandoc.deb
RUN cabal new-update && cabal new-install hakyll-4.14.1.0
