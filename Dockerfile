FROM gcc:11.5.0-bullseye
COPY . /Test
WORKDIR /Test/
RUN gcc -o test-program main.c
CMD ["./test-program"]
