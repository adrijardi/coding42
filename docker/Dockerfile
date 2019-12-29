FROM haskell:8.6
RUN apt update
COPY pandoc-2.7.3-1-amd64.deb /pandoc.deb
RUN dpkg -i /pandoc.deb
RUN cabal new-update && cabal new-install hakyll-4.13.0.1
