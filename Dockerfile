FROM gcc:latest
COPY . /Test
WORKDIR /Test/
RUN gcc -o test-program main.c
CMD ["./test-program"]
