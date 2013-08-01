## Overview

_"Clean your room before you go outside."_

__"Yes ma'am!"__

>do nothing, and go right outside.

_"Hey! I thought I told you to clean your room?!?  Come back here and start cleaning!"_

__"Yes ma'am!"__

>do nothing, and keep on playing.

This is a Riak KV storage backend that does essentially the least amount of work possible to satisfy a complete implementation of the `riak_kv_backend` behavior.

It creates a static Riak Object on startup, stores that in the State, and passes it directly back on every `GET` request.  `PUT` and `DELETE` requests simply return `{ok, State}` without doing any work at all.

The idea is to use this as a way to figure out the maximum possible throughput and lowest possible latency that `riak_kv` running on `riak_core` is capable of by not doing any actual work at the storage layer.

Conceptually similar to the purpose of the `riak_kv_yessir_backend` except it does even less work before simply returning `ok`.


## Installation

**Pre-requisites:** You must build this using the same version of Erlang that was used to build Riak, or build it with the version of Erlang that is bundled with Riak.

```
$ git clone https://github.com/nathanaschbacher/riak_kv_yesmaam_backend.git
$ cd riak_kv_yesmaam_backend
$ erlc riak_kv_yesmaam_backend.erl
```

This should create a `riak_kv_yesmaam_backend.beam` file in the same directory as the `.erl` file.

Then you need to copy the `riak_kv_yesmaam_backend.beam` to the `lib` or `lib/basho-patches` directory of your Riak install.

```
$ cp ./riak_kv_yesmaam_backend.beam /path/to/riak/lib/basho-patches/riak_kv_yesmaam_backend.beam
``` 
You should be already to go.


## Usage

Edit app.config to set your storage backend to use `riak_kv_yesmaam_backend`

```
%% Riak KV config
{riak_kv, [
            {storage_backend, riak_kv_yesmaam_backend},
            ...
          ]},
```    

## License

(The MIT License)

Copyright (c) 2013 Nathan Aschbacher

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
