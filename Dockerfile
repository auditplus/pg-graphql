FROM rust:1.75 as build
RUN apt-get update && apt install -y openssl
ENV PKG_CONFIG_ALLOW_CROSS=1
WORKDIR /usr/src/pg-graphql/
COPY . .
ARG git_personal_token
RUN git config --global url."https://hchockarprasad:${git_personal_token}@github.com/".insteadOf "https://github.com/"
RUN cargo build --release


FROM gcr.io/distroless/cc-debian12
ARG EXE_PATH=/usr/src/pg-graphql/target/release
COPY --from=build /lib/x86_64-linux-gnu/libz.so.1 /usr/lib/libz.so.1
COPY --from=build /lib/x86_64-linux-gnu/libssl.so.3 /usr/lib/libssl.so.3
COPY --from=build /lib/x86_64-linux-gnu/libcrypto.so.3 /usr/lib/libcrypto.so.3
COPY --from=build /usr/lib/x86_64-linux-gnu/libfreetype.so.6 /usr/lib/libfreetype.so.6
COPY --from=build /usr/lib/x86_64-linux-gnu/libpng16.so.16 /usr/lib/libpng16.so.16
COPY --from=build /usr/lib/x86_64-linux-gnu/libbrotlidec.so.1 /usr/lib/libbrotlidec.so.1
COPY --from=build /usr/lib/x86_64-linux-gnu/libbrotlicommon.so.1 /usr/lib/libbrotlicommon.so.1
COPY --from=build $EXE_PATH/pg_graph /usr/local/bin/pg_graph

CMD ["pg_graph"]