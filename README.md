Ring Benchmark
==============

Ring benchmark implemented in Erlang.


The benchmark can be parameterized as follows:

- `NPROCS`: Number of processes in the ring (defaults to 1000)
- `NREPS`: Number of times the message is circulated over the ring (defaults to 1)
- `MSG_SIZE`: Size of the message in bytes (defaults to 1024)
- `MSG_TYPE`: Binary (`bin`) or string (`str`) (defaults to `str`).


### Usage

```
make test
Avg. Latency: 4.618us, Total Time: 4618us
```

```
make NPROCS=1000 NREPS=1 MSG_SIZE=1024 MSG_TYPE=bin test
Avg. Latency: 3.539us, Total Time: 3539us
```