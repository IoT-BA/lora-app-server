FROM golang:1.7

#Node.js and npm
RUN groupadd --gid 1000 node \
  && useradd --uid 1000 --gid node --shell /bin/bash --create-home node

# gpg keys listed at https://github.com/nodejs/node#release-team
RUN set -ex \
  && for key in \
    9554F04D7259F04124DE6B476D5A82AC7E37093B \
    94AE36675C464D64BAFA68DD7434390BDBE9B9C5 \
    FD3A5288F042B6850C66B31F09FE44734EB7990E \
    71DCFD284A79C3B38668286BC97EC7A07EDE3FC1 \
    DD8F2338BAE7501E3DD5AC78C273792F7D83545D \
    B9AE9905FFD7803F25714661B63B535A4C206CA9 \
    C4F0DFFF4E8C1A8236409D08E73BC641CC11F4C8 \
    56730D5401028683275BD23C23EFEFE93C4CFFFE \
  ; do \
    gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "$key"; \
  done

ENV NPM_CONFIG_LOGLEVEL info
ENV NODE_VERSION 7.7.4

RUN curl -SLO "https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-x64.tar.gz"
RUN curl -SLO "https://nodejs.org/dist/v$NODE_VERSION/SHASUMS256.txt.asc"
RUN gpg --batch --decrypt --output SHASUMS256.txt SHASUMS256.txt.asc
RUN grep " node-v$NODE_VERSION-linux-x64.tar.gz\$" SHASUMS256.txt | sha256sum -c -
RUN ls -l
RUN tar -xzf "node-v$NODE_VERSION-linux-x64.tar.gz" -C /usr/local --strip-components=1
RUN rm "node-v$NODE_VERSION-linux-x64.tar.gz" SHASUMS256.txt.asc SHASUMS256.txt
RUN ln -s /usr/local/bin/node /usr/local/bin/nodejs


ENV PROJECT_PATH=/go/src/github.com/brocaar/lora-app-server
ENV PATH=$PATH:$PROJECT_PATH/build

# install tools
RUN go get github.com/golang/lint/golint
RUN go get github.com/kisielk/errcheck
RUN go get github.com/smartystreets/goconvey
RUN go get golang.org/x/tools/cmd/stringer
RUN go get github.com/jteeuwen/go-bindata/...

# grpc dependencies
RUN apt-get update && apt-get install -y unzip
RUN wget https://github.com/google/protobuf/releases/download/v3.0.0/protoc-3.0.0-linux-x86_64.zip && \
	unzip protoc-3.0.0-linux-x86_64.zip && \
	mv bin/protoc /usr/local/bin/protoc && \
	mv include/google /usr/local/include/ && \
	rm protoc-3.0.0-linux-x86_64.zip

RUN go get github.com/golang/protobuf/protoc-gen-go
RUN go get github.com/grpc-ecosystem/grpc-gateway/protoc-gen-swagger
RUN go get github.com/grpc-ecosystem/grpc-gateway/protoc-gen-grpc-gateway

RUN mkdir -p $PROJECT_PATH
WORKDIR $PROJECT_PATH
ENV LORA_APP_SERVER_VERSION 0.7.2
RUN git clone --single-branch --branch 0.7.2 https://github.com/brocaar/lora-app-server ./
# install all requirements
RUN make requirements ui-requirements
# run the tests if $RUN_TEST = true
RUN  if [ -z $RUN_TEST ]; then export RUN_TEST=false; fi && if "$RUN_TEST"; then make test; else true; fi;
# build ui (requires NodeJS) and generate static files
RUN make ui statics
# compile
RUN make build
CMD ["lora-app-server"]
