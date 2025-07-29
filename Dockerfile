FROM gcc:latest
COPY . /DockerWorld
WORKDIR /DockerWorld/
RUN gcc -o test-program main.c
CMD ["./test-program"]
