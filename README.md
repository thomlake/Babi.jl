Babi.jl
-------
> bAbI utilies for [Julia](http://julialang.org/)

## About
The [bAbI](https://research.facebook.com/researchers/1543934539189348) dataset is a collection of synthetic question answering tasks for testing text understanding and reasoning. The dataset was released in 2015 by [Facebook AI research](https://research.facebook.com/ai). 

All the task are descibed in the paper [Towards AI Complete Question Answering: A Set of Prerequisite Toy Tasks](http://arxiv.org/abs/1502.05698). See [here](http://thomlake.github.io/2016/03/20/deconstructing-babi-task-1.html) for a fairly in-depth breakdown of the data from task 1.

## Intro
This module provides utilities for wokring with the bAbI tasks data. Currently this is just loading the data, but in the future other functionality may be added. Before using this module you'll need to download the bAbI data. Version 1.2 is available [here](http://www.thespermwhale.com/jaseweston/babi/tasks_1-20_v1-2.tar.gz). Should this link rot an up to date link should be available at the main [bAbI page](https://research.facebook.com/researchers/1543934539189348).

## Usage
The function you want is `Babi.read_data`. It takes a single positional argument `task_id` which should be a number from 1 to 20 specifying the task to read. Here's the docstring

    Babi.read_data(task_id; path=ENV["BABI_PATH"], collection="en")

Read bAbI task data for the task specified by `task_id`. 

**Arguments**

* `task_id::Int`: task number (from 1 to 20).
* `path::AbstractString`: path to the directory containing the bAbI task data, i.e., `"/path/to/tasks_1-20_v1-2/"`.
* `collection::AbstractString`: collection to load. Should be one of `"en"`, `"hn"`, `"shuffled"`, `"en-10k"`, `"hn-10k"`, or `"shuffled-10k"`.

**Returns**

* `input_vocab::IndexedArray{ASCIIString}`: clause and question vocabulary.
* `output_vocab::IndexedArray{ASCIIString}`: answer vocabulary.
* `train_docs::Vector{Vector{Babi.Item}}`: training documents.
* `clause_vocab::IndexedArray{ASCIIString}`: testing document.

By default `Babi.read_data` attempts to use the `BABI_PATH` environment variable to find the location where the data resides. You can either pass in this variable or set it

```bash
export BABI_PATH="/path/to/tasks_1-20_v1-2/"
```
