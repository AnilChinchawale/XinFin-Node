FROM golang:1.23-bookworm

WORKDIR /work

RUN \
    apt-get update && apt-get install -y git build-essential && \
    git clone https://github.com/XinFinOrg/XDPoSChain.git xdcchain && \
    (cd xdcchain && git checkout --detach 433c202a55a7ffd740f993a2e8799efe6797234a && make)

RUN cp /work/xdcchain/build/bin/XDC /usr/bin && chmod +x /usr/bin/XDC && \
    rm -rf xdcchain

# Only expose P2P port — RPC is opt-in via ENABLE_RPC
EXPOSE 30303

ENTRYPOINT ["bash","/work/start.sh"]
